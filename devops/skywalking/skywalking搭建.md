## 搭建skywalking 服务端

### 一. 所需第三方软件

* XShell
* Xftp
* Visual Studio 2019
* .net Core 2.2 SDK
* JDK8+
* Elasticsearch 6.3.2
* centos7
* docker

### 二. 实验架构

本次实验采用2台服务器Elasticsearch 放在centos7上，collector和客户端放在一起收集本机web服务器提供的数据。如果对skywalking架构不了解的同学可以先去了解一下。这里就不多做介绍了。

### 三. 安装运行环境

#### 1. 安装java

根据博客上的命令行在centos7上安装失败了，命令如下

```bash
wget --no-check-certificate --no-cookie --header "Cookie: oraclelicense=accept-securebackup-cookie;" http://download.oracle.com/otn-pub/java/jdk/8u171-b11/512cd62ec5174c3487ac17c61aaa89e8/jdk-8u171-linux-x64.rpm
```

所以在本地上下载的`jdk-8u221-linux-x64.rpm` 在用Xftp传到centos上，然后用一下命令安装

```bash
rpm -ivh jdk-8u221-linux-x64.rpm 
```

安装完后使用命令检查安装是否成功

```bash
java -version
```

![java安装成功.png](https://ws1.sinaimg.cn/large/006nK6pBgy1g762f1ed2wj30db025a9x.jpg)

#### 2. 部署Elasticsearch

我们使用docker安装elasticsearch，使用命令拉取镜像并且启动容器

```bash
docker run -p 9200:9200 -p 9300:9300 -e cluster.name=elasticsearch -e xpack.security.enabled=false --name=elasticsearch --restart=always -d wutang/elasticsearch-shanghai-zone:6.3.2
```

使用命令查看启动的容器

```bash
docker ps -a
```

![elasticsearch启动成功.png](https://ws1.sinaimg.cn/large/0072fULUgy1g7svq42gwjj312701iwef.jpg)

可以去主机的9200端口查看ui界面

![elaticseach查看.png](https://ws1.sinaimg.cn/large/0072fULUgy1g7svrqqaspj30b40aljrn.jpg)

#### 3. 部署collector

下载skywalking[下载](http://skywalking.apache.org/downloads/)

这里使用的是6.x版本，相比于5.x版本，6.x版本的ui界面高大上许多。下载完解压后目录如下

![skyapm目录.png](https://ws1.sinaimg.cn/large/0072fULUgy1g7sw2v248hj30jq080q3d.jpg)

由于skywalking默认是使用h2作为数据存储，我们是使用官方推荐的elasticsearch作为数据存储，所以我们要修改一下配置文件` config\application.yml`，注释掉h2的配置，打开elasticsearch的配置，并且配置好elasticsearch的地址。

![配置.png](https://ws1.sinaimg.cn/large/0072fULUgy1g7sw85krcjj30n30e8jt0.jpg)

##### 配置信息

```
/config/application.yml
cluster:
   # 单节点模式
   standalone:
   # zk用于管理collector集群协作.
   # zookeeper:
      # 多个zk连接地址用逗号分隔.
      # hostPort: localhost:2181
      # sessionTimeout: 100000
   # 分布式 kv 存储设施，类似于zk，但没有zk重型（除了etcd，consul、Nacos等都是类似功能）
   # etcd:
      # serviceName: ${SW_SERVICE_NAME:"SkyWalking_OAP_Cluster"}
      # 多个节点用逗号分隔, 如: 10.0.0.1:2379,10.0.0.2:2379,10.0.0.3:2379
      # hostPort: ${SW_CLUSTER_ETCD_HOST_PORT:localhost:2379}
core:
   default:
      # 混合角色：接收代理数据，1级聚合、2级聚合
      # 接收者：接收代理数据，1级聚合点
      # 聚合器：2级聚合点
      role: ${SW_CORE_ROLE:Mixed} # Mixed/Receiver/Aggregator
 
       # rest 服务地址和端口
      restHost: ${SW_CORE_REST_HOST:localhost}
      restPort: ${SW_CORE_REST_PORT:12800}
      restContextPath: ${SW_CORE_REST_CONTEXT_PATH:/}
 
      # gRPC 服务地址和端口
      gRPCHost: ${SW_CORE_GRPC_HOST:localhost}
      gRPCPort: ${SW_CORE_GRPC_PORT:11800}
 
      downsampling:
      - Hour
      - Day
      - Month
 
      # 设置度量数据的超时。超时过期后，度量数据将自动删除.
      # 单位分钟
      recordDataTTL: ${SW_CORE_RECORD_DATA_TTL:90}
 
      # 单位分钟
      minuteMetricsDataTTL: ${SW_CORE_MINUTE_METRIC_DATA_TTL:90}
 
      # 单位小时
      hourMetricsDataTTL: ${SW_CORE_HOUR_METRIC_DATA_TTL:36}
 
      # 单位天
      dayMetricsDataTTL: ${SW_CORE_DAY_METRIC_DATA_TTL:45}
 
      # 单位月
      monthMetricsDataTTL: ${SW_CORE_MONTH_METRIC_DATA_TTL:18}
 
storage:
 
   elasticsearch:
 
      # elasticsearch 的集群名称
      nameSpace: ${SW_NAMESPACE:"local-ES"}
 
      # elasticsearch 集群节点的地址及端口
      clusterNodes: ${SW_STORAGE_ES_CLUSTER_NODES:192.168.2.10:9200}
 
      # elasticsearch 的用户名和密码
      user: ${SW_ES_USER:""}
      password: ${SW_ES_PASSWORD:""}
 
      # 设置 elasticsearch 索引分片数量
      indexShardsNumber: ${SW_STORAGE_ES_INDEX_SHARDS_NUMBER:2}
 
      # 设置 elasticsearch 索引副本数
      indexReplicasNumber: ${SW_STORAGE_ES_INDEX_REPLICAS_NUMBER:0}
 
      # 批量处理配置
      # 每2000个请求执行一次批量
      bulkActions: ${SW_STORAGE_ES_BULK_ACTIONS:2000}
 
      # 每 20mb 刷新一次内存块
      bulkSize: ${SW_STORAGE_ES_BULK_SIZE:20}
 
      # 无论请求的数量如何，每10秒刷新一次堆
      flushInterval: ${SW_STORAGE_ES_FLUSH_INTERVAL:10}
 
      # 并发请求的数量
      concurrentRequests: ${SW_STORAGE_ES_CONCURRENT_REQUESTS:2}
 
      # elasticsearch 查询的最大数量
      metadataQueryMaxSize: ${SW_STORAGE_ES_QUERY_MAX_SIZE:5000}
 
      # elasticsearch 查询段最大数量
      segmentQueryMaxSize: ${SW_STORAGE_ES_QUERY_SEGMENT_SIZE:200}
```

配置完后进入` bin`目录，执行批处理文件，windows下为`startup.bat`,linux为` startup.sh`。启动成功后访问8080端口。出现如下界面则说明skywalking部署成功，接下来可以进行客户端接入

![skywalkingUI.png](https://ws1.sinaimg.cn/large/0072fULUgy1g7swh0wpm0j313y0l9gmp.jpg)

