## MongoDB简介

MongoDB 是一个跨平台的，面向文档的数据库，是当前 NoSQL 数据库产品中最热门的一种。它介于关系数据库和非关系数据库之间，是非关系数据库当中功能最丰富，最像关系数据库的产品。它支持的数据结构非常松散，是类似 JSON 的 BSON 格式，因此可以存储比较复杂的数据类型。

### 一. 使用情景

* 数据量大（非大数据不用）
*  写入操作频繁
* 数据价值较低（丢失一两条数据无所谓）

这样的数据适合使用MongoDB存储。

### 二. MongoDB特点

MongoDB 最大的特点是他支持的查询语言非常强大，其语法有点类似于面向对象的查询语言，几乎可以实现类似关系数据库单表查询的绝大部分功能，而且还支持对数据建立索引。它是一个面向集合的,模式自由的文档型数据库。

具体特点总结如下：

* 面向集合存储，易于存储对象类型的数据

* 模式自由

* 支持动态查询

* 支持完全索引，包含内部对象

* 支持复制和故障恢复

* 使用高效的二进制数据存储，包括大型对象（如视频等）

* 自动处理碎片，以支持云计算层次的扩展性

* 支持 Python，PHP，Ruby，Java，C，C#，Javascript，Perl 及 C++语言的驱动程序，社区中也提供了对 Erlang 及.NET 等平台的驱动程序

* 文件存储格式为 BSON（一种 JSON 的扩展）

### 三. MongoDB体系

  MongoDB 的逻辑结构是一种层次结构。主要由：文档(document)、集合(collection)、数据库(database)这三部分组成的。逻辑结构是面向用户的，用户使用 MongoDB 开发应用程序使用的就是逻辑结构。

1. MongoDB 的文档（document），相当于关系数据库中的一行记录。
2. 多个文档组成一个集合（collection），相当于关系数据库的表。
3. 多个集合（collection），逻辑上组织在一起，就是数据库（database）。
4. 一个 MongoDB 实例支持多个数据库（database）。

文档(document)、集合(collection)、数据库(database)的层次结构如下图:



### 二. Docker上安装

```
docker run ‐di ‐‐name=tensquare_mongo ‐p 27017:27017 mongo
```



