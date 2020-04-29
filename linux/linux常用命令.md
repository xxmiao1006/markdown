#### linux

```bash
#查看端口占用情况 
lsof -i:8000
netstat -tunlp | grep 8000
ps aux | grep 4874

#查看当前所有tcp端口
netstat -ntlp

#查看已开放端口列表
firewall-cmd --permanent --list-port 


#杀死进程
kill -9 26993
#批量杀死进程
ps -ef | grep firefox | grep -v grep | awk '{print "kill -9 "$2}'|sh
#列出了当前主机中运行的进程中包含firefox关键字的进程
ps -ef | grep firefox | grep -v grep    
#列出了要kill掉这些进程的命令，并将之打印在了屏幕上 
ps -ef | grep firefox | grep -v grep | awk '{print "kill -9 "$2}'
#后面加上|sh后，则执行这些命令，进而杀掉了这些进程
ps -ef | grep firefox | grep -v grep | awk '{print "kill -9 "$2}' | sh

#防火墙相关
systemctl status firewalld.service #查看防火墙状态
systemctl start firewalld.service #启用防火墙
systemctl stop firewalld #停用防火墙
systemctl disable firewalld #开机禁用
systemctl enable firewalld #开机启用
systemctl disable firewalld #关闭开机自启

#iptables
service iptables status #查看iptables状态
systemctl restart iptables.service #重启
iptables -t nat -S #iptables 规则
iptables -L


#系统常用
top  #查看cup 内存
df -h  #查看硬盘
du -sh *  #查看当前目录文件大小的详细列表
systemctl restart network #重启网络

#设置环境变量
export hyd_file_default_port="9998"
#加载环境变量
source /etc/profile
#查看环境变量
echo $hyd_file_default_port

#禁用swap
swapoff -a

#解压文件
tar -xzvf test.tar.gz 

#拷贝
cp -r 

#进程
ps -elf

#安装常用工具
yum install bridge-utils

#资源信息
lscpu
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
docker attach containerid   

#查看容器启动日志
docker logs -f 898f2cd0403d89394ec01ef47892f9cc4b381378db7973714611d550659ccb08

#查看容器进程
ps axf

#查看容器网络
docker network ls

#docker bridge 网络的配置信息
docker network inspect bridge

#data volume
docker inspect containerid/containername/volumename
docker volume ls

#logging driver
docker info |grep 'Logging Driver'

#列出所有的 dangling images
docker images -f "dangling=true"

#删除所有的 dangling images：
docker rmi $(docker images -f "dangling=true" -q)

#启动所有 docker 容器
docker start $(docker ps -aq)

#停止所有 docker 容器
docker stop $(docker ps -aq)

#删除所有 docker 容器
docker rm $(docker ps -aq)

#删除所有 docker 镜像
docker rmi $(docker images -q)

#docker 资源清理
# 删除所有退出状态的容器
docker container prune 

# 删除未被使用的数据卷
docker volume prune 

# 删除 dangling 或所有未被使用的镜像
docker image prune 

#删除已停止的容器、dangling 镜像、未被容器引用的 network 和构建过程中的 cache
# 安全起见，这个命令默认不会删除那些未被任何容器引用的数据卷，如果需要同时删除这些数据卷，你需要显式的指定 --volumns 参数
docker system prune 

#这次不仅会删除数据卷，而且连确认的过程都没有了！注意，使用 --all 参数后会删除所有未被引用的镜像而不仅仅是 dangling 镜像
docker system prune --all --force --volumns 

```

