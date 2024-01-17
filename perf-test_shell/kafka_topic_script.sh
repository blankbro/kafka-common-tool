#!/bin/bash

# 默认值
kafka_bootstrap_servers=""
backup_file=""
create_input_file=""
kafka_bin_dir="."
operation=""
topic_grep=""

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
    --backup_file)
        backup_file="$2"
        shift
        shift
        ;;
    --create_input_file)
        create_input_file="$2"
        shift
        shift
        ;;
    --topic_grep)
        topic_grep="$2"
        shift
        shift
        ;;
    *)
        shift
        ;;
    esac
done

# 备份 Kafka topic 数据函数
backup_topics() {
    echo "备份 Kafka topic 数据开始..."

    # 获取 Kafka topic 列表
    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "topic 总量: $topic_total_count"

    # 清空输出文件
    echo "" >$backup_file

    # 遍历每个 topic
    index=1
    for topic in $topics; do
        echo "[$index/$topic_total_count] 开始处理 $topic"
        if [[ $topic == "__consumer_offsets" || $topic == "ATLAS_ENTITIES" || $topic == "__amazon_msk_canary" ]]; then
            echo "跳过 $topic"
            index=$((index + 1))
            continue
        elif [[ $topic_grep != "" && $topic != *"$topic_grep"* ]]; then
            echo "跳过不匹配的 Topic: $topic"
            index=$((index + 1))
            continue
        fi

        # 将数据写入输出文件
        # echo $kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --describe --topic $topic | grep "PartitionCount" | awk '{print $1,$2}{print $3,$4} {print $5,$6}'
        $kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --describe --topic $topic | grep "PartitionCount" | awk '{print $1,$2}{print $3,$4} {print $5,$6}' >>$backup_file

        # 空行隔开
        echo "" >>$backup_file
        index=$((index + 1))
    done

    echo "备份 Kafka topic 数据完成，并已写入文件: $backup_file"
}

partition_counts() {
    echo "partition数量，开始统计..."

    # 获取 Kafka topic 列表
    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "topic 总量: $topic_total_count"

    # 遍历每个 topic
    index=1
    topic_valid_count=0
    partition_total_count=0
    for topic in $topics; do
        echo "[$index/$topic_total_count] $topic 开始处理"
        if [[ $topic == "__consumer_offsets" || $topic == "ATLAS_ENTITIES" || $topic == "__amazon_msk_canary" ]]; then
            echo "跳过无效 Topic: $topic"
            index=$((index + 1))
            continue
        elif [[ $topic_grep != "" && $topic != *"$topic_grep"* ]]; then
            echo "跳过不匹配的 Topic: $topic"
            index=$((index + 1))
            continue
        fi

        topic_valid_count=$((topic_valid_count + 1))
        # 获取当前 topic 的 partition 数量
        count=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --describe --topic $topic | grep "PartitionCount" | awk '{print $4}')
        echo "[$index/$topic_total_count] $topic 有 $count 个 partition"
        partition_total_count=$((partition_total_count + count))
        index=$((index + 1))
    done

    echo "topic 总量: $topic_total_count"
    echo "topic 有效总量: $topic_valid_count"
    echo "partition 有效总量: $partition_total_count"
}

# 统计 consumer 数量
consumer_counts() {
    echo "consumer数量，开始统计..."

    # 获取 Kafka topic 列表
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
        $kafka_bin_dir/kafka-consumer-groups.sh --bootstrap-server $kafka_bootstrap_servers --describe --group $consumer_group >consumer_counts.temp
        count=$(cat consumer_counts.temp | awk 'NF>1 && !/CONSUMER-ID/{print $7}' | wc -l)
        active_count=$(cat consumer_counts.temp | awk 'NF>1 && !/CONSUMER-ID/ && $7!="-"{print $7}' | sort | uniq | wc -l)
        noactive_count=$(cat consumer_counts.temp | awk 'NF>1 && !/CONSUMER-ID/ && $7=="-"{print $7}' | grep -c "-")
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

# 创建 Kafka topic 数据函数
create_topics() {
    echo "创建 Kafka topic 数据开始..."

    # 读取备份文件内容
    while IFS= read -r line; do
        # 提取 topic 名称、分区和副本因子
        if [[ $line == "Topic: "* ]]; then
            topic=${line#"Topic: "}
        elif [[ $line == "PartitionCount: "* ]]; then
            partitions=${line#"PartitionCount: "}
        elif [[ $line == "ReplicationFactor: "* ]]; then
            replication_factor=${line#"ReplicationFactor: "}

            # 创建 topic
            echo "$topic parition:[$partitions], replication_factor:[$replication_factor] 开始创建"
            # $kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers --create --topic $topic --partitions $partitions --replication-factor $replication_factor
            echo "$topic 完成创建"
        fi
    done <$create_input_file

    echo "创建 Kafka topic 数据完成。"
}

# 统计topic 磁盘占用
topic_dir_bytes() {
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
            if [[ $topic == "__consumer_offsets" || $topic == "ATLAS_ENTITIES" || $topic == "__amazon_msk_canary" ]]; then
                echo "跳过无效 Topic: $topic"
                continue
            fi

            # 获取当前 topic 的 磁盘占用
            topic_log_dir=$(./kafka-log-dirs.sh --bootstrap-server $kafka_bootstrap_servers --topic-list $topic --describe)

            # 提取每个 broker
            brokers=$(echo "$topic_log_dir" | jq -r '.brokers')

            # 遍历每个 broker
            while IFS= read -r broker; do
                broker_id=$(echo "$broker" | jq -r '.broker')
                partitions=$(echo "$broker" | jq -r '.logDirs[0].partitions')

                # 计算每个 broker 的总大小
                total_size=0
                while IFS= read -r partition; do
                    size=$(echo "$partition" | jq -r '.size')
                    total_size=$((total_size + size))
                done <<< "$partitions"

                echo "Broker $broker_id 的总磁盘使用量为: $total_size 字节"
            done <<< "$brokers"

        done

}

if [[ -z $kafka_bootstrap_servers ]]; then
    echo "请提供 Kafka 集群信息"
    exit
fi

# 根据参数执行对应功能
if [[ $operation == "backup_topics" ]]; then
    backup_topics
elif [[ $operation == "create_topics" ]]; then
    create_topics
elif [[ $operation == "partition_counts" ]]; then
    partition_counts
elif [[ $operation == "consumer_counts" ]]; then
    consumer_counts
elif [[ $operation == "topic_dir_bytes" ]]; then
    topic_dir_bytes
else
    echo "请提供正确的参数"
fi
