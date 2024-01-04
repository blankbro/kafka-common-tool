# 压测环境准备(Centos)

1. 安装必要的工具

```shell
sudo su -
yum install git
yum install java-1.8.0-openjdk-devel
yum install wget
```

2. 下载 kafka 脚本

```shell
mkdir -p /root/kafka
cd /root/kafka
wget https://downloads.apache.org/kafka/3.5.1/kafka_2.13-3.5.1.tgz
tar zxvf kafka_2.13-3.5.1.tgz
```

3. 下载压测脚本

```shell
mkdir -p /root/github
cd /root/github
git clone https://github.com/blankbro/kafka-shell-tool.git
```

4. 如果是 confluent cloud, 请编写 cloud.properties

```shell
vim /root/github/kafka-test-tool/cloud.properties
```

```shell
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
request.timeout.ms=20000
bootstrap.servers=<cloud-bootstrap-server>
retry.backoff.ms=500
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="<cloud-key>" password="<cloud-password>";
security.protocol=SASL_SSL
```