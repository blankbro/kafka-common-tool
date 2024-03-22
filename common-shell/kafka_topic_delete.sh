#!/bin/bash

kafka_bootstrap_servers=""
kafka_bin_dir=""
operation=""
mock=1
command_config=""

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
    --mock)
        mock="$2"
        shift
        shift
        ;;
    --command-config)
        command_config="--command-config $2"
        shift
        shift
        ;;
    *)
        shift
        ;;
    esac
done

# 删除业务 topic，排除内部 topic
delete_biz_topics() {
    start_time=$(date +%s%3N)

    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers $command_config --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "$(date "+%Y-%m-%d %H:%M:%S") topic 总量: $topic_total_count"

    index=1
    skipped_topic_count=0
    deleted_topic_count=0
    skipped_topic_list=""
    for topic in $topics; do
        log_prefix="$(date "+%Y-%m-%d %H:%M:%S") [$index/$topic_total_count] $topic -"
        if [[ $topic =~ .*[-.]internal || $topic == "heartbeats" || $topic =~ .*.heartbeats || $topic =~ .*.replica || $topic =~ __.* || $topic == "ATLAS_ENTITIES" ]]; then
            skipped_topic_list="$skipped_topic_list \n\t$topic"
            skipped_topic_count=$((skipped_topic_count + 1))
        else
            echo "$log_prefix 准备删除"
            if [[ $mock ]]; then
                echo "$kafka_bin_dir/kafka-topics.sh --delete --topic $topic --bootstrap-server $kafka_bootstrap_servers $command_config"
                $kafka_bin_dir/kafka-topics.sh --delete --topic $topic --bootstrap-server $kafka_bootstrap_servers $command_config
            fi
            deleted_topic_count=$((deleted_topic_count + 1))
        fi
        index=$((index + 1))
    done

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo -e "skipped_topic_list: $skipped_topic_list"
    echo "topic_total_count: $topic_total_count"
    echo "skipped_topic_count: $skipped_topic_count"
    echo "deleted_topic_count: $deleted_topic_count"
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
}

# 删除 mm2 相关的 topic
delete_mm2_topics() {
    start_time=$(date +%s%3N)

    topics=$($kafka_bin_dir/kafka-topics.sh --bootstrap-server $kafka_bootstrap_servers $command_config --list)
    topic_total_count=$(echo $topics | wc -w)
    echo "$(date "+%Y-%m-%d %H:%M:%S") topic 总量: $topic_total_count"

    index=1
    skipped_topic_count=0
    deleted_topic_count=0
    skipped_topic_list=""
    for topic in $topics; do
        log_prefix="$(date "+%Y-%m-%d %H:%M:%S") [$index/$topic_total_count] $topic -"
        if [[ $topic =~ .*.checkpoints.internal || $topic == "heartbeats" || $topic =~ .*.heartbeats || $topic =~ mm2-.*.internal ]]; then
            echo "$log_prefix 准备删除"
            if [[ $mock ]]; then
                echo "$kafka_bin_dir/kafka-topics.sh --delete --topic $topic --bootstrap-server $kafka_bootstrap_servers $command_config"
                $kafka_bin_dir/kafka-topics.sh --delete --topic $topic --bootstrap-server $kafka_bootstrap_servers $command_config
            fi
            deleted_topic_count=$((deleted_topic_count + 1))
        else
            skipped_topic_list="$skipped_topic_list \n\t$topic"
            skipped_topic_count=$((skipped_topic_count + 1))
        fi
        index=$((index + 1))
    done

    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))
    echo -e "skipped_topic_list: $skipped_topic_list"
    echo "topic_total_count: $topic_total_count"
    echo "skipped_topic_count: $skipped_topic_count"
    echo "deleted_topic_count: $deleted_topic_count"
    echo "$(date "+%Y-%m-%d %H:%M:%S") 命令执行时间为: ${duration}ms"
}

if [[ -z $kafka_bootstrap_servers ]]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") 请提供 Kafka 集群信息"
    exit
fi

# 根据参数执行对应功能
if [[ $operation == "delete_biz_topics" ]]; then
    delete_biz_topics
elif [[ $operation == "delete_mm2_topics" ]]; then
    delete_mm2_topics
else
    echo "$(date "+%Y-%m-%d %H:%M:%S") 请提供正确的参数"
fi
