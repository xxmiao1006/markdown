## 消息中间件RabbitMQ

### 一. RabbitMQ简介

消息队列中间件简介：

消息队列中间件是分布式系统中重要的组件，主要解决应用耦合，异步消息，流量削锋等问题实现高性能，高可用，可伸缩和最终一致性[架构] 使用较多的消息队列有ActiveMQ，RabbitMQ，ZeroMQ，Kafka，MetaMQ，RocketMQ。

以下介绍消息队列在实际应用中常用的使用场景：异步处理，应用解耦，流量削锋和消息通讯四个场景

什么是RabbitMQ？

RabbitMQ 是一个由 Erlang 语言开发的 AMQP 的开源实现。

AMQP ：Advanced Message Queue，高级消息队列协议。它是应用层协议的一个开放标准，为面向消息的中间件设计，基于此协议的客户端与消息中间件可传递消息，并不受产品、开发语言等条件的限制。

RabbitMQ 最初起源于金融系统，用于在分布式系统中存储转发消息，在易用性、扩展
性、高可用性等方面表现不俗。具体特点包括：

* 可靠性（Reliability）RabbitMQ 使用一些机制来保证可靠性，如持久化、传输确认、发布确认。

* 灵活的路由（Flexible Routing）在消息进入队列之前，通过 Exchange 来路由消息的。对于典型的路由功能，RabbitMQ已经提供了一些内置的 Exchange 来实现。针对更复杂的路由功能，可以将多个
  Exchange 绑定在一起，也通过插件机制实现自己的 Exchange 。

* 消息集群（Clustering）多个 RabbitMQ 服务器可以组成一个集群，形成一个逻辑 Broker

* 高可用（Highly Available Queues）队列可以在集群中的机器上进行镜像，使得在部分节点出问题的情况下队列仍然可用。

* 多种协议（Multi-protocol）RabbitMQ 支持多种消息队列协议，比如 STOMP、MQTT 等等。

* 多语言客户端（Many Clients）RabbitMQ 几乎支持所有常用语言，比如 Java、.NET、Ruby 等等。

* 管理界面（Management UI）RabbitMQ 提供了一个易用的用户界面，使得用户可以监控和管理消息 Broker 的许多方面。

* 跟踪机制（Tracing）如果消息异常，RabbitMQ 提供了消息跟踪机制，使用者可以找出发生了什么。

* 插件机制（Plugin System）RabbitMQ 提供了许多插件，来从多方面进行扩展，也可以编写自己的插件。

### 二. 主要概念

![rabbitmq架构图.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1gaox4gr1ssj30h5075jri.jpg)

**RabbitMQ Server**： 也叫broker server，它是一种传输服务。 他的角色就是维护一条从Producer到Consumer的路线，保证数据能够按照指定的方式进行传输。

**Producer**： 消息生产者，如图A、B、C，数据的发送方。消息生产者连接RabbitMQ服务器然后将消息投递到Exchange。

**Consumer**：消息消费者，如图1、2、3，数据的接收方。消息消费者订阅队列，RabbitMQ将Queue中的消息发送到消息消费者。

**Exchange**：生产者将消息发送到Exchange（交换器），由Exchange将消息路由到一个或多个Queue中（或者丢弃）。Exchange并不存储消息。RabbitMQ中的Exchange有direct、fanout、topic、headers四种类型，每种类型对应不同的路由规则。

**Queue**：（队列）是RabbitMQ的内部对象，用于存储消息。消息消费者就是通过订阅队列来获取消息的，RabbitMQ中的消息都只能存储在Queue中，生产者生产消息并最终投递到Queue中，消费者可以从Queue中获取消息并消费。多个消费者可以订阅同一个Queue，这时Queue中的消息会被平均分摊给多个消费者进行处理，而不是每个消费者都收到所有的消息并处理。

**RoutingKey**：生产者在将消息发送给Exchange的时候，一般会指定一个routing key，来指定这个消息的路由规则，而这个routing key需要与Exchange Type及binding key联合使用才能最终生效。在Exchange Type与binding key固定的情况下（在正常使用时一般这些内容都是固定配置好的），我们的生产者就可以在发送消息给Exchange时，通过指定routing key来决定消息流向哪里。RabbitMQ为routing key设定的长度限制为255bytes。

**Connection**： （连接）：Producer和Consumer都是通过TCP连接到RabbitMQ Server的。以后我们可以看到，程序的起始处就是建立这个TCP连接。

**Channels**： （信道）：它建立在上述的TCP连接中。数据流动都是在Channel中进行的。也就是说，一般情况是程序起始建立TCP连接，第二步就是建立这个Channel。

**VirtualHost**：权限控制的基本单位，一个VirtualHost里面有若干Exchange和MessageQueue，以及指定被哪些user使用

### 三. docker下安装rabbitmq

（1）下载镜像：

```bash
docker pull rabbitmq:management
```

（2）创建容器，rabbitmq需要有映射以下端口: 5671 5672 4369 15671 15672 25672

* 15672 (if management plugin is enabled)
* 15671 management监听端口
* 5672, 5671 (AMQP 0-9-1 without and with TLS)
* 4369 (epmd) epmd 代表 Erlang 端口映射守护进程
* 25672 (Erlang distribution)

```bash
docker run -di --name=tensquare_rabbitmq -p 5671:5617 -p 5672:5672 -p4369:4369 -p 15671:15671 -p 15672:15672 -p 25672:25672 rabbitmq:management
```

### 四. rabbitmq的使用

#### 1.直接模式（Direct）

我们需要将消息发给唯一一个节点时使用这种模式，这是最简单的一种形式。

![direct-exchage.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1gaozpm4xrpj30hg08haa6.jpg)

任何发送到Direct Exchange的消息都会被转发到RouteKey中指定的Queue。
1.一般情况可以使用rabbitMQ自带的Exchange：”"(该Exchange的名字为空字符串，下文称其为default Exchange)。
2.这种模式下不需要将Exchange进行任何绑定(binding)操作
3.消息传递时需要一个“RouteKey”，可以简单的理解为要发送到的队列名字。
**4.如果vhost中不存在RouteKey中指定的队列名，则该消息会被抛弃**。

只有一个消费者可以接收到消息。

`provider -> queue`

#### 2.分列模式（Fanout）

当我们需要将消息一次发给多个队列时，需要使用这种模式

![fanout-exchange.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1gaozou96xqj30h00933yo.jpg)

任何发送到Fanout Exchange的消息都会被转发到与该Exchange绑定(Binding)的所有Queue上。
1.可以理解为路由表的模式
2.这种模式不需要RouteKey
3.这种模式需要提前将Exchange与Queue进行绑定，一个Exchange可以绑定多个
Queue，一个Queue可以同多个Exchange进行绑定。
**4.如果接受到消息的Exchange没有与任何Queue绑定，则消息会被抛弃**。

`provider -> exchange ->exchange bind queues`

#### 3.主题模式（Topic）

任何发送到Topic Exchange的消息都会被转发到所有关心RouteKey中指定话题的Queue上

![topic-exchage.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1gaoyvurrllj30im097jrw.jpg)

如上图所示
此类交换器使得来自不同的源头的消息可以到达一个对列，其实说的更明白一点就是模糊匹配的意思，例如：上图中红色对列的routekey为usa.#，#代表匹配任意字符，但是要想消息能到达此对列，usa.必须匹配后面的#好可以随意。图中usa.news,usa.weather,都能找到红色队列，符号 # 匹配一个或多个词，符号 * 匹配不多不少一个
词。因此 usa.# 能够匹配到 usa.news.XXX ，但是 usa.* 只会匹配到 usa.XXX 。

注：

交换器说到底是一个名称与队列绑定的列表。当消息发布到交换器时，实际上是由你所连接的信道，将消息路由键同交换器上绑定的列表进行比较，最后路由消息。

任何发送到**Topic Exchange**的消息都会被转发到所有关心**RouteKey**中指定话题的**Queue**上

1.这种模式较为复杂，简单来说，就是每个队列都有其关心的主题，所有的消息都带有一个“标题”(RouteKey)，Exchange会将消息转发到所有关注主题能与RouteKey模糊匹配的队列。

2.这种模式需要RouteKey，也许要提前绑定Exchange与Queue。

3.在进行绑定时，要提供一个该队列关心的主题，如“#.log.#”表示该队列关心所有涉及log的消息(一个RouteKey为”MQ.log.error”的消息会被转发到该队列)。

4.“#”表示0个或若干个关键字，“”表示一个关键字。如“log.”能与“log.warn”匹配，无法与“log.warn.timeout”匹配；但是“log.#”能与上述两者匹配。

5.同样，如果Exchange没有发现能够与RouteKey匹配的Queue，则会抛弃此消息

### 五. Rabbitmq的模式

#### 1. 单一模式

即单机情况不做集群，就单独运行一个rabbitmq而已。

#### 2. 普通模式

默认模式，以两个节点（rabbit01、rabbit02）为例来进行说明。对于Queue来说，消息实体只存在于其中一个节点rabbit01（或者rabbit02），rabbit01和rabbit02两个节点仅有相同的元数据，即队列的结构。当消息进入rabbit01节点的Queue后，consumer从rabbit02节点消费时，RabbitMQ会临时在rabbit01、rabbit02间进行消息传输，把A中的消息实体取出并经过B发送给consumer。所以consumer应尽量连接每一个节点，从中取消息。即对于同一个逻辑队列，要在多个节点建立物理Queue。否则无论consumer连rabbit01或rabbit02，出口总在rabbit01，会产生瓶颈。当rabbit01节点故障后，rabbit02节点无法取到rabbit01节点中还未消费的消息实体。如果做了消息持久化，那么得等rabbit01节点恢复，然后才可被消费；如果没有持久化的话，就会产生消息丢失的现象。

#### 3. 镜像模式

把需要的队列做成镜像队列，存在与多个节点属于**RabbitMQ的HA方案。**该模式解决了普通模式中的问题，其实质和普通模式不同之处在于，消息实体会主动在镜像节点间同步，而不是在客户端取数据时临时拉取。该模式带来的副作用也很明显，除了降低系统性能外，如果镜像队列数量过多，加之大量的消息进入，集群内部的网络带宽将会被这种同步通讯大大消耗掉。所以在对可靠性要求较高的场合中适用。



![rabbitmq权限](E:\git-markdown\markdown\images\rabbitmq\rabbitmq权限.png)



![rabbitmq权限-2](E:\git-markdown\markdown\images\rabbitmq\rabbitmq权限-2.png)





### 问题

1. 什么样的消息会进入死信队列？

1.消息的TTL过期。
2.消费者对broker应答Nack，并且消息禁止重回队列。
3.Queue队列长度已达上限。



2. 如果MQ数据丢失了，有哪几个方面？

生产者(可以用transcation或者confirm模式解决)，

消息队列(持久化到磁盘)，

消费者(手动确认ACK)。



3. 如何避免消息重复投递或重复消费(消费者处理消息幂等?)

在消息⽣生产时，MQ内部针对每条⽣生产者发送的消息⽣生成⼀一个inner-msg-id，作为去重和幂等的依据（消息投递失败并重传），避免重复的消息进⼊入队列列；在消息消费时，要求消息体中必须要有⼀个bizId（对于同⼀业务全局唯一，如⽀支付ID、订单ID、帖⼦子ID等）作为去重和幂等的依据，避免同⼀条消息被重复消费。



[搭建rabbitmq高可用](https://www.cnblogs.com/knowledgesea/p/6535766.html)

[RabbitMQ如何处理消息丢失](https://segmentfault.com/a/1190000019125512)

[消息队列之 RabbitMQ](https://www.jianshu.com/p/79ca08116d57)

[springboot + rabbitmq 消息确认机制](https://blog.csdn.net/zhangweiwei2020/article/details/107250202/)

[rabbitmq unacked消息如何处理_RabbitMQ 如何保证消息可靠性(详细)](https://blog.csdn.net/weixin_39774808/article/details/111173256)

[如何保证消息不被重复消费？](https://www.cnblogs.com/aaron911/p/11612920.html)

[消息队列面试连环问：如何保证消息不丢失？处理重复消息？消息有序性？消息堆积处理？](https://mp.weixin.qq.com/s?__biz=MzkxNTE3NjQ3MA==&mid=2247485753&idx=1&sn=d22f8adc8eb0dfc08163e160127f6b17&chksm=c1626440f615ed565d8a2ceee7335ddce26ce2d9364474a276e8dbb8767bcc6ebb0f7e298f71&mpshare=1&scene=24&srcid=0420JPgrORaR97Ywr7QgNIH0&sharer_sharetime=1618881118549&sharer_shareid=232a5434dda7f9bc9ee0a06a8085ff95#rd)

[RabbitMQ 七种队列模式应用场景案例分析（通俗易懂）](https://mp.weixin.qq.com/s?__biz=MzI5ODI5NDkxMw==&mid=2247539541&idx=3&sn=c64045d8776aa13509acd5d4b7688a43&chksm=ecaa10bbdbdd99adce2976bba0605d142f09051063699dff962b65d311da7796fb8fc8b5720e&mpshare=1&scene=24&srcid=0420GkKpKjoAdT4bpfp99ZnW&sharer_sharetime=1618875716031&sharer_shareid=232a5434dda7f9bc9ee0a06a8085ff95#rd)

[面试题系列：MQ 夺命连环11问](https://mp.weixin.qq.com/s?__biz=MzI0NTE4NjA0OQ==&mid=2658374961&idx=1&sn=63aea1ec6fe47dca3542900af5c054dc&chksm=f2d55e5fc5a2d749af5ebb965eac0d09ba2f586875f119fe98db3a059ac331a52a8bd842fe06&mpshare=1&scene=24&srcid=0503wGpBC7g9bVqOPOw9755r&sharer_sharetime=1620033842736&sharer_shareid=232a5434dda7f9bc9ee0a06a8085ff95#rd)

[RabbitMQ-HA搭建-部署](https://blog.csdn.net/qq_37681291/article/details/81099318)

[提升RabbitMQ消费速度的一些实践](https://www.cnblogs.com/bossma/p/practices-on-improving-the-speed-of-rabbitmq-consumption.html)

