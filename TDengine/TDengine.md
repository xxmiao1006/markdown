## TDengine

​		TDengine是一个高效的存储、查询、分析时序大数据的平台(**时序数据库**)，专为物联网、车联网、工业互联网、运维监测等优化而设计。可以像使用关系型数据库MySQL一样来使用。

仔细研究发现，物联网、车联网、运维监测类数据还具有很多明显的特征：

* 数据高度结构化；
* 数据极少有更新或删除操作；
* 无需传统数据库的事务处理；
* 相对互联网应用，写多读少；
* 流量平稳，根据设备数量和采集频次，可以预测出来；
* 用户关注的是一段时间的趋势，而不是某一特定时间点的值；
* 数据有保留期限；
* 数据的查询分析一定是基于时间段和空间区域；
* 除存储、查询操作外，还需要各种统计和实时计算操作；
* 数据量巨大，一天可能采集的数据就可以超过100亿条。数据高度结构化；
* 数据极少有更新或删除操作；
* 无需传统数据库的事务处理；
* 相对互联网应用，写多读少；
* 流量平稳，根据设备数量和采集频次，可以预测出来；
* 用户关注的是一段时间的趋势，而不是某一特定时间点的值；
* 数据有保留期限；
* 数据的查询分析一定是基于时间段和空间区域；
* 除存储、查询操作外，还需要各种统计和实时计算操作；
* 数据量巨大，一天可能采集的数据就可以超过100亿条。

TDengine就是针对这种数据来设计的。

### 一. TDengine的搭建

​		实验环境：centos7

​		官网直接下载安装包 [下载链接](https://www.taosdata.com/cn/getting-started/#%E9%80%9A%E8%BF%87%E5%AE%89%E8%A3%85%E5%8C%85%E5%AE%89%E8%A3%85)，然后直接解压安装，这里注意下，如果不使用`--nodeps`会提示你安装python3，实际不需要，可以忽略掉。这里下载的是 2.0.16版本。

```bash
tar -zxvf Python-3.6.1.tgz
rpm -iv --nodeps  TDengine-server-2.0.16.0-Linux-x64.rpm 
```

```bash
[root@node1 ~]# rpm -iv --nodeps  TDengine-server-2.0.16.0-Linux-x64.rpm  
软件包准备中...
tdengine-2.0.16.0-3.x86_64
Start to install TDengine...
Created symlink from /etc/systemd/system/multi-user.target.wants/taosd.service to /etc/systemd/system/taosd.service.

System hostname is: localhost.localdomain

Enter FQDN:port (like h1.taosdata.com:6030) of an existing TDengine cluster node to join
OR leave it blank to build one:

Enter your email address for priority support or enter empty to skip: 

To configure TDengine : edit /etc/taos/taos.cfg
To start TDengine     : sudo systemctl start taosd
To access TDengine    : taos -h localhost.localdomain to login into TDengine server
```

​		直接通过`systemctl`启动

​		启动后可以通过`systemctl status  taos`查看是否启动成功 

```bash
[root@node1 ~]# systemctl status taosd
● taosd.service - TDengine server service
   Loaded: loaded (/etc/systemd/system/taosd.service; enabled; vendor preset: disabled)
   Active: active (running) since 二 2021-03-09 10:29:20 CST; 1 weeks 1 days ago
  Process: 22282 ExecStartPre=/usr/local/taos/bin/startPre.sh (code=exited, status=0/SUCCESS)
 Main PID: 22296 (taosd)
   CGroup: /system.slice/taosd.service
           └─22296 /usr/bin/taosd

3月 09 10:29:20 node1 systemd[1]: Starting TDengine server service...
3月 09 10:29:20 node1 systemd[1]: Started TDengine server service.
3月 09 10:29:20 node1 TDengine:[22296]: Starting TDengine service...
3月 09 10:29:20 node1 TDengine:[22296]: Started TDengine service successfully.

```

可以进入`usr/local/taos`查看TDengine目录结构		

```bash
[root@node1 taos]# cd /usr/local/taos/
[root@node1 taos]# ll
总用量 0
drwxr-xr-x  2 root root 144 3月   4 17:17 bin
drwxr-xr-x  2 root root  42 3月   4 17:17 cfg					#配置文件
drwxr-xr-x  6 root root 104 3月   4 17:17 connector   
lrwxrwxrwx  1 root root  13 3月   4 17:17 data -> /var/lib/taos  #数据存储目录
drwxr-xr-x  2 root root  33 3月   4 17:17 driver
drwxr-xr-x 12 root root 121 3月   4 17:17 examples     			#各种语言代码示例
drwxr-xr-x  2 root root  39 3月   4 17:17 include
drwxr-xr-x  2 root root  19 3月   4 17:17 init.d
lrwxrwxrwx  1 root root  13 3月   4 17:17 log -> /var/log/taos   #日志目录，启动失败可以看日志
drwxr-xr-x  2 root root  37 3月   4 17:17 script
```

​		从里面我们可以看到数据存储的目录`/var/lib/taos`和日志的目录`/var/log/taos`。

###  二. TDengine TAOS： 访问TDengine的简便方式

​		在搭建完TDengine服务端后，我们可以在服务端直接用命令行访问TDengine,只要在Linux终端执行`taos`即可。注意如果在其他内网机器想要通过命令行访问，需要在机器上安装TDengine客户端（通过代码连接也是需要的）

```bash
[root@node1 ~]# taos

Welcome to the TDengine shell from Linux, Client Version:2.0.16.0
Copyright (c) 2020 by TAOS Data, Inc. All rights reserved.

taos> 

```

​		在TDengine终端中，用户可以通过SQL命令来创建/删除数据库、表等，并进行插入查询操作。和mysql的控制台是类似的。

**命令行参数**

您可通过配置命令行参数来改变TDengine终端的行为。以下为常用的几个命令行参数：

- -c, --config-dir: 指定配置文件目录，默认为*/etc/taos*
- -h, --host: 指定服务的IP地址，默认为本地服务
- -s, --commands: 在不进入终端的情况下运行TDengine命令
- -u, -- user: 连接TDengine服务器的用户名，缺省为root
- -p, --password: 连接TDengine服务器的密码，缺省为taosdata
- -?, --help: 打印出所有命令行参数

```bash
taos -h 192.168.0.1 -s "use db; show tables;"
```



### 三. TDengine的数据模型 

#### 数据模型

​		这里想要说明一下的是TDengine的数据建模，TDengine仍然是采用关系数据模型，需要建库建表，这和其他关系型数据库一样，需要注意的是TDengine提出了**超级表**的概念。

​		在典型的物联网、车联网、运维监测场景中，往往有多种不同类型的数据采集设备，采集一个到多个不同的物理量。而同一种采集设备类型，往往又有多个具体的采集设备分布在不同的地点。大数据处理系统就是要将各种采集的数据汇总，然后进行计算和分析。对于同一类设备，其采集的数据都是很规则的。以智能电表为例，假设每个智能电表采集电流、电压、相位三个量，其采集的数据类似如下的表格。

|  设备ID   |    时间戳     | 采集量  | 采集量 | 采集量 |          标签        | 标签 |
| :-------: | :-----------: | :-----: | :-----: | :---: | :--------------: | :-----: |
| Device ID |  Time Stamp   | current | voltage | phase |     location     | groupId |
|   d1001   | 1538548685000 |  10.3   |   219   | 0.31  | Beijing.Chaoyang |    2    |
|   d1002   | 1538548684000 |  10.2   |   220   | 0.23  | Beijing.Chaoyang |    3    |
|   d1003   | 1538548686500 |  11.5   |   221   | 0.35  | Beijing.Haidian  |    3    |
|   d1004   | 1538548685500 |  13.4   |   223   | 0.29  | Beijing.Haidian  |    2    |
|   d1001   | 1538548695000 |  12.6   |   218   | 0.33  | Beijing.Chaoyang |    2    |
|   d1004   | 1538548696600 |  11.8   |   221   | 0.28  | Beijing.Haidian  |    2    |
|   d1002   | 1538548696650 |  10.3   |   218   | 0.25  | Beijing.Chaoyang |    3    |
|   d1001   | 1538548696800 |  12.3   |   221   | 0.31  | Beijing.Chaoyang |    2    |

​		每一条记录都有设备ID，时间戳，采集的物理量(如上图中的电流、电压、相位），还有与每个设备相关的静态标签（如上述表一中的位置Location和分组groupId）。每个设备是受外界的触发，或按照设定的周期采集数据。采集的数据点是时序的，是一个数据流。

**一个数据采集点一张表**

​		为充分利用其数据的时序性和其他数据特点，TDengine要求**对每个数据采集点单独建表**（比如有一千万个智能电表，就需创建一千万张表，上述表格中的d1001, d1002, d1003, d1004都需单独建表），用来存储这个采集点所采集的时序数据。这种设计有几大优点：

1. 能保证一个采集点的数据在**存储介质上是以块为单位连续存储**的。如果读取一个时间段的数据，它能大幅减少随机读取操作，成数量级的提升读取和查询速度。
2. 由于不同采集设备产生数据的过程完全独立，每个设备的数据源是唯一的，一张表也就只有一个写入者，这样就**可采用无锁方式来写，写入速度就能大幅提升**。
3. 对于一个数据采集点而言，其产生的数据是时序的，因此写的操作可用追加的方式实现，进一步大幅提高数据写入速度。

​		如果采用传统的方式，将多个设备的数据写入一张表，由于网络延时不可控，不同设备的数据到达服务器的时序是无法保证的，写入操作是要有锁保护的，而且一个设备的数据是难以保证连续存储在一起的。**采用一个数据采集点一张表的方式，能最大程度的保证单个数据采集点的插入和查询的性能是最优的。**



**超级表：同一类型数据采集点的集合**

​		由于一个数据采集点一张表，导致表的数量巨增，难以管理，而且应用经常需要做采集点之间的聚合操作，聚合的操作也变得复杂起来。为解决这个问题，TDengine引入超级表(Super Table，简称为STable)的概念。

​		超级表是指某一特定类型的数据采集点的集合。同一类型的数据采集点，其表的结构是完全一样的，但每个表（数据采集点）的静态属性（标签）是不一样的。描述一个超级表（某一特定类型的数据采集点的结合），除需要定义采集量的表结构之外，还需要定义其标签的schema，标签的数据类型可以是整数、浮点数、字符串，标签可以有多个，可以事后增加、删除或修改。 如果整个系统有N个不同类型的数据采集点，就需要建立N个超级表。

​		在TDengine的设计里，**表用来代表一个具体的数据采集点，超级表用来代表一组相同类型的数据采集点集合**。当为某个具体数据采集点创建表时，用户使用超级表的定义做模板，同时指定该具体采集点（表）的标签值。与传统的关系型数据库相比，表（一个数据采集点）是带有静态标签的，而且这些标签可以事后增加、删除、修改。**一张超级表包含有多张表，这些表具有相同的时序数据schema，但带有不同的标签值**。

​		当对多个具有相同数据类型的数据采集点进行聚合操作时，TDengine将先把满足标签过滤条件的表从超级表的中查找出来，然后再扫描这些表的时序数据，进行聚合操作，这样能将需要扫描的数据集大幅减少，从而大幅提高聚合计算的性能。



#### 建模示例

​		上面大致描述了一下TDengine中的超级表和表的概念，下面以智能电表为例进行数据建模。

##### 1. 创建库

​		不同类型的数据采集点往往具有不同的数据特征，包括**数据采集频率的高低，数据保留时间的长短，副本的数目，数据块的大小，是否允许更新数据**等等。为让各种场景下TDengine都能最大效率的工作，**TDengine建议将不同数据特征的表创建在不同的库里，因为每个库可以配置不同的存储策略**。创建一个库时，除SQL标准的选项外，应用还可以指定保留时长、副本数、内存块个数、时间精度、文件块里最大最小记录条数、是否压缩、一个数据文件覆盖的天数等多种参数。

```sql
CREATE DATABASE power KEEP 365 DAYS 10 BLOCKS 4 UPDATE 1;
```

​		上述语句将创建一个名为power的库，这个库的数据将保留365天（超过365天将被自动删除），每10天一个数据文件，内存块数为4，允许更新数据。可用的参数如下：

- days：一个数据文件存储数据的时间跨度，单位为天，默认值：10。

- keep：数据库中数据保留的天数，单位为天，默认值：3650。

- minRows：文件块中记录的最小条数，单位为条，默认值：100。

- maxRows：文件块中记录的最大条数，单位为条，默认值：4096。

- comp：文件压缩标志位，0：关闭；1：一阶段压缩；2：两阶段压缩。默认值：2。

- walLevel：WAL级别。1：写wal，但不执行fsync；2：写wal, 而且执行fsync。默认值：1。

- fsync：当wal设置为2时，执行fsync的周期。设置为0，表示每次写入，立即执行fsync。单位为毫秒，默认值：3000。

- cache：内存块的大小，单位为兆字节（MB），默认值：16。

- blocks：每个VNODE（TSDB）中有多少cache大小的内存块。因此一个VNODE的用的内存大小粗略为（cache * blocks）。单位为块，默认值：4。

- replica：副本个数，取值范围：1-3。单位为个，默认值：1

- precision：时间戳精度标识，ms表示毫秒，us表示微秒。默认值：ms

- cacheLast：是否在内存中缓存子表 last_row，0：关闭；1：开启。默认值：0。（从 2.0.11 版本开始支持此参数）

- update: 为1时支持更新操作，0不支持，默认值：0

  可以使用命令`show databases`查看创建的数据库以及一些配置的参数。

```bash
taos> show databases;
              name              |      created_time       |   ntables   |   vgroups   | replica | quorum |  days  |   keep0,keep1,keep(D)    |  cache(MB)  |   blocks    |   minrows   |   maxrows   | wallevel |    fsync    | comp | cachelast | precision | update |   status   |
====================================================================================================================================================================================================================================================================================
 test                           | 2021-03-08 10:50:22.182 |        1000 |           1 |       1 |      1 |     10 | 3650,3650,3650           |          16 |           6 |         100 |        4096 |        1 |        3000 |    2 |         0 | ms        |      0 | ready      |
 log                            | 2021-03-04 17:19:13.364 |           4 |           1 |       1 |      1 |     10 | 30,30,30                 |           1 |           3 |         100 |        4096 |        1 |        3000 |    2 |         0 | us        |      0 | ready      |
 power                          | 2021-03-17 11:56:36.512 |           0 |           0 |       1 |      1 |     10 | 365,365,365              |          16 |           4 |         100 |        4096 |        1 |        3000 |    2 |         0 | ms        |      1 | ready      |
 db                             | 2021-03-08 14:00:54.053 |           1 |           1 |       1 |      1 |     10 | 3650,3650,3650           |          16 |           4 |         100 |        4096 |        1 |        3000 |    2 |         0 | ms        |      0 | ready      |
Query OK, 4 row(s) in set (0.029333s)

```

##### 2. 创建超级表

​		一个物联网系统，往往存在多种类型的设备，比如对于电网，存在智能电表、变压器、母线、开关等等。为便于多表之间的聚合，使用TDengine, 需要对每个类型的数据采集点创建一超级表。以智能电表为例，可以使用如下的SQL命令创建超级表

```sql
CREATE STABLE meters (ts timestamp, current float, voltage int, phase float) TAGS (location binary(64), groupdId int);
```

​		与创建普通表一样，创建表时，需要提供表名（示例中为meters），表结构Schema，即数据列的定义。**第一列必须为时间戳**（示例中为ts)，其他列为采集的物理量（示例中为current, voltage, phase)，数据类型可以为整型、浮点型、字符串等。除此之外，还需要提供标签的schema (示例中为location, groupId)，标签的数据类型可以为整型、浮点型、字符串等。**采集点的静态属性往往可以作为标签**，比如采集点的地理位置、设备型号、设备组ID、管理员ID等等。标签的schema可以事后增加、删除、修改。具体定义以及细节请见 [TAOS SQL 的超级表管理](https://www.taosdata.com/cn/documentation/taos-sql#super-table) 章节。

一张超级表最多容许1024列，如果一个采集点采集的物理量个数超过1024，需要建多张超级表来处理。一个系统可以有多个DB，一个DB里可以有一到多个超级表。

##### 3. 创建表

​		TDengine对每个数据采集点需要独立建表。与标准的关系型数据一样，一张表有表名，Schema，但除此之外，还可以带有一到多个标签。创建时，需要使用超级表做模板，同时指定标签的具体值。以表一中的智能电表为例，可以使用如下的SQL命令建表：

```sql
CREATE TABLE d1001 USING meters TAGS ("Beijing.Chaoyang", 2);
```

​		其中d1001是表名，meters是超级表的表名，后面紧跟标签Location的具体标签值”Beijing.Chaoyang"，标签groupId的具体标签值2。虽然在创建表时，需要指定标签值，但可以事后修改。详细细则请见 [TAOS SQL 的表管理](https://www.taosdata.com/cn/documentation/taos-sql#table) 章节。

​		**TDengine建议将数据采集点的全局唯一ID作为表名(比如设备序列号）。但对于有的场景，并没有唯一的ID，可以将多个ID组合成一个唯一的ID。不建议将具有唯一性的ID作为标签值**。

​	**自动建表**：在某些特殊场景中，用户在写数据时并不确定某个数据采集点的表是否存在，此时可在写入数据时使用自动建表语法来创建不存在的表，若该表已存在则不会建立新表。比如：

```sql
INSERT INTO d1001 USING METERS TAGS ("Beijng.Chaoyang", 2) VALUES (now, 10.2, 219, 0.32);
```

​		上述SQL语句将记录 (now, 10.2, 219, 0.32) 插入表d1001。如果表d1001还未创建，则使用超级表meters做模板自动创建，同时打上标签值“Beijing.Chaoyang", 2。

​		关于自动建表的详细语法请参见 [插入记录时自动建表](https://www.taosdata.com/cn/documentation/taos-sql#auto_create_table) 章节。

其实了解完TDengine的数据建模后，我们会将它与传统的sqlserver、mysql等数据库的建模相对比，很明显TDengine的这种数据建模方式更加针对物联网行业，更加针对时序数据。对采集点单独建表，不仅降低了数据存储的复杂性。更将数据查询效率提示了几个数量级； 将静态数据标签化极大的节省了静态数据的存储空间。

##### 4. 多列模型 vs 单列模型

​		TDengine支持多列模型，只要物理量是一个数据采集点同时采集的（时间戳一致），这些量就可以作为不同列放在一张超级表里。但还有一种极限的设计，单列模型，每个采集的物理量都单独建表，因此每种类型的物理量都单独建立一超级表。比如电流、电压、相位，就建三张超级表。

​		TDengine建议尽可能采用多列模型，因为插入效率以及存储效率更高。但对于有些场景，一个采集点的采集量的种类经常变化，这个时候，如果采用多列模型，就需要频繁修改超级表的结构定义，让应用变的复杂，这个时候，采用单列模型会显得简单。

#### 存储模型

​		TDengine存储的数据包括采集的时序数据以及库、表相关的元数据、标签数据等，这些数据具体分为三部分：

- 时序数据：通过采用一个采集点一张表的模型，一个时间段的数据是连续存储，对单张表的写入是简单的追加操作，一次读，可以读到多条记录，这样保证对单个采集点的插入和查询操作，性能达到最优。
- 标签数据：存放于vnode里的meta文件，支持增删改查四个标准操作。数据量不大，有N张表，就有N条记录，因此**可以全内存存储**。如果标签过滤操作很多，查询将十分频繁，因此TDengine支持多核多线程并发查询。只要计算资源足够，即使有数千万张表，过滤结果能毫秒级返回。
- 元数据：包含系统节点、用户、DB、Table Schema等信息，支持增删改查四个标准操作。这部分数据的量不大，可以全内存保存，而且由于客户端有缓存，查询量也不大。因此目前的设计虽是集中式存储管理，但不会构成性能瓶颈。

与典型的NoSQL存储模型相比，TDengine将标签数据与时序数据完全分离存储，它具有两大优势：

- 能够极大地降低标签数据存储的冗余度：一般的NoSQL数据库或时序数据库，采用的K-V存储，其中的Key包含时间戳、设备ID、各种标签。每条记录都带有这些重复的内容，浪费存储空间。而且如果应用要在历史数据上增加、修改或删除标签，需要遍历数据，重写一遍，操作成本极其昂贵。
- 能够实现极为高效的多表之间的聚合查询：做多表之间聚合查询时，先把符合标签过滤条件的表查找出来，然后再查找这些表相应的数据块，这样大幅减少要扫描的数据集，从而大幅提高查询效率。而且标签数据采用全内存的结构进行管理和维护，千万级别规模的标签数据查询可以在毫秒级别返回。

​		

想要了解更多请参考[TDengine数据模型和整体架构](https://www.taosdata.com/cn/documentation/architecture#model)

### 四. TDengine性能测试

​		测试环境： centos7 虚拟机， 8核32G, 使用官方示例以10个线程模拟10个链接，每个链接每次请求插入1000条数据，总共往1000个数据库每个数据库里插入100000条数据，总共1亿条数据，测试写入、查询性能，并且观察1亿数据所占磁盘空间大小，查看数据压缩算法的性能。

```bash
[root@localhost lib]# taosdemo -t 1000 -n 100000
###################################################################
# Server IP:                         localhost:0
# User:                              root
# Password:                          taosdata
# Use metric:                        true
# Datatype of Columns:               int int int int int int int float 
# Binary Length(If applicable):      -1
# Number of Columns per record:      3
# Number of Threads:                 10
# Number of Tables:                  1000
# Number of Data per Table:          100000
# Records/Request:                   1000
# Database name:                     test
# Table prefix:                      t
# Delete method:                     0
# Test time:                         2021-03-08 10:50:01
###################################################################

##数据库配置
taos> show databases;
              name              |      created_time       |   ntables   |   vgroups   | replica | quorum |  days  |   keep0,keep1,keep(D)    |  cache(MB)  |   blocks    |   minrows   |   maxrows   | wallevel |    fsync    | comp | cachelast | precision | update |   status   |
====================================================================================================================================================================================================================================================================================
 test                           | 2021-03-08 10:50:22.182 |        1000 |           1 |       1 |      1 |     10 | 3650,3650,3650           |          16 |           6 |         100 |        4096 |        1 |        3000 |    2 |         0 | ms        |      0 | ready 


##超级表结构
taos> describe test.meters ;
             Field              |         Type         |   Length    |   Note   |
=================================================================================
 ts                             | TIMESTAMP            |           8 |          |
 f1                             | INT                  |           4 |          |
 f2                             | INT                  |           4 |          |
 f3                             | INT                  |           4 |          |
 areaid                         | INT                  |           4 | TAG      |
 loc                            | BINARY               |          10 | TAG      |
Query OK, 6 row(s) in set (0.024501s)

##普通表结构
taos> describe test.t1 ;
             Field              |         Type         |   Length    |   Note   |
=================================================================================
 ts                             | TIMESTAMP            |           8 |          |
 f1                             | INT                  |           4 |          |
 f2                             | INT                  |           4 |          |
 f3                             | INT                  |           4 |          |
 areaid                         | INT                  |           4 | TAG      |
 loc                            | BINARY               |          10 | TAG      |
Query OK, 6 row(s) in set (0.030036s)

```

* 创建数据库,可以看到在0.4885s 创建好了1000个数据库

```bash
Creating meters super table...
meters created!
create table......
Creating table from 0 to 99
Creating table from 100 to 199
Creating table from 200 to 299
Creating table from 300 to 399
Creating table from 400 to 499
Creating table from 500 to 599
Creating table from 600 to 699
Creating table from 700 to 799
Creating table from 800 to 899
Creating table from 900 to 999
Spent 0.4885 seconds to create 1000 tables with 10 connections
```

#### 插入数据

​		10个线程以 1000records / request 插入1亿数据花费了 81.2108秒，写入性能达到1231363.30 records/second

```bash
Inserting data......
SYNC Insert with 10 connections:
Spent 81.2108 seconds to insert 100000000 records with 1000 record(s) per request: 1231363.30 records/second
insert delay, avg:   3.713379ms, max: 200.696000ms, min:   0.955000ms
```

#### 查询数据

​		以不同的条件、函数等做示例

```bash
Where condition: areaid = 1
select          * took 3.384394 second(s)

Where condition: areaid = 1 or areaid = 2 
select          * took 7.550554 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3 
select          * took 10.925874 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4 
select          * took 15.282361 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5 
select          * took 19.674449 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6 
select          * took 24.227113 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7 
select          * took 28.556858 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8 
select          * took 33.008950 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9 
select          * took 38.703300 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9  or areaid = 10 
select          * took 43.590366 second(s)

Where condition: areaid = 1
select   count(*) took 0.025194 second(s)

Where condition: areaid = 1 or areaid = 2 
select   count(*) took 0.034948 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3 
select   count(*) took 0.056405 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4 
select   count(*) took 0.083299 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5 
select   count(*) took 0.086486 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6 
select   count(*) took 0.102238 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7 
select   count(*) took 0.131608 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8 
select   count(*) took 0.128230 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9 
select   count(*) took 0.164125 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9  or areaid = 10 
select   count(*) took 0.178595 second(s)

Where condition: areaid = 1
select    avg(f1) took 0.037597 second(s)

Where condition: areaid = 1 or areaid = 2 
select    avg(f1) took 0.079839 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3 
select    avg(f1) took 0.109661 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4 
select    avg(f1) took 0.135424 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5 
select    avg(f1) took 0.198729 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6 
select    avg(f1) took 0.231769 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7 
select    avg(f1) took 0.269865 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8 
select    avg(f1) took 0.299164 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9 
select    avg(f1) took 0.331940 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9  or areaid = 10 
select    avg(f1) took 0.348635 second(s)

Where condition: areaid = 1
select    sum(f1) took 0.039283 second(s)

Where condition: areaid = 1 or areaid = 2 
select    sum(f1) took 0.070957 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3 
select    sum(f1) took 0.111735 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4 
select    sum(f1) took 0.134681 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5 
select    sum(f1) took 0.174341 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6 
select    sum(f1) took 0.207145 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7 
select    sum(f1) took 0.270399 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8 
select    sum(f1) took 0.336404 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9 
select    sum(f1) took 0.437470 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9  or areaid = 10 
select    sum(f1) took 0.414024 second(s)

Where condition: areaid = 1
select    max(f1) took 0.035580 second(s)

Where condition: areaid = 1 or areaid = 2 
select    max(f1) took 0.081659 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3 
select    max(f1) took 0.103483 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4 
select    max(f1) took 0.145270 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5 
select    max(f1) took 0.171827 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6 
select    max(f1) took 0.267316 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7 
select    max(f1) took 0.247778 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8 
select    max(f1) took 0.314483 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9 
select    max(f1) took 0.312259 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9  or areaid = 10 
select    max(f1) took 0.382516 second(s)

Where condition: areaid = 1
select    min(f1) took 0.043306 second(s)

Where condition: areaid = 1 or areaid = 2 
select    min(f1) took 0.077856 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3 
select    min(f1) took 0.103554 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4 
select    min(f1) took 0.137697 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5 
select    min(f1) took 0.177541 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6 
select    min(f1) took 0.261640 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7 
select    min(f1) took 0.274016 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8 
select    min(f1) took 0.274705 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9 
select    min(f1) took 0.314388 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9  or areaid = 10 
select    min(f1) took 0.379401 second(s)

Where condition: areaid = 1
select  first(f1) took 0.018450 second(s)

Where condition: areaid = 1 or areaid = 2 
select  first(f1) took 0.038220 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3 
select  first(f1) took 0.058192 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4 
select  first(f1) took 0.080654 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5 
select  first(f1) took 0.093259 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6 
select  first(f1) took 0.123205 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7 
select  first(f1) took 0.133690 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8 
select  first(f1) took 0.145858 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9 
select  first(f1) took 0.168809 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9  or areaid = 10 
select  first(f1) took 0.179103 second(s)

Where condition: areaid = 1
select   last(f1) took 0.021641 second(s)

Where condition: areaid = 1 or areaid = 2 
select   last(f1) took 0.051385 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3 
select   last(f1) took 0.070362 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4 
select   last(f1) took 0.085282 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5 
select   last(f1) took 0.125976 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6 
select   last(f1) took 0.133965 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7 
select   last(f1) took 0.148518 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8 
select   last(f1) took 0.185621 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9 
select   last(f1) took 0.198738 second(s)

Where condition: areaid = 1 or areaid = 2  or areaid = 3  or areaid = 4  or areaid = 5  or areaid = 6  or areaid = 7  or areaid = 8  or areaid = 9  or areaid = 10 
select   last(f1) took 0.243156 second(s)
```

#### 数据压缩

​		以下是插入前后磁盘所用对比 1亿条数据，大概使用了200M空间

```bash
##插入 1000个表  每个表100000条数据  共一亿条数据  下面是插入前后磁盘使用对比 总共用了200M空间
[root@localhost lib]# du -h --max-depth=1
1.6M  ./taos
72M .


[root@localhost lib]# du -h --max-depth=1
203M  ./taos
273M  .
```

按照上面的数据结构算一条记录大概是 `8+4+4+4=20Byte` 

`100,000,000 * 20Byte / 1024 / 1024 =2,670 MB`

通过粗略计算大概需要2.5G的存储空间，但是TDengine最后只使用了200MB

对比sqlserver差不多的数据结构下2700W数据大约是300多MB，粗略估算1亿数据差不多是1.2G~1.5个G

所以在TDengine二级压缩策略下是可以省下大量磁盘空间的。官方测算TDengine对比通用数据库，存储空间使用不到其他的1/10，这里测算大概是sqlserver的1/7~1/6。

官方测算：

1000万台智能电表，每台电表每15分钟采集一次数据，每次采集的数据128字节，那么一年的原始数据量是：`10000000*128*24*60/15*365 = 44.8512T`。TDengine大概需要消耗44.851/5=8.97024T空间。

更详细的计算请参考：

**立即计算CPU、内存、存储，请参见：[资源估算方法](https://www.taosdata.com/config/config.html)**



### 五. TDengine  JDBC demo

[jdbc、springboot demo](https://github.com/xxmiao1006/taosdemo)

### 六. TDengine行业应用案例 

[代替 TimescaleDB，TDengine 接管数据量日增 40 亿条的光伏日电系统](https://www.taosdata.com/blog/2020/09/30/1872.html)

[数据传输、存储、展现，EMQ X + TDengine 搭建 MQTT 物联网数据可视化平台](https://www.taosdata.com/blog/2020/08/04/1722.html)

[解决海量时序数据的存储和计算，TDengine在智慧环保上的应用](https://www.taosdata.com/blog/2020/07/30/1689.html)

[实现雨量监测预警，TDengine在智慧水务大数据中的应用](https://www.taosdata.com/blog/2020/07/17/1668.html)

[TDengine开源版本在电力运维平台的应用](https://www.taosdata.com/blog/2020/07/09/1648.html)

[Spark+TDengine 在中国电信电力测功系统监控平台上的应用实践](https://www.taosdata.com/blog/2020/06/18/1614.html)

[TDengine加持，一周时间上线环保监测平台  (springcloud+mybatis plus、流式聚合计算)](https://www.taosdata.com/blog/2020/06/12/1602.html)

[TDengine在华夏天信露天煤矿智慧矿山操作系统的应用](https://www.taosdata.com/blog/2020/06/09/1588.html)

[存储地面运动数据，TDengine在地震自动监测系统中的应用](https://www.taosdata.com/blog/2020/06/03/1571.html)

[一条SQL语句搞定半导体行业采集的μs级数据](https://www.taosdata.com/blog/2020/06/01/1553.html)

[一个「开创型」功能的诞生：从降维聚合到 1μs 补值排序](https://www.taosdata.com/blog/2020/05/09/1502.html)

[接手被MySQL卡死的数据，TDengine在能源管理系统的应用](https://www.taosdata.com/blog/2020/04/16/1453.html)

[使用 TDengine 进行报警监测](https://www.taosdata.com/blog/2020/04/14/1438.html)

[从OpenTSDB到TDengine，如何做好工业物联网的数据库选型？（采用单列存储）](https://www.taosdata.com/blog/2020/04/08/1427.html)

[拒绝高深技术栈，裸机10分钟搭建酷炫的工业物联网监控平台  （采用了单列存储-详细](https://www.taosdata.com/blog/2020/03/30/1378.html)

[TDengine在SCARM云设备服务平台的使用](https://www.taosdata.com/blog/2020/03/04/1326.html)

[TDengine在智慧排水系统中的应用介绍 (单列存储)](https://www.taosdata.com/blog/2020/02/12/1264.html)

[TDengine在数字治理系统中处理轨迹数据的应用](https://www.taosdata.com/blog/2020/01/15/1140.html)

[TDengine在星诺好管车的应用实践](https://www.taosdata.com/blog/2019/11/29/941.html)

[使用TDengine快速搭建车联网平台](https://www.taosdata.com/blog/2019/07/10/143.html)



### 七. 总结

TDengine优点：

* 专门针对物联网时序数据设计，节省大量存储成本和计算成本，与Hadoop体系相比，Hadoop模块多且重，不管是学习成本还是运维成本都非常高。
* 较小的学习成本（与MySQL相似）与运维成本（集群搭建较为简单）支持Python/Java/C/C++/C#/Go/Node.js。
* 与许多第三方组件无缝对接（Grafana、EMQ X、Prometheus等）



TDengine缺点：

* 相较于sql，还有许多语法未完善
  * 暂不支持 OR 连接的不同列之间的查询过滤条件
  * 目前 distinct 关键字只支持对超级表的标签列进行去重，而不能用于普通列
  * 目前不支持多表的联合检索

* 仍然处于发展阶段，bug较多。版本并不稳定。

* 虽然一定程度上解决了大数据量的问题，但也是基于内存存储以及优化磁盘存储结构来解决的，当数据达到一定量级的时候想要保持较高的查询检索效率可能需要较高的内存成本，问题无法从根本上解决（压力依然在云端）。



​		综合学习成本，性能、运维成本等来看TDengine确实是物联网行业一个比较好的时序数据解决方案，相较于sqlserver等其他数据库有无法比拟的优势,是一个比较值得尝试的解决方案。



TODO LIST

* TDengine集群搭建
* TDengine高性能写入组件开发





超级表：
多列存储模式  （效率高，不够灵活，需要在初期就确定设备类型的采集物理量和频率）
 1.同时采集同表：一张超级表里，包含的采集物理量必须是同时采集的，也就是说时间戳都是相同的
 2.对同一个类型的设备，可能存在多组物理量，且每组的物理量并不是同时采集的，则需要为每组物理量单独建立一个超级表，因此一个类型的设备，可能需要建立多个超级表
 3.系统有N个类型的设备，就至少需要建立N个超级表
 4.一个系统可以有多个DB库，一个DB库可以有多个超级表

 比如一个采集终端采集的参数包括电流、电压、环境温度、湿度。电流电压5S采集一次，温度湿度1min采集一次，可以创建两个超级表 meter_power(电流、电压)、meter_temper(温度、湿度)

单列存储模式 （插入和存储效率没有多列存储高，需要创建非常多的表，但更灵活，后期可增加采集种类）
 1.每个物理量都单独建表
 2.一个设备或者采集点的物理量种类经常变化，建议采用单列模型
 比如电流电压，两个量就键两个超级表

一个变量一张表，这样做的优势是非常明显的。每张表里面只存一个变量的数据即使每秒写入一次，1个月也只有260万条，对其作指定时间范围的查询，不用考虑其他变量的数据，直接从时间戳索引得到想要时间范围的数据，效率很高。云组态的需求正是短时间内有很多变量按秒存储，保存半年左右，并且在此情况下，用户想查询任意一个变量的历史情况都能够快速得到响应。针对平台，在每个设备类型采集参数种类不确定、采集频率不确定的情况下，建议采用单列模型。



1.以schemaless方式使用TDengine（单列存储模式）
创建数据库iot_datas，数据的保持时间为365天，过期的数据将会被成块删除：
CREATE DATABASE IF NOT EXISTS iot_datas KEEP 365

超级表iot_meters用于存储设备的数据信息创建超级表的语句如下：
CREATE TABLE iot_meters (ts timestamp, value double) TAGS(device_id binary(20), point_id binary(20));

create table iot_meters_1_1 using iot_meters tags (1,1);
create table iot_meters_60000_1 using iot_meters tags (60000,1)

假设有 1 个设备 meter_001，设备下有 1 路温度 temp 和 1 路湿度 humi，我们可以采用写入数据自动建表的方法：
INSERT INTO iot_datas.meter_001_humi USING iot_datas.iot_meters TAGS ('meter_001', 'humi') VALUES ('2018-01-01 00:00:00.000',95);
INSERT INTO iot_datas.meter_001_temp USING iot_datas.iot_meters TAGS ('meter_001', 'temp') VALUES ('2018-01-01 00:00:00.000',20);

自动建表语句只能自动建立子表而不能建立超级表，这就要求超级表已经被事先定义好。这里实现schemaless的方式就是将超级表定义成一个单值模型，也即每条记录为：时间戳+采集值。在超级表的标签列中，要定义出设备ID、点位ID甚至点位物理量名称、点位分组等信息。这样同一设备不同点位的数据上报后，可以通过自动建表的语法向其对应子表中写入，在写入时指定tag值。此时，如果此点位对应子表不存在则会被自动创建；如果此点位对应子表已经存在，则TDengine本身会跳过建表过程，直接写入数据，这样也就是实现了一种schemaless的写入方式。

当然，在确定设备（子表）已经存在的情况下，可以同时向不同的超级表中同时插入数据。注意为了提高写入速度，对同一条insert SQL语句，可以向多张表插入新记录，具体如下：

INSERT INTO iot_datas.meter_001_humi VALUES ('2018-01-01 00:00:01.000', 95)    iot_datas.meter_001_temp VALUES ('2018-01-01 00:00:01.000', 20)


days：数据文件存储数据的时间跨度，单位为天
keep：数据保留的天数
rows: 文件块中记录条数
comp: 文件压缩标志位，0：关闭，1:一阶段压缩，2:两阶段压缩
ctime：数据从写入内存到写入硬盘的最长时间间隔，单位为秒
clog：数据提交日志(WAL)的标志位，0为关闭，1为打开
tables：每个vnode允许创建表的最大数目
cache: 内存块的大小（字节数）
tblocks: 每张表最大的内存块数
ablocks: 每张表平均的内存块数
precision：时间戳为微秒的标志位，ms表示毫秒，us表示微秒

/etc/taos/taos.cfg
```bash
# max number of tables per vnode
# maxTablesPerVnode         1000000

# cache block size (Mbyte)
# cache                     16

# number of cache blocks per vnode
# blocks                    6

# number of days per DB file
# days                  10

# number of days to keep DB file
# keep                  3650

# minimum rows of records in file block
# minRows               100

# maximum rows of records in file block
# maxRows               4096

# max length of an SQL
# maxSQLLength          65480
```



测试创建表的数量

https://www.taosdata.com/blog/2019/12/03/965.html 创建数据表时提示more dnodes are needed
create database db tables 2000 cache 10240 ablocks 4 tblocks 50 
cache*ablocks + tblocks*8 + 1000