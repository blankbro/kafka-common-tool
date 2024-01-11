## 压测环境准备（Ubuntu）
```shell
# 安装必要的工具
apt install default-jdk
apt install maven

# 验证Maven安装
mvn -version
```

## 压测环境准备（Centos）
1. 安装必要的工具

```shell
sudo su -
yum install git
yum install java-1.8.0-openjdk-devel
yum install wget
yum search jdk | grep 1.8  # 搜索可以安装的 jdk
yum list installed | grep jdk # 获取已安装的 jdk
yum remove java-1.8.0-openjdk # # 卸载已安装的 jdk
```

2. 下载 maven

```shell
mkdir -p /root/maven
cd /root/maven

# 下载Maven
wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz

# 解压缩Maven压缩包
tar -zxvf apache-maven-3.9.6-bin.tar.gz
```

3. 设置 maven 环境变量

```shell
# 编辑`/etc/profile`文件或者`~/.bashrc`文件，添加以下行来设置Maven的环境变量：
echo "export M2_HOME=/root/maven/apache-maven-3.9.6" >> /etc/profile
echo "export PATH=$PATH:$M2_HOME/bin" >> /etc/profile

# 使环境变量生效：
source /etc/profile

# 验证Maven安装
mvn -version
```

## spring-boot-kafka 启动步骤

```shell
# 拉取脚本
mkdir -p ~/github
cd ~/github
git clone https://github.com/blankbro/hbase-test-tool.git

# 获取最新代码
cd ~/github/hbase-test-tool/client-test_java/
git pull

# 编译
./build.sh spring-boot-kafka

# 停止
./control.sh --jar-full-path ~/github/hbase-test-tool/client-test_java/output/spring-boot-kafka.jar --operation stop

# 启动 
# application-local.yml
./control.sh --jar-full-path ~/github/hbase-test-tool/client-test_java/output/spring-boot-kafka.jar --app_prop "--spring.kafka.bootstrap-servers=xxx " --operation start  &
# application-cck.yml
./control.sh --jar-full-path ~/github/hbase-test-tool/client-test_java/output/spring-boot-kafka.jar --app_prop "--spring.kafka.bootstrap-servers=xxx --confluent-cloud-kafka.CLUSTER_API_KEY=xxx --confluent-cloud-kafka.CLUSTER_API_SECRET=xxx " --operation start  &
# application-avk.yml
./control.sh --jar-full-path ~/github/hbase-test-tool/client-test_java/output/spring-boot-kafka.jar --app_prop "--spring.kafka.bootstrap-servers=xxx --aiven-kafka.sasl_username=xxx --aiven-kafka.sasl_password=xxx --spring.kafka.properties.ssl.truststore.location=xxx --spring.kafka.properties.ssl.truststore.password=xxx " --operation start  &

# 看日志
tail -f logs/info.log
```