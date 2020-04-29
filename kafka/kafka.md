## kafka

​	Kafka 是一个**分布式**的基于**发布/订阅模式**的**消息队列**（Message Queue），主要应用于
大数据实时处理领域。(消息存磁盘，默认存7天)

 ### 一. 消息队列的两种模式 

#### 1. peer to peer  点对点 一对一 ，消费者主动拉取数据，消息收到后消息清除	

​		消息生产者生产消息发送到Queue中，然后消息消费者从Queue中取出并且消费消息。消息被消费以后，queue 中不再有存储，所以消息消费者不可能消费到已经被消费的消息。Queue 支持存在多个消费者，但是对一个消息而言，只会有一个消费者可以消费。

#### 2 . 发布/订阅模式（一对多,消费者消费数据之后不会清除消息）发布订阅模式里面又包含两种。

​	一种是消息队列主动推给消费者（可能消费者处理能力不同造成消费者崩溃或者是消费者资源浪费），

​	一种是消费者自己拉（这样需要每个消费者去轮询消息队列，给消息队列造成压力，另外消息什么时候清除呢？）（kafka）

​		消息生产者（发布）将消息发布到 topic 中，同时有多个消息消费者（订阅）消费该消息。和点对点方式不同，发布到 topic 的消息会被所有订阅者消费。							

______

### 二. kafka基础架构

![kafka基础架构.png](https://wx1.sinaimg.cn/large/0072fULUgy1ge97np0igrj311x0ksaf2.jpg)



* **Producer** ：消息生产者，就是向 kafka broker 发消息的客户端；

* **Consumer** ：消息消费者，向 kafka broker 取消息的客户端

* **Consumer Group （CG**）：消费者组，由**多个 consumer 组成**。消费者组内每个消费者负
  责消费不同分区的数据，**一个分区只能由一个组内消费者消费**；消费者组之间互不影响。所
  有的消费者都属于某个消费者组，即消费者组是逻辑上的一个**订阅者**。

* **Broker** ：一台 kafka 服务器就是一个 broker。一个集群由多个 broker 组成。一个 broker
  可以容纳多个 topic。

* **Topic** ：可以理解为一个队列，生产者和消费者面向的都是一个 topic；

* **Partition**：为了实现扩展性，一个非常大的 topic 可以分布到多个 broker（即服务器）上，
  一个 topic 可以分为多个 partition，每个 partition 是一个有序的队列；

* **Replica**：副本，为保证集群中的某个节点发生故障时，该节点上的 partition 数据不丢失，且 kafka 仍然能够继续工作，kafka 提供了副本机制，一个 topic 的每个分区都有若干个副本，
  一个 leader 和若干个 follower。（副本数<=broker数目）

* **leader**：每个分区多个副本的“主”，生产者发送数据的对象，以及消费者消费数据的对
  象都是 leader。

* **follower**：每个分区多个副本中的“从”，实时从 leader 中同步数据，保持和 leader 数据
  的同步。leader 发生故障时，某个 follower 会成为新的 follower。

------

### 三. kafka 测试

1. 启动zookeeper

```bash
./zookeeper-server-start.sh -daemon ../config/zookeeper.properties 
```

2. 启动kafka server

```bash
./kafka-server-start.sh -daemon ../config/server.properties
```

3. 启动生产者

```bash
/kafka-console-producer.sh --broker-list localhost:9092 --topic first
```

4. 启动消费者

```bash
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --from-beginning --topic first

./kafka-console-consumer.sh --zookeeper localhost:2181 --from-beginning --topic first
```

5. 删除topic

```bash
./kafka-topics.sh --zookeeper localhost:2181 --delete --topic first
```

kafka数据是存在磁盘中的，为什么查找数据还会快？

一个topic有多个partition，一个partition有多个segment，每个segment对应.log和.index文件，index文件里面存的是偏移量。和对应消息在.log文件的位置（包括文件的大小），.index文件里面的元数据大小基本都是固定的，所以可以通过偏移量快速找到该条信息在.log文件中的位置与大小，这样取出来就非常快了。