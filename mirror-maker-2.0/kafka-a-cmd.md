**设置环境变量**

```shell
export PATH="/Users/lizexin/application/kafka/kafka_2.13-2.6.2/bin:$PATH"
kafka_server="127.0.0.1:9092"
```

**选择topic**

```shell
topic="testA"
```
```shell
topic="testB"
```

**创建Topic**

```shell
kafka-topics.sh --bootstrap-server $kafka_server --replication-factor 3 --partitions 10 --create --topic $topic
```

**列出所有topic**

```shell
kafka-topics.sh --bootstrap-server $kafka_server --list
```

**获取topic消息量**

```shell
kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list $kafka_server --topic $topic --time -1
```

**发布消息**

```shell
kafka-console-producer.sh --broker-list $kafka_server --topic $topic
```

**订阅消息**

```shell
kafka-console-consumer.sh --bootstrap-server $kafka_server --topic $topic
```
