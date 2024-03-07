**设置环境变量**

```shell
export PATH="/Users/lizexin/application/kafka/kafka_2.13-2.6.2/bin:$PATH"
```

**选择topic**

```shell
topic="testB"
```
```shell
topic="A.exclude_testA"
```

**删除topic**

```shell
kafka-topics.sh --bootstrap-server 127.0.0.1:9192 --delete --topic $topic
```

**创建Topic**

```shell
kafka-topics.sh --bootstrap-server 127.0.0.1:9192 --create --replication-factor 3 --partitions 10 --topic $topic
```

**列出所有topic**

```shell
kafka-topics.sh --bootstrap-server 127.0.0.1:9192 --list
```

**获取topic消息量**

```shell
kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list 127.0.0.1:9192 --topic $topic --time -1
```

### Topic Group

**获取所有group**

```shell
kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9192 --list
```

**发布消息**

```shell
kafka-console-producer.sh --broker-list 127.0.0.1:9192 --topic $topic
```

**订阅消息**

```shell
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9192 --topic $topic
```