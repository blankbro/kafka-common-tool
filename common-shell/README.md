## 压测环境准备

1. 安装必要的工具

```shell
# Centos
sudo su -
yum install git
yum install java-1.8.0-openjdk-devel
yum install wget

# Ubuntu
sudo su -
apt update
apt install default-jdk
```

2. 下载 kafka 脚本

```shell
mkdir -p /root/kafka
cd /root/kafka
wget https://archive.apache.org/dist/kafka/3.0.0/kafka_2.13-3.0.0.tgz
tar zxvf kafka_2.13-3.0.0.tgz
```

3. 下载压测脚本

```shell
mkdir -p /root/github
cd /root/github
git clone https://github.com/blankbro/kafka-test-tool.git
```

4. 如果是通过sasl加密访问的, 请编写 sasl.properties

```shell
cp .sasl.properties.template sasl.properties
vim sasl.properties
```

5. 配置环境变量

```shell
cp .env.template .env
vim .env
source .env
```

## 压测命令

0. 脚本参数说明

```shell
--kafka-bin-dir # 指定 kafka 脚本所在目录
--operation # 指定压测操作
--multi-topic-start 0 # 用于指定 topic 开始的序列号。 topic 固定 "topic_" 前缀，序号不足三位时补 0，比如序号是 0，则 topic 为 "topic_000"
--multi-topic-end 0 # 用于指定 topic 结束的序列号
--single-topic # 用于指定固定 topic，压测单个 topic 使用
--command-config, --producer.config, --consumer.config # 用于指定配置文件 
```

1. 删除 topic

```shell
./kafka_perf_test.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --command-config $command_config --operation delete_all_topics
```

2. 创建 topic

```shell
./kafka_perf_test.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --command-config $command_config --operation create_topics --replication-factor 3 --multi-topic-start 0 --multi-topic-end 0 --partitions 100
```

3. 压测单个 topic 生产消息

```shell
./kafka_perf_test.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --producer.config $command_config --operation produce_single_topic_test --single-topic topic_000 --num-records 10000000
```

4. 压测单个 topic 消费消息

```shell
./kafka_perf_test.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --consumer.config $command_config --operation consume_single_topic_test --single-topic topic_000 --messages 10000000
```

5. 压测多个 topic 生产消息

```shell
./kafka_perf_test.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --producer.config $command_config --operation produce_multi_topic_test --multi-topic-start 1 --multi-topic-end 100 --num-records 1000
```

6. 压测多个 topic 消费消息

```shell
./kafka_perf_test.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --consumer.config $command_config --operation consume_multi_topic_test --multi-topic-start 1 --multi-topic-end 100 --messages 100
```

7. 终止所有压测进程

```shell
./kafka_perf_test.sh --operation kill_all
```

## 统计命令

1. topic 数量

```shell
./kafka_statistics.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --operation topic_count 
```

2. partition 数量

```shell
./kafka_statistics.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --operation partition_count 
```

3. consumer 数量

```shell
./kafka_statistics.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --operation consumer_count 
```

4. 统计 kafka topic 磁盘占用

```shell
./kafka_statistics.sh --kafka-bin-dir $kafka_bin_dir --bootstrap-server $bootstrap_server --operation topic_dir_bytes 

# 如何在excel中将单元格的字节格式化为kb-mb-gb等
# 参考：https://stackoverflow.com/questions/1533811/how-can-i-format-bytes-a-cell-in-excel-as-kb-mb-gb-etc
# =IF(A1>POWER(1024,4),TRUNC(A1/POWER(1024,4),2)&" TB", IF(A1>POWER(1024,3),TRUNC(A1/POWER(1024,3),2)&" GB", IF(A1>POWER(1024,2), ROUND(A1/POWER(1024,2),0)&" MB", ROUND(A1/1024,0)&" KB")))
```