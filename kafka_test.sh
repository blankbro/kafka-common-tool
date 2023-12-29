#!/bin/bash

kafka_bootstrap_servers=""
kafka_bin_dir=""
operation=""
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
    *)
        shift
        ;;
    esac
done

create_topics() {
    # 创建一个极大的 topic，测试带宽
    topic_name="topic_0"
    echo "开始创建 $topic_name"
    $kafka_bin_dir/kafka-topics.sh --create --topic "$topic_name" --partitions 100 --replication-factor 2 --bootstrap-server $kafka_bootstrap_servers

    # 创建一堆topic，用于持续测试
    for ((i = 1; i <= 200; i++)); do
        topic_name="topic_$i"
        # 使用kafka-topics.sh脚本创建Topic
        echo "开始创建 $topic_name"
        $kafka_bin_dir/kafka-topics.sh --create --topic "$topic_name" --partitions 10 --replication-factor 2 --bootstrap-server $kafka_bootstrap_servers
    done
}

# 测试生产带宽
produce_single_topic_test() {
    echo "produce_single_topic_test start..."

    # 给 topic_0 发 1.22 亿条 586B 的消息
    $kafka_bin_dir/kafka-producer-perf-test.sh --topic topic_0 --throughput -1 --num-records 122916666 --record-size 586 --producer-props bootstrap.servers=$kafka_bootstrap_servers
}

# 测试生产服务器抗压能力
produce_multi_topic_test() {
    echo "produce_multi_topic_test start..."

    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "topic 总量: $topic_total_count"

    index=1
    for topic in $topics; do
        echo "[$index/$topic_total_count] 开始处理 $topic"
        if [[ $topic == "__consumer_offsets" || $topic == "ATLAS_ENTITIES" || $topic == "__amazon_msk_canary" || $topic == "topic_0" ]]; then
            echo "跳过 $topic"
            index=$((index + 1))
            continue
        fi
        if [[ $index == 3 ]]; then
            break
        fi

        my_uuid=$(uuidgen)

        # 运行测试并将输出追加到文件
        #$kafka_bin_dir/kafka-producer-perf-test.sh --topic $topic --throughput -1 --num-records 122916666 --record-size 586 --producer-props bootstrap.servers=$kafka_bootstrap_servers 2>&1 | awk -v topic="$topic" -v time="$(date +'%Y-%m-%d %H:%M:%S')" '{print "[" time "] [" topic "] " $0}' >>produce_multi_topic_test.log &
        $kafka_bin_dir/kafka-producer-perf-test.sh --topic $topic --throughput -1 --num-records 122916666 --record-size 586 --producer-props bootstrap.servers=$kafka_bootstrap_servers 2>&1 | awk -v topic="$topic" -v my_uuid="$my_uuid" '{print "" my_uuid " [" topic "] " $0}' >> produce_multi_topic_test.log &

        index=$((index + 1))
    done

    echo "produce_multi_topic_test started..."

    # 等待所有测试完成
    tail -f produce_multi_topic_test.log
}

# 测试消费带宽
consume_single_topic_test() {
    echo "consume_single_topic_test start..."
    my_uuid=$(uuidgen)

    # 给 topic_0 发 1.22 亿条 586B 的消息
    $kafka_bin_dir/kafka-consumer-perf-test.sh --date-format yyyy-MM-dd HH:mm:ss:SSS --group $my_uuid --messages 122916666 --topic topic_0 --bootstrap-server bootstrap.servers=$kafka_bootstrap_servers
}

# 测试消费服务器抗压能力
consume_multi_topic_test() {
    echo "consume_multi_topic_test start..."

    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "topic 总量: $topic_total_count"

    index=1
    for topic in $topics; do
        echo "[$index/$topic_total_count] 开始处理 $topic"
        if [[ $topic == "__consumer_offsets" || $topic == "ATLAS_ENTITIES" || $topic == "__amazon_msk_canary" || $topic == "topic_0" ]]; then
            echo "跳过 $topic"
            index=$((index + 1))
            continue
        fi

        my_uuid=$(uuidgen)
        # 运行测试并将输出追加到文件
        $kafka_bin_dir/kafka-consumer-perf-test.sh --date-format yyyy-MM-dd HH:mm:ss:SSS --group $my_uuid --messages 122916666 --topic topic_0 --bootstrap-server bootstrap.servers=$kafka_bootstrap_servers 2>&1 | awk -v topic="$topic" -v time="$(date +'%Y-%m-%d %H:%M:%S')" '{print "[" time "] [" topic "] " $0}' >>consume_multi_topic_test.log &

        index=$((index + 1))
    done

    echo "consume_multi_topic_test started..."

    # 等待所有测试完成
    tail -f consume_multi_topic_test.log
}

if [[ -z $kafka_bootstrap_servers ]]; then
    echo "请提供 Kafka 集群信息"
    exit
fi

# 根据参数执行对应功能
if [[ $operation == "create_topics" ]]; then
    create_topics
elif [[ $operation == "produce_single_topic_test" ]]; then
    produce_single_topic_test
elif [[ $operation == "produce_multi_topic_test" ]]; then
    produce_multi_topic_test
elif [[ $operation == "consume_single_topic_test" ]]; then
    consume_single_topic_test
elif [[ $operation == "consume_multi_topic_test" ]]; then
    consume_multi_topic_test
else
    echo "请提供正确的参数"
fi
