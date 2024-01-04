# 压测环境准备（Ubuntu）
```shell
# 安装必要的工具
apt install default-jdk
apt install maven

# 验证Maven安装
mvn -version
```

# 压测环境准备（Centos）
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