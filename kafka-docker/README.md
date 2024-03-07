## docker-compose-kafka-cluster-ab.yml 使用步骤

**设置环境变量文件**

```shell
cp .env.template .env
vim .env
```

**创建并启动容器**

```shell
docker-compose -f docker-compose-kafka-cluster-ab.yml --env-file .env -p kafka-cluster-ab up -d
```

**启动容器**

```shell
docker-compose -f docker-compose-kafka-cluster-ab.yml -p kafka-cluster-ab start
```

**停止集群**

```shell
docker-compose -f docker-compose-kafka-cluster-ab.yml -p kafka-cluster-ab stop
```

**移除集群**

```shell
docker-compose -f docker-compose-kafka-cluster-ab.yml -p kafka-cluster-ab down
```