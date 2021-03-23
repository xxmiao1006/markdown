## redis

docker	启动redis并配置密码

```bash
docker pull redis:latest
docker run --name redis-tensquare -p 6379:6379 -d --restart=always redis:latest redis-server --appendonly yes --requirepass "sUlnkfBOQ3MglYN1"

```



## centos 安装redis

```bash
wget http://download.redis.io/releases/redis-4.0.11.tar.gz
tar xzf redis-6.0.6.tar.gz
cd redis-6.0.6
make
make install
```





## 单线程

redis的核心命令执行模块是单线程，其他模块还是有它各自的模块的线程模型

一般来说 Redis 的瓶颈并不在 CPU，而在内存和网络。如果要使用 CPU 多核，可以搭建多个 Redis 实例来解决

其实，Redis 4.0 开始就有多线程的概念了，比如 Redis 通过多线程方式在后台删除对象、以及通过 Redis 模块实现的阻塞命令等。

 Redis 6 正式发布了，其中有一个是被说了很久的多线程IO

这个 Theaded IO 指的是在网络 IO 处理方面上了多线程，如网络数据的读写和协议解析等，需要注意的是，执行命令的核心模块还是单线程的。

之前的段落说了，Redis 的瓶颈并不在 CPU，而在内存和网络。

内存不够的话，可以加内存或者做数据结构优化和其他优化等，但网络的性能优化才是大头，网络 IO 的读写在 Redis 整个执行期间占用了大部分的 CPU 时间，如果把网络处理这部分做成多线程处理方式，那对整个 Redis 的性能会有很大的提升。

最后，目前最新的 6.0 版本中，IO 多线程处理模式默认是不开启的，需要去配置文件中开启并配置线程数





[如何优雅地用Redis实现分布式锁](https://baijiahao.baidu.com/s?id=1623086259657780069&wfr=spider&for=pc)

[redis官方中文文档](http://www.redis.cn/topics/distlock.html)

