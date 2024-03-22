#!/bin/bash

# 默认值
kafka_bootstrap_servers=""
kafka_bin_dir="."
operation=""
topic_blacklist=""

# 解析命令行参数
# $# 是一个特殊变量，表示命令行参数的数量。-gt 是一个比较运算符，表示大于。
while [[ $# -gt 0 ]]; do
    # 将当前处理的命令行参数赋值给变量 key
    key="$1"

    case $key in
    --kafka-bin-dir)
        kafka_bin_dir="$2"
        shift
        shift
        ;;
    --bootstrap-server)
        kafka_bootstrap_servers="$2"
        # shift 命令将已处理的参数移除, 第一次移除key, 第二次移除对应的值
        shift
        shift
        ;;
    --operation)
        operation="$2"
        shift
        shift
        ;;
    --topic_blacklist)
        topic_blacklist="$2"
        shift
        shift
        ;;
    *)
        shift
        ;;
    esac
done

topic_count() {
    echo "topic数量，开始统计..."

    # 获取 Kafka topic 列表
    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --list)
    topic_total_count=$(echo $topics | wc -w)

    # 遍历每个 topic
    index=1
    internal_topic_count=0
    blacklist_topic_count=0
    valid_topic_count=0
    partition_total_count=0
    for topic in $topics; do
        log_prefix="[$index/$topic_total_count] $topic -"
        if [[ $topic =~ .*[-.]internal || $topic == "heartbeats" || $topic =~ .*.heartbeats || $topic =~ .*.replica || $topic =~ __.* || $topic == "ATLAS_ENTITIES" ]]; then
            echo "$log_prefix kafka internal topic"
            internal_topic_count=$((internal_topic_count+1))
        elif [[ $topic_blacklist != "" && $topic != *"$topic_blacklist"* ]]; then
            echo "$log_prefix in blacklist"
            blacklist_topic_count=$((blacklist_topic_count+1))
        else
            echo "$log_prefix 开始处理"
            valid_topic_count=$((valid_topic_count + 1))
        fi
        index=$((index + 1))
    done

    echo "topic_total_count: $topic_total_count"
    echo "internal_topic_count: $internal_topic_count"
    echo "blacklist_topic_count: $blacklist_topic_count"
    echo "valid_topic_count: $valid_topic_count"
    echo "partition_total_count: $partition_total_count"
}

partition_count() {
    echo "partition数量，开始统计..."

    # 获取 Kafka topic 列表
    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "topic 总量: $topic_total_count"

    # 遍历每个 topic
    index=1
    internal_topic_count=0
    blacklist_topic_count=0
    valid_topic_count=0
    partition_total_count=0
    for topic in $topics; do
        log_prefix="[$index/$topic_total_count] $topic -"
        if [[ $topic =~ .*[-.]internal || $topic == "heartbeats" || $topic =~ .*.heartbeats || $topic =~ .*.replica || $topic =~ __.* || $topic == "ATLAS_ENTITIES" ]]; then
            echo "$log_prefix kafka internal topic"
            internal_topic_count=$((internal_topic_count+1))
        elif [[ $topic_blacklist != "" && $topic != *"$topic_blacklist"* ]]; then
            echo "$log_prefix in blacklist"
            blacklist_topic_count=$((blacklist_topic_count+1))
        else
            echo "$log_prefix 开始处理"
            # 获取当前 topic 的 partition 数量
            partition_count=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --describe --topic $topic | grep "PartitionCount" | awk '{print $4}')
            echo "$log_prefix 有 $partition_count 个 partition"
            partition_total_count=$((partition_total_count + partition_count))
            valid_topic_count=$((valid_topic_count + 1))
        fi
        index=$((index + 1))
    done

    echo "topic_total_count: $topic_total_count"
    echo "internal_topic_count: $internal_topic_count"
    echo "blacklist_topic_count: $blacklist_topic_count"
    echo "valid_topic_count: $valid_topic_count"
    echo "partition_total_count: $partition_total_count"
}

# 统计 consumer 数量
consumer_count() {
    echo "consumer数量，开始统计..."

    # 获取 Kafka group 列表
    consumer_groups=$($kafka_bin_dir/kafka-consumer-groups.sh --bootstrap-server $kafka_bootstrap_servers --list)
    group_total_count=$(echo $consumer_groups | wc -w)
    echo "group 总量: $group_total_count"

    # 遍历每个 group
    index=1
    consumer_total_count=0
    active_consumer_total_count=0
    noactive_consumer_total_count=0
    for consumer_group in $consumer_groups; do
        echo "[$index/$group_total_count] $consumer_group 开始处理"
        # 获取当前 consumer_group 的 consumer 数量，写入到临时文件
        $kafka_bin_dir/kafka-consumer-groups.sh --bootstrap-server $kafka_bootstrap_servers --describe --group $consumer_group >consumer_count.temp
        count=$(cat consumer_count.temp | awk 'NF>1 && !/CONSUMER-ID/{print $7}' | wc -l)
        active_count=$(cat consumer_count.temp | awk 'NF>1 && !/CONSUMER-ID/ && $7!="-"{print $7}' | sort | uniq | wc -l)
        noactive_count=$(cat consumer_count.temp | awk 'NF>1 && !/CONSUMER-ID/ && $7=="-"{print $7}' | grep -c "-")
        echo "[$index/$group_total_count] $consumer_group 共有 $count 个 consumer，有 active $active_count 个，有 noactive $noactive_count 个"
        consumer_total_count=$((consumer_total_count + count))
        active_consumer_total_count=$((active_consumer_total_count + active_count))
        noactive_consumer_total_count=$((noactive_consumer_total_count + noactive_count))
        index=$((index + 1))
    done

    echo "consumer group 总量: $group_total_count"
    echo "consumer 总量: $consumer_total_count"
    echo "active consumer 总量（去重之后的）: $active_consumer_total_count"
    echo "noactive consumer 总量: $noactive_consumer_total_count"
}

# 统计topic 磁盘占用
topic_bytes() {
    echo "topic磁盘占用，开始统计..."

        # 获取 Kafka topic 列表
        topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --list)
        topic_total_count=$(echo $topics | wc -w)
        echo "topic 总量: $topic_total_count"

        # 遍历每个 topic
        index=1
        for topic in $topics; do
            echo "[$index/$topic_total_count] $topic 开始处理"
            index=$((index + 1))

            # 获取当前 topic 的 磁盘占用信息
            topic_dir_describe=$($kafka_bin_dir/kafka-log-dirs.sh --bootstrap-server $kafka_bootstrap_servers --topic-list $topic --describe | grep -E '^{.*}$')

            # 提取 size，并计算总量
            # jp 官方文档：https://jqlang.github.io/jq/manual/v1.5/#math
            total_bytes_size=$(echo "$topic_dir_describe" | jq '.brokers[].logDirs[].partitions[].size' | jq -n 'reduce inputs as $i (0; . + $i)')

            echo "$topic 磁盘总用量为: $total_bytes_size 字节" >> topic_dir_bytes.log
        done

        echo "topic磁盘占用，统计完成..."
}

if [[ -z $kafka_bootstrap_servers ]]; then
    echo "请提供 Kafka 集群信息"
    exit
fi

# 根据参数执行对应功能
if [[ $operation == "topic_count" ]]; then
    topic_count
elif [[ $operation == "partition_count" ]]; then
    partition_count
elif [[ $operation == "consumer_count" ]]; then
    consumer_count
elif [[ $operation == "topic_bytes" ]]; then
    topic_bytes
else
    echo "请提供正确的参数"
fi
