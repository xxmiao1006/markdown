#### linux

```bash
#查看端口占用情况 
lsof -i:8000
netstat -tunlp | grep 8000
#查看当前所有tcp端口
netstat -ntlp
#杀死进程
kill -9 26993

#解压文件
tar -xzvf test.tar.gz 

##进程
ps -elf
```

#### elasticsearch

```bash
#查看节点信息
curl -X GET http://localhost:9200/_nodes

#打开文件数信息
curl -X GET http://localhost:9200/_nodes/stats/process?filter_path=**.max_file_descriptors

#集群健康状态
curl -X GET http://localhost:9200/_cat/health?v

#查看集群索引数
curl -X GET http://localhost:9200/_cat/indices?v

#查看磁盘分配情况
curl -X GET http://localhost:9200/_cat/allocation?v

#查看集群节点
curl -X GET http://localhost:9200/_cat/nodes?v

#查看集群其他信息
curl -X GET http://localhost:9200/_cat
```

#### docker

```bash
#进入容器命令行界面   898f2cd0403d  容器id  退出用exit
docker exec -u 0 -it 898f2cd0403d /bin/bash

#查看容器启动日志
docker logs -f 898f2cd0403d89394ec01ef47892f9cc4b381378db7973714611d550659ccb08

#查看容器进程
ps axf

#查看容器网络
docker network ls

#docker bridge 网络的配置信息
docker network inspect bridge
```

