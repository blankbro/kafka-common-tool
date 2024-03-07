**设置环境变量**

```shell
export PATH="/Users/lizexin/application/kafka/kafka_2.13-2.6.2/bin:$PATH"
```

### Topic 相关操作

**选择topic**

```shell
topic="testA"
```
```shell
topic="exclude_testA"
```

**创建Topic**

```shell
kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --replication-factor 3 --partitions 10 --create --topic $topic
```

**列出所有topic**

```shell
kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --list
```

**获取topic消息量**

```shell
kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list 127.0.0.1:9092 --topic $topic --time -1
```

### Consumer Group

**获取所有group**

```shell
kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --list
```

**查看group详细信息**

```shell
kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --describe --group consumer_01
```

### 发布与订阅

**发布消息**

```shell
kafka-console-producer.sh --broker-list 127.0.0.1:9092 --topic $topic
```

**订阅消息**

```shell
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --group consumer_01 --topic $topic 
```
