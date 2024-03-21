#!/bin/bash

kafka_bootstrap_servers=""
kafka_bin_dir=""
operation=""
command_config=""
producer_config=""
consumer_config=""
partitions=10
replication_factor=2
num_records=123000000
record_size=600
messages=$num_records
single_topic=""
multi_topic_start=1
multi_topic_end=200

while [[ $# -gt 0 ]]; do
    # 将当前处理的命令行参数赋值给变量 key
    key="$1"

    case $key in
    --bootstrap-server)
        kafka_bootstrap_servers="$2"
        shift
        shift
        ;;
    --kafka-bin-dir)
        kafka_bin_dir="$2"
        shift
        shift
        ;;
    --operation)
        operation="$2"
        shift
        shift
        ;;
    --command-config)
        command_config="--command-config $2"
        shift
        shift
        ;;
    --producer.config)
        producer_config="--producer.config $2"
        shift
        shift
        ;;
    --consumer.config)
        consumer_config="--consumer.config $2"
        shift
        shift
        ;;
    --partitions)
        partitions=$2
        shift
        shift
        ;;
    --replication-factor)
        replication_factor=$2
        shift
        shift
        ;;
    --num-records)
        num_records=$2
        shift
        shift
        ;;
    --record-size)
        record_size=$2
        shift
        shift
        ;;
    --single-topic)
        single_topic=$2
        shift
        shift
        ;;
    --multi-topic-start)
        multi_topic_start=$2
        shift
        shift
        ;;
    --multi-topic-end)
        multi_topic_end=$2
        shift
        shift
        ;;
    --messages)
        messages=$2
        shift
        shift
        ;;
    *)
        shift
        ;;
    esac
done

create_topics() {
    start_time=$(date +%s%3N)

    for ((i = $multi_topic_start; i <= $multi_topic_end; i++)); do
        formatted_number=$(printf "%03d" $i)
        topic_name="topic_$formatted_number"
        echo "$(date "+%Y-%m-%d %H:%M:%S") 开始创建 $topic_name"
        $kafka_bin_dir/kafka-topics.sh --create --topic "$topic_name" --partitions $partitions --replication-factor $replication_factor --bootstrap-server $kafka_bootstrap_servers $command_config
    done

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
}

delete_topics() {
    start_time=$(date +%s%3N)

    for ((i = $multi_topic_start; i <= $multi_topic_end; i++)); do
        formatted_number=$(printf "%03d" $i)
        topic_name="topic_$formatted_number"
        echo "$(date "+%Y-%m-%d %H:%M:%S") 开始删除 $topic_name"
        $kafka_bin_dir/kafka-topics.sh --delete --topic "$topic_name" --bootstrap-server $kafka_bootstrap_servers $command_config
    done

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
}

delete_all_topics() {
    start_time=$(date +%s%3N)

    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers $command_config --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "$(date "+%Y-%m-%d %H:%M:%S") topic 总量: $topic_total_count"

    index=1
    for topic in $topics; do
        echo "$(date "+%Y-%m-%d %H:%M:%S") [$index/$topic_total_count] 开始处理 $topic"
        if [[ $topic == "__consumer_offsets" || $topic == "ATLAS_ENTITIES" || $topic == "__amazon_msk_canary" ]]; then
            echo "$(date "+%Y-%m-%d %H:%M:%S") 跳过 $topic"
        else
            echo "$(date "+%Y-%m-%d %H:%M:%S") 开始删除 $topic"
            $kafka_bin_dir/kafka-topics.sh --delete --topic "$topic" --bootstrap-server $kafka_bootstrap_servers $command_config
        fi
        index=$((index + 1))
    done

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
}

# 测试生产带宽
produce_single_topic_test() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") produce_single_topic_test start..."

    # 给 topic_0 发 1.22 亿条 586B 的消息
    # --throughput -1  吞吐量上限 -1：无上限
    # --num-records 122916666 测试 10 分钟，约 1 亿条消息，177 亿 / 24 / 60 * 10
    # --record-size 586 每条消息 586B，计算方法：14.19MB(Bytes in /sec) ÷ 25374.72(Messages in /sec)
    echo "$kafka_bin_dir/kafka-producer-perf-test.sh --topic $single_topic --throughput -1 --num-records $num_records --record-size $record_size --producer-props bootstrap.servers=$kafka_bootstrap_servers $producer_config"
    start_time=$(date +%s%3N)

    $kafka_bin_dir/kafka-producer-perf-test.sh --topic $single_topic --throughput -1 --num-records $num_records --record-size $record_size --producer-props bootstrap.servers=$kafka_bootstrap_servers $producer_config

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
}

# 测试生产服务器抗压能力
produce_multi_topic_test() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") produce_multi_topic_test start..."
    logfile="produce_multi_topic_test.log"

    request_uuid=$(uuidgen)
    echo "" > $logfile
    echo "====================================================== [$request_uuid] $(date +"%Y-%m-%d %H:%M:%S")" >> $logfile
    start_time=$(date +%s%3N)

    for ((i = $multi_topic_start; i <= $multi_topic_end; i++)); do
        formatted_number=$(printf "%03d" $i)
        topic_name="topic_$formatted_number"
        echo "$(date +"%Y-%m-%d %H:%M:%S") 开始生产 $topic_name"
        $kafka_bin_dir/kafka-producer-perf-test.sh --topic "$topic_name" --throughput -1 --num-records $num_records --record-size $record_size --producer-props bootstrap.servers=$kafka_bootstrap_servers $producer_config 2>&1 | awk -v topic="$topic_name" '{print "[" topic "] " $0}' >> $logfile &
    done

    echo "$(date "+%Y-%m-%d %H:%M:%S") produce_multi_topic_test started..."

    # 等待所有测试完成
    echo "$(date +"%Y-%m-%d %H:%M:%S") 开始等待所有测试完成"
    wait

    end_time=$(date +%s%3N)
    echo "====================================================== [$request_uuid] $(date +"%Y-%m-%d %H:%M:%S")" >> $logfile

    duration=$((end_time - start_time))
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
    tail -n 20 $logfile
}

# 测试消费带宽
consume_single_topic_test() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") consume_single_topic_test start..."
    my_uuid=$(uuidgen)
    start_time=$(date +%s%3N)

    # 给 topic_0 发 1.22 亿条 586B 的消息
    $kafka_bin_dir/kafka-consumer-perf-test.sh --date-format "yyyy-MM-dd HH:mm:ss:SSS" --group "$my_uuid" --messages $messages --topic $single_topic --bootstrap-server bootstrap.servers=$kafka_bootstrap_servers $consumer_config

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
}

# 测试消费服务器抗压能力
consume_multi_topic_test() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") consume_multi_topic_test start..."
    logfile="consume_multi_topic_test.log"

    request_uuid=$(uuidgen)
    echo "" > $logfile
    echo "====================================================== [$request_uuid] $(date +"%Y-%m-%d %H:%M:%S")" >> $logfile
    start_time=$(date +%s%3N)

    for ((i = $multi_topic_start; i <= $multi_topic_end; i++)); do
        formatted_number=$(printf "%03d" $i)
        topic_name="topic_$formatted_number"
        echo "$(date +"%Y-%m-%d %H:%M:%S") 开始消费 $topic_name"
        my_group_id=$(uuidgen)
        $kafka_bin_dir/kafka-consumer-perf-test.sh --date-format "yyyy-MM-dd HH:mm:ss:SSS" --group $my_group_id --messages $messages --topic "$topic_name" --bootstrap-server bootstrap.servers=$kafka_bootstrap_servers $consumer_config 2>&1 | awk -v topic="$topic_name" '{print "[" topic "] " $0}' >> $logfile &
    done

    echo "$(date "+%Y-%m-%d %H:%M:%S") consume_multi_topic_test started..."

    # 等待所有测试完成
    echo "$(date +"%Y-%m-%d %H:%M:%S") 开始等待所有测试完成"
    wait

    end_time=$(date +%s%3N)
    echo "====================================================== [$request_uuid] $(date +"%Y-%m-%d %H:%M:%S")" >> $logfile

    duration=$((end_time - start_time))
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
    tail -n 20 $logfile
}

kill_all() {
    # 获取包含特定"topic"的所有进程的PID
    pids=$(ps -ef | grep topic | grep -v grep | awk '{print $2}')
    pid_count=$(echo $pids | wc -w)

    # 检查是否有匹配的进程
    if [ -n "$pids" ]; then
        # 终止匹配到的进程
        echo "$(date "+%Y-%m-%d %H:%M:%S") 匹配到 $pid_count 个进程"
        kill $pids
        echo "$(date "+%Y-%m-%d %H:%M:%S") 已终止"
    else
        echo "$(date "+%Y-%m-%d %H:%M:%S") 未匹配的进程"
    fi
}

if [[ $operation != "kill_all" && -z $kafka_bootstrap_servers ]]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") 请提供 Kafka 集群信息"
    exit
fi

# 根据参数执行对应功能
if [[ $operation == "create_topics" ]]; then
    create_topics
elif [[ $operation == "delete_topics" ]]; then
    delete_topics
elif [[ $operation == "delete_all_topics" ]]; then
    delete_all_topics
elif [[ $operation == "produce_single_topic_test" ]]; then
    produce_single_topic_test
elif [[ $operation == "produce_multi_topic_test" ]]; then
    produce_multi_topic_test
elif [[ $operation == "kill_all" ]]; then
    kill_all
elif [[ $operation == "consume_single_topic_test" ]]; then
    consume_single_topic_test
elif [[ $operation == "consume_multi_topic_test" ]]; then
    consume_multi_topic_test
else
    echo "$(date "+%Y-%m-%d %H:%M:%S") 请提供正确的参数"
fi
