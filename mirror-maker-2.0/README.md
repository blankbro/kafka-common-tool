**设置环境变量**

```shell
export PATH="/Users/lizexin/application/kafka/kafka_2.13-2.6.2/bin:$PATH"
kafka_server=127.0.0.1:9092
kafka_server=127.0.0.1:9192
topic="testA"
topic="exclude_testA"
topic="A.testA"
```

**启动MM2**

```shell
connect-mirror-maker.sh connect-mirror-maker.properties
```

**Topic 相关操作**

```shell
# 删除topic
kafka-topics.sh --bootstrap-server $kafka_server --delete --topic $topic

# 创建Topic
kafka-topics.sh --bootstrap-server $kafka_server --create --replication-factor 3 --partitions 10 --topic $topic

# 列出所有topic
kafka-topics.sh --bootstrap-server $kafka_server --list

# 获取topic消息量
kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list $kafka_server --topic $topic --time -1
```

**Consumer Group相关**

```shell
# 获取所有group
kafka-consumer-groups.sh --bootstrap-server $kafka_server --list

# 查看group详细信息
kafka-consumer-groups.sh --bootstrap-server $kafka_server --describe --group consumer_01
```

**发布与订阅**

```shell
# 发布消息
kafka-console-producer.sh --broker-list $kafka_server --topic $topic

# 订阅消息
kafka-console-consumer.sh --bootstrap-server $kafka_server --group consumer_01 --topic $topic
```