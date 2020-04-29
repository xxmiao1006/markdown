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