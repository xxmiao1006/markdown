

### 一. 技术栈

* 熟悉 JAVA 集合,多线程,面向对象等基础知识。
* 掌握常用的计算机网络和操作系统基础知识。
* 熟悉JVM，熟悉常用的GC算法和垃圾收集器。有JVM参数优化经验
* 熟悉springboot和spring cloud alibaba，有分布式微服务开发经验。
* 熟悉mysql,对mysql有一定的研究，有sql优化经验。
* 熟悉其他常用中间件比如rabbitmq、redis。参与了系统缓存模块的构建。
* 有云原生开发经验。

### 二. 工作		

* 根据产品文档，设计与开发产品完整功能。
* 参与技术方案讨论，对平台进行优化，并协助架构师进行技术预研。
* 负责平台BUG修复，保障稳定性，协助运维搭建devops体系工具链（ELK、skywalking等）。
* 担任过项目经理，经历过产品从零到上线的整个过程。

### 三. 项目

1. Xhub    springboot+springcloud+redis+mysql+rabbitmq+nginx

- 数据源连接管理
- 产品标准库管理
- 数据源档案管理
- 安全开发

实时数据模块数据优化（redis）

分布式锁



项目感悟：



2. 新加坡efos平台

`Azure IoT PaaS Services`

这个是戴德梁行、微软与我们公司合作开发的，因为一些平台合规的要求，需要使用微软提供的云计算中间件和服务来构建整个技术架构和解决方案。在这个项目中由我对微软的一些云计算中间件和服务进行了技术预研，比如iothub、cosmosdb、function、streamAnalystic,storage等，通过微软专家的协助，最终搭建了符合我们平台业务的技术架构。



项目感悟：对平台进行技术选型的时候，不仅仅需要考虑技术合理性和业务达标，还要考虑成本。PasS化节省了大量的部署成本、运维成本，开发也不复杂。但是仍然需要大家去学习，有学习成本，还有，云计算的组件和服务费用都很高，一定要多做测试选择合理的架构和付费套餐，能节省大量费用。



3. efos平台  grpc

* 刚进来就参与项目从单体到微服务的重构
* 供电局项目
* 项目经理-负责efos平台其中青桔产品的落地-洗手间屏-态势屏-手环-对讲机手持机。
* 综合态势功能点

项目感悟： 在平台微服务化的过程中，出现了很多微服务带来的问题，问题故障难以排查，运维难度增加，在基础设施不够完善的情况下，慎用微服务。

**设计缓存系统（见redis）**

**分布式微服务---系统拆分过程、grpc**

> 单体服务->微服务
>
> AggregService聚合服务和grpcService原子服务
>
> 第一次：最开始是将一些基础服务抽象成grpc服务，使用Aggreg服务提供接口->团队划分为应用开发组（Aggreg和部分业务服务）和核心数据组（数据对接、以及一些核心基础服务）
>
> 第二次：由于产品增多，将最开始的聚合层进一步划分，通过产品线进行划分，这样每个产品发布的时候互不影响（比如3.0平台coreAggreg、洗手间产品toiletAggreg、巡检屏产品screenAggreg）
>
> 第三次：由于一个产品线的项目较多，将应用开发组进一步拆分->  应用开发一组、二组，不同组负责不同的产品服务继续拆分 toiletAggreg->toiletScreenAggreg、toiletAppAggreg等。
>
> 内网调用肯定走rpc   而且可以让不同团队使用不同的技术栈
>
> grpc pb协议
>
> [为什么 PB 的效率是最高的？](https://doocs.gitee.io/advanced-java/#/./docs/distributed-system/dubbo-serialization-protocol?id=为什么-pb-的效率是最高的？)
>
> 其实 PB 之所以性能如此好，主要得益于两个：**第一**，它使用 proto 编译器，自动进行序列化和反序列化，速度非常快，应该比 `XML` 和 `JSON` 快上了 `20~100` 倍；**第二**，它的数据压缩效果好，就是说它序列化后的数据量体积小。因为体积小，传输起来带宽和速度上会有优化。



**青桔**

智慧洗手间产品 迭代过两次  从最开始的手环、蓝牙网关到现如今的  对讲机手持机，还有洗手间屏、洗手间态势屏。

模块：洗手间问题项方案配置模块、问题项转工单模块、流程处理模块（bpm流转）、洗手间态势屏展示模块（层级方案配置、大屏监管显示、指标配置）

难点：定位的问题

​			动态指标，在态势大屏要有一个获取指标数据的接口，每个层级的指标是动态配置的，要通过一个接口返回配置的所有指标和数据，问题，每个指标的定义有点不一样，有的一个值，有的两个值，后续可能还要增加指标给每一个指标定义一个策略，每一个返回值定义一个指标基础父类，定义通用的方法计算指标，返回通用父类，内部实现每个指标用不同的策略去计算。



**项目经理经验**：对于一个项目来说，一定要有一个驱动人去驱动整个项目组，而最适合的人选就是后端，后端直接跟产品、前端、运维打交道。对于需求来说，不仅仅有业务开发的需求，还有运维需求、开发测试人员的需求，项目经理需要协调各项需求，保证项目能按计划完成。我们项目有硬件相关，需要协调采购、硬件等部门联合帮助测试进行产品测试。



**jvm调优**

碰到的问题

现象:程序假死，不停进行FGC ，进程没有挂掉 但是无法处理任何请求

看日志  outofmemory metaSpace，说明是元空间不够了   jdk使用元空间替代永久代，里面存放的是类信息mataSapce内存溢出基本都是加载类异常。

使用jstat --gc utils 查看GC状况，发现FGC次数一直在暴增，这说明GC后还是空间不够，看了参数最大值是128M，很奇怪的一点是，jstat打印出来的M为83%  说明其实metaSpace没有被用完，还有空间，但是还是无法分配空间，拿到了GCLOG和dump文件后，迅速调大了MetaSpace的大小重启了服务，问题解决后续分析原因  

> 类被卸载的条件：
>
> 1. 该类所有的实例已经被回收
> 2. 加载该类的ClassLoder已经被回收
>
> 3. 该类对应的java.lang.Class对象没有任何对方被引用

> 其实这里有两个疑问，1.metaSpace哪些类占了这么多空间，是不是全部都是有用的 ，还是有的没用了无法被卸载导致内存泄漏。2.为什么通过jstat工具看到metaspace空间明明还有空间还是会报outofmemory？
>
> 首先查看了gclog，这里可以使用在线GC分析GClog  可以看到一些指标，但是这里我想看发生FGC的原因，所以直接打开看，发现大量`Metadata GC Threshold`，后面的大小使用显然没有到最大的128M，这里很明显就可以看出来这里是因为metaspace的内存碎片化。在进一步使用dump文件分析，发现其中有一个DelegatingClassLoader有700多个，后来发现这个是在sun.reflect包下，这里就可以看出来是和反射有关系了

> metaSpace碎片化原因
>
> 在 Java 虚拟机中，每个类加载器都有一个 ClassLoaderData 的数据结构，ClassloaderData 内部有管理内存的 Metaspace，Metaspace 在 initialize 的时候会调用 get_initialization_chunk 分配第一块 Metachunk，类加载器在类的时候是以 Metablock 为单位来使用 Metachunk。
>
> 通常一个类加载器在申请 Metaspace 空间用来存放 metadata 的时候，也就需要几十到几百个字节，但是它会得到一个 Metachunk，一个比要求的内存大得多的内存块。
>
> 前面说了，chunk 有三种规格，那 Metaspace 的分配器怎么知道一个类加载器每次要多大的 chunk 呢？这当然是基于猜测的：
>
> - 通常，一个标准的类加载器在第一次申请空间时，会得到一个 4K 的 chunk，直到它达到了一个随意设置的阈值（4），此时分配器失去了耐心，之后会一次性给它一个 64K 的大 chunk。
> - bootstrap classloader 是一个公认的会加载大量的类的加载器，所以分配器会给它一个巨大的 chunk，一开始就会给它 4M。可以通过 InitialBootClassLoaderMetaspaceSize 进行调优。
> - 反射类类加载器 (`jdk.internal.reflect.DelegatingClassLoader`) 和匿名类类加载器只会加载一个类，所以一开始只会给它们一个非常小的 chunk（1K），因为给它们太多就是一种浪费。

> **简单来说，由于使用太多反射，并且该参数设置的阈值较小导致触发 JVM 的反射优化操作，反射调用时会根据每个方法生成一个包装了这个方法的类加载器DelegatingClassLoader和Java类 MethodAccessor，如果反射方法很多的话 就会生成N多字节码，（每个加载器只加载一个类 会造成大量的碎片化）导致metaspace 溢出**  大流量入口频繁使用反射



2.解决完metaspace的溢出后，运营反馈在大流量的时候接口还是有明显卡顿，7天后再次查看GC日志发现FGC很频繁，在gceasy看到最长一次gc时间达到了3S，cms为低停顿著名，3S几乎是不可以接受的（同时看到metaSpace峰值最大到了124M，这也同时反应了之前的128M是不够的）且有规律的出现大量`concurrent mode failure`。这个在深入理解jvm中介绍过，cms收集有一个阈值，老年代大小到达后开启回收，因为cms是并发回收，并发过程中如果留下的内存不够则会冻结用户线程的执行，临时启用Serial Old收集器来重新进行老年代的垃圾收集，停顿时间就很长了。

> CMS收集器的启动阈值就已经默认提升至92%。（1.5默认68%）但这又会更容易面临另一种风险：要是CMS运行期间预留的内存无法满足程序分配新对象的需要，就会出现一次“并发失败”（Concurrent Mode Failure）

这里将-Xms1024M -Xmx1024M -Xmn375M，同时将阈值降低，在并发收集过程中留出更多的内存给工作线程用。同时使用-XX：CMSInitiatingOccu-pancyFraction调低了阈值到80%

> -XX:CMSInitiatingOccupancyFraction=70 是指设定CMS在对内存占用率达到70%的时候开始GC(因为CMS会有浮动垃圾,所以一般都较早启动GC);
>
>    -XX:+UseCMSInitiatingOccupancyOnly 只是用设定的回收阈值(上面指定的70%),如果不指定,JVM仅在第一次使用设定值,后续则自动调整.

jstat打印gc信息

FGC 7天/200次/99S    YGC  7天/1065次/171S 

以减少GC次数为目标，降低停顿时间

> nohup java -jar -server -Xms512M -Xmx512M  -Xss512k -XX:MetaspaceSize=128M -XX:MaxMetaspaceSize=128M -XX:+UseConcMarkSweepGC -XX:+PrintGCDateStamps -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/root/Xhub/dumpLocation  -XX:+PrintGCDetails -Xloggc:/root/Xhub/gclogs/devicegc.log  -XX:+UnlockCommercialFeatures  -XX:+FlightRecorder -Dcom.sun.management.jmxremote.rmi.port=1099 -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=1.0.0.6 DSLinkHub-Xhub-device-server-1.0-SNAPSHOT.jar --server.port=8769 > /root/Xhub/serviceLogs/device-8769.txt &



将xms xmx调整成一样的，防止内存重分配造成内存震荡，使用了xmn 调整新生代的大小（减少ygc的次数），一般调整为整个堆的3/8   这里直接用xmn设置成375M

调优后

> nohup java -jar -server -Xms1024M -Xmx1024M -Xmn375M -Xss512k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseConcMarkSweepGC -XX:+PrintGCDateStamps -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/root/Xhub/dumpLocation  -XX:+PrintGCDetails -Xloggc:/root/Xhub/gclogs/devicegc.log  -XX:+UnlockCommercialFeatures  -XX:+FlightRecorder -Dcom.sun.management.jmxremote.rmi.port=1099 -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.local.only=false -Djava.rmi.server.hostname=1.0.0.6 DSLinkHub-Xhub-device-server-1.0-SNAPSHOT.jar --server.port=8769 > /root/Xhub/serviceLogs/device-8769.txt &





**对新技术以及学习的一些感悟：**

1.永远不要为了高大上而去引入新技术，引入新技术的前提有两个：

* 你已经确定当前的问题已经无法通过当前的技术栈来解决，必须通过第三方组件或新技术来解决。
* 你已经进行充分的学习和预研，在能解决当前问题的前提下，你还能解决由于引入新组件而带来的新问题！！

2 .对于程序员来说，学习是一辈子的事情，并不是说现在没用到就不需要去学，很多东西可能现在没用，看起来学着没用，但肯定能在未来的某一时刻帮你解决问题或者帮你剪掉错误的道路，最大限度减少你试错的成本。





**遇到的问题以及解决**

redis stringkye 占内存的问题  bigkey的问题 见过生产环境一个hashkey 有几百万field

缓存穿透         

jvm调优

数据库优化(服务端参数，索引重建)

mybatis   interceptor

MQ  消息顺序性问题   一个队列一个消费者 但是扩展性?







**为什么想来大厂？**

在小公司经历过各种从0到无，但是没有体验过互联网公司公司量级的技术栈，相比从一开始就进大厂的人，可能我更懂得什么知识才是比较珍贵的。要学习的东西有哪些。主要是自己踩过很多坑，想看看大厂的人是怎么解决或者避免这种坑的。平台还是非常重要的，各有各的好处与坏处。

真正看重的，不是说你掌握高并发相关的一些基本的架构知识，架构中的一些技术，RocketMQ、Kafka、Redis、Elasticsearch，高并发这一块，你了解了，也只能是次一等的人才。对一个有几十万行代码的复杂的分布式系统，一步一步架构、设计以及实践过高并发架构的人，这个经验是难能可贵的



