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
        echo "开始创建 $topic_name"
        $kafka_bin_dir/kafka-topics.sh --create --topic "$topic_name" --partitions $partitions --replication-factor $replication_factor --bootstrap-server $kafka_bootstrap_servers $command_config
    done

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "命令执行时间为: ${duration} 毫秒"
}

delete_topics() {
    start_time=$(date +%s%3N)

    for ((i = $multi_topic_start; i <= $multi_topic_end; i++)); do
        formatted_number=$(printf "%03d" $i)
        topic_name="topic_$formatted_number"
        echo "开始删除 $topic_name"
        $kafka_bin_dir/kafka-topics.sh --delete --topic "$topic_name" --bootstrap-server $kafka_bootstrap_servers $command_config
    done

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "命令执行时间为: ${duration} 毫秒"
}

delete_all_topics() {
    start_time=$(date +%s%3N)

    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers $command_config --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "topic 总量: $topic_total_count"

    index=1
    for topic in $topics; do
        echo "[$index/$topic_total_count] 开始处理 $topic"
        if [[ $topic == "__consumer_offsets" || $topic == "ATLAS_ENTITIES" || $topic == "__amazon_msk_canary" ]]; then
            echo "跳过 $topic"
            index=$((index + 1))
            continue
        fi

        echo "开始删除 $topic"
        $kafka_bin_dir/kafka-topics.sh --delete --topic "$topic" --bootstrap-server $kafka_bootstrap_servers $command_config
        index=$((index + 1))
    done

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "命令执行时间为: ${duration} 毫秒"
}

# 测试生产带宽
produce_single_topic_test() {
    echo "produce_single_topic_test start..."

    # 给 topic_0 发 1.22 亿条 586B 的消息
    echo "$kafka_bin_dir/kafka-producer-perf-test.sh --topic $single_topic --throughput -1 --num-records $num_records --record-size $record_size --producer-props bootstrap.servers=$kafka_bootstrap_servers $producer_config"
    start_time=$(date +%s%3N)

    $kafka_bin_dir/kafka-producer-perf-test.sh --topic $single_topic --throughput -1 --num-records $num_records --record-size $record_size --producer-props bootstrap.servers=$kafka_bootstrap_servers $producer_config

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "命令执行时间为: ${duration} 毫秒"
}

# 测试生产服务器抗压能力
produce_multi_topic_test() {
    echo "produce_multi_topic_test start..."

    request_uuid=$(uuidgen)
    echo "====================================================== [$request_uuid] $(date +"%Y-%m-%d %H:%M:%S")" > produce_multi_topic_test.log
    start_time=$(date +%s%3N)

    for ((i = $multi_topic_start; i <= $multi_topic_end; i++)); do
        formatted_number=$(printf "%03d" $i)
        topic_name="topic_$formatted_number"
        echo "$(date +"%Y-%m-%d %H:%M:%S") 开始生产 $topic_name"
        $kafka_bin_dir/kafka-producer-perf-test.sh --topic "$topic_name" --throughput -1 --num-records $num_records --record-size $record_size --producer-props bootstrap.servers=$kafka_bootstrap_servers $producer_config 2>&1 | awk -v topic="$topic_name" '{print "[" topic "] " $0}' >>produce_multi_topic_test.log &
    done

    echo "produce_multi_topic_test started..."

    # 等待所有测试完成
    echo "$(date +"%Y-%m-%d %H:%M:%S") 开始等待所有测试完成"
    wait

    end_time=$(date +%s%3N)
    echo "====================================================== [$request_uuid] $(date +"%Y-%m-%d %H:%M:%S")" > produce_multi_topic_test.log

    duration=$((end_time - start_time))
    echo "命令执行时间为: ${duration} 毫秒"
}

# 测试消费带宽
consume_single_topic_test() {
    echo "consume_single_topic_test start..."
    my_uuid=$(uuidgen)
    start_time=$(date +%s%3N)

    # 给 topic_0 发 1.22 亿条 586B 的消息
    $kafka_bin_dir/kafka-consumer-perf-test.sh --date-format "yyyy-MM-dd HH:mm:ss:SSS" --group "$my_uuid" --messages $messages --topic $single_topic --bootstrap-server bootstrap.servers=$kafka_bootstrap_servers $consumer_config

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "命令执行时间为: ${duration} 毫秒"
}

# 测试消费服务器抗压能力
consume_multi_topic_test() {
    echo "consume_multi_topic_test start..."

    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "topic 总量: $topic_total_count"
    start_time=$(date +%s%3N)

    index=1
    valid_count=0
    for topic in $topics; do
        echo "[$index/$topic_total_count] 开始处理 $topic"
        if [[ $topic == "__consumer_offsets" || $topic == "ATLAS_ENTITIES" || $topic == "__amazon_msk_canary" || $topic == "topic_0" ]]; then
            echo "跳过 $topic"
            index=$((index + 1))
            continue
        fi

        if [[ $valid_count == 10 ]]; then
            echo "已达到 $valid_count 压测进程"
            break
        fi

        my_uuid=$(uuidgen)
        # 运行测试并将输出追加到文件
        $kafka_bin_dir/kafka-consumer-perf-test.sh --date-format yyyy-MM-dd HH:mm:ss:SSS --group $my_uuid --messages $messages --topic "$topic" --bootstrap-server bootstrap.servers=$kafka_bootstrap_servers $consumer_config 2>&1 | awk -v my_uuid="$my_uuid" '{print "" my_uuid " [" topic "] " $0}' >>consume_multi_topic_test.log &

        index=$((index + 1))
        valid_count=$((valid_count + 1))
    done

    echo "consume_multi_topic_test started..."

    # 等待所有测试完成
    wait

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo "命令执行时间为: ${duration} 毫秒"
}

kill_all() {
    # 获取包含特定"topic"的所有进程的PID
    pids=$(ps -ef | grep topic | grep -v grep | awk '{print $2}')

    # 检查是否有匹配的进程
    if [ -n "$pids" ]; then
        # 终止匹配到的进程
        echo "匹配到进程: $pids"
        pkill -f "topic"
        echo "已终止进程: $pids"
    else
        echo "未找到匹配的进程"
    fi
}

if [[ $operation != "kill_all" && -z $kafka_bootstrap_servers ]]; then
    echo "请提供 Kafka 集群信息"
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
    echo "请提供正确的参数"
fi
