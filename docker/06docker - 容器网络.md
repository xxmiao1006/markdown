## 容器网络

Docker 网络从覆盖范围可分为单个 host 上的容器网络和跨多个 host 的网络，我们先来了解单个host上的容器网络，我们可以用`docker network ls`命令查看

![docker网络-2.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g948r5xw21j30q405uaad.jpg)

### 一. none网络

故名思议，none 网络就是什么都没有的网络。挂在这个网络下的容器除了 lo，没有其他任何网卡。容器创建时，可以通过 `--network=none` 指定使用 none 网络。

![docker网络-3.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g948srncdbj30og0d20ts.jpg)

封闭意味着隔离，一些对安全性要求高并且不需要联网的应用可以使用 none 网络。比如某个容器的唯一用途是生成随机密码，就可以放到 none 网络中避免密码被窃取。

------



### 二. host 网络

连接到 host 网络的容器共享 Docker host 的网络栈，容器的网络配置与 host 完全一样。可以通过 `--network=host` 指定使用 host 网络。

![docker网络-4.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9490bvfwyj30xs0iowh6.jpg)

在容器中可以看到 host 的所有网卡，并且连 hostname 也是 host 的。直接使用 Docker host 的网络最大的好处就是性能，如果容器对网络传输效率有较高要求，则可以选择 host 网络。当然不便之处就是牺牲一些灵活性，比如要考虑端口冲突问题，Docker host 上已经使用的端口就不能再用了。

Docker host 的另一个用途是让容器可以直接配置 host 网路。比如某些跨 host 的网络解决方案，其本身也是以容器方式运行的，这些方案需要对网络进行配置，比如管理 iptables。

------



### 三. bridge 网络

Docker 安装时会创建一个 命名为 `docker0` 的 linux bridge。如果不指定`--network`，创建的容器默认都会挂到 `docker0` 上。

![docker网络-5.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9496whgppj30r205uq3a.jpg)

当前 docker0 上没有任何其他网络设备，我们创建一个容器看看有什么变化。

![docker网络-6.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9497w4jhpj30qm08gwfb.jpg)

一个新的网络接口 `veth28c57df` 被挂到了 `docker0` 上，`veth28c57df`就是新创建容器的虚拟网卡。

下面看一下容器的网络配置。

![docker网络-7.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g949a4yy96j310s0g476n.jpg)

容器有一个网卡 `eth0@if34`，为什么不是`veth28c57df` 呢？实际上 `eth0@if34` 和 `veth28c57df` 是一对 veth pair。veth pair 是一种成对出现的特殊网络设备，可以把它们想象成由一根虚拟网线连接起来的一对网卡，网卡的一头（`eth0@if34`）在容器中，另一头（`veth28c57df`）挂在网桥 `docker0` 上，其效果就是将 `eth0@if34` 也挂在了 `docker0` 上。我们还看到 `eth0@if34` 已经配置了 IP `172.17.0.2`，为什么是这个网段呢？让我们通过 `docker network inspect bridge` 看一下 bridge 网络的配置信息

![docker网络-8.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g949baku2sj30vq0h6dgr.jpg)

原来 bridge 网络配置的 subnet 就是 172.17.0.0/16，并且网关是 172.17.0.1。这个网关在哪儿呢？大概你已经猜出来了，就是 docker0。

![docker网络-9.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g949f1o11tj30p609qmya.jpg)

![docker网络-10.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g949fkbzobj30k00puaai.jpg)

容器创建时，docker 会自动从 172.17.0.0/16 中分配一个 IP，这里 16 位的掩码保证有足够多的 IP 可以供容器使用。

### 四. user-defined

Docker 提供三种 user-defined 网络驱动：bridge, overlay 和 macvlan。overlay 和 macvlan 用于创建跨主机的网络

我们可通过 bridge 驱动创建类似前面默认的 bridge 网络，例如：

![docker网络-11.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kj9d1rl7j30p803qmxg.jpg)

查看一下当前 host 的网络结构变化：

![docker网络-12.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kjb34p1oj30qq06mgm5.jpg)

新增了一个网桥 `br-eaed97dc9a77`，这里 `eaed97dc9a77` 正好新建 bridge 网络 `my_net` 的短 id。执行 `docker network inspect` 查看一下 `my_net` 的配置信息：

![docker网络-13.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kjc0bu4ej30vo0ocq48.jpg)

这里 172.18.0.0/16 是 Docker 自动分配的 IP 网段。

我们可以自己指定 IP 网段。只需在创建网段时指定 `--subnet` 和 `--gateway` 参数

![docker网络-14.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kjg1sy14j315e0q8ac4.jpg)

这里我们创建了新的 bridge 网络 `my_net2`，网段为 172.22.16.0/24，网关为 172.22.16.1。与前面一样，网关在 `my_net2` 对应的网桥 `br-5d863e9f78b6` 上：

![docker网络-15.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kjh4efzzj30py094my8.jpg)

容器要使用新的网络，需要在启动时通过 `--network` 指定：

![docker网络-16.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kjmmdz6fj30uw0g4jtc.jpg)

容器分配到的 IP 为 172.22.16.2。

到目前为止，容器的 IP 都是 docker 自动从 subnet 中分配，我们能否指定一个静态 IP 呢？

可以通过`--ip`指定

![docker网络-17.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kjplpl9tj30ug0g2ac0.jpg)

注：**只有使用 --subnet 创建的网络才能指定静态 IP**。

`my_net` 创建时没有指定 `--subnet`，如果指定静态 IP 报错如下：

![docker网络-18.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kjqdoejbj313s04udgb.jpg)

好了，我们来看看当前 docker host 的网络拓扑结构。

![docker网络-19.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9kjts8bcuj30k00puwfk.jpg)

### 五. 容器之间的连通性

![docker网络-20.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9lkjskh32j30k00puwfk.jpg)

当前 docker host 的网络拓扑结构如上图所示

两个 busybox 容器都挂在 my_net2 上，应该能够互通，我们验证一下：

![docker网络-21.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9mycbe86pj30pw0t8tc7.jpg)

可见同一网络中的容器、网关之间都是可以通信的。`my_net2` 与默认 bridge 网络能通信吗？

从拓扑图可知，两个网络属于不同的网桥，应该不能通信，我们通过实验验证一下，让 busybox 容器 ping httpd 容器：

![docker网络-22.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9myedk1xlj30ne06k750.jpg)

确实 ping 不通，符合预期。那么接下来的问题是：怎样才能让 busybox 与 httpd 通信呢？

答案是：为 httpd 容器添加一块 net_my2 的网卡。这个可以通过`docker network connect` 命令实现。

![docker网络-23.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9myg2xpx2j30tq08igmg.jpg)

我们在 httpd 容器中查看一下网络配置：

![docker网络-24.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9myhll7sqj31120iw41h.jpg)

容器中增加了一个网卡 eth1，分配了 my_net2 的 IP 172.22.16.3。现在 busybox 应该能够访问 httpd 了，验证一下：

![docker网络-25.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9myiowdcpj30me0gsmyp.jpg)

busybox 能够 ping 到 httpd，并且可以访问 httpd 的 web 服务。当前网络结构如图所示：

![docker网络-26.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9myjlkpllj30k00psq3x.jpg)

### 六. 容器间通信的三种方式

容器之间可通过 **IP，Docker DNS Server 或 joined **容器三种方式通信。

#### **IP 通信**

从上面的例子可以得出这样一个结论：两个容器要能通信，必须要有属于同一个网络的网卡

满足这个条件后，容器就可以通过 IP 交互了。具体做法是在容器创建时通过 `--network` 指定相应的网络，或者通过 `docker network connect` 将现有容器加入到指定网络。

#### **Docker DNS Server**

通过 IP 访问容器虽然满足了通信的需求，但还是不够灵活。因为我们在部署应用之前可能无法确定 IP，部署之后再指定要访问的 IP 会比较麻烦。对于这个问题，可以通过 docker 自带的 DNS 服务解决。

从 Docker 1.10 版本开始，docker daemon 实现了一个内嵌的 DNS server，使容器可以直接通过“容器名”通信。方法很简单，只要在启动时用 `--name` 为容器命名就可以了。

下面启动两个容器 bbox1 和 bbox2：

```bash
docker run -it --network=my_net2 --name=bbox1 busybox
docker run -it --network=my_net2 --name=bbox2 busybox
```

然后，bbox2 就可以直接 ping 到 bbox1 了：

![docker网络-27.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9mysigf53j30qw07o0ti.jpg)

使用 docker DNS 有个限制：**只能在 user-defined 网络中使用**。也就是说，默认的 bridge 网络是无法使用 DNS 的。下面验证一下：

创建 bbox3 和 bbox4，均连接到 bridge 网络。

```bash
docker run -it --name=bbox3 busybox
docker run -it --name=bbox4 busybox
```

bbox4 无法 ping 到 bbox3。

![docker网络-28.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9mytwlkgij30js05mgmd.jpg)

#### **joined 容器**

joined 容器是另一种实现容器间通信的方式。

joined 容器非常特别，它可以使两个或多个容器共享一个网络栈，共享网卡和配置信息，joined 容器之间可以通过 127.0.0.1 直接通信。请看下面的例子：

先创建一个 httpd 容器，名字为 web1。

```bash
docker run -d -it --name=web1 httpd
```

然后创建 busybox 容器并通过 `--network=container:web1` 指定 jointed 容器为 web1：

![docker网络-29.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9myvdm69zj30uk0fywgf.jpg)

请注意 busybox 容器中的网络配置信息，下面我们查看一下 web1 的网络：

![docker网络-30.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9mz2we0b7j310q0g8di6.jpg)

busybox 和 web1 的网卡 mac 地址与 IP 完全一样，它们共享了相同的网络栈。busybox 可以直接用 127.0.0.1 访问 web1 的 http 服务。

![docker网络-31.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9mz524cvlj30om07kgly.jpg)

joined 容器非常适合以下场景：

1. 不同容器中的程序希望通过 loopback 高效快速地通信，比如 web server 与 app server。
2. 希望监控其他容器的网络流量，比如运行在独立容器中的网络监控程序。

### 七. 容器与外部通信

前面我们已经解决了容器间通信的问题，接下来讨论容器如何与外部世界通信。这里涉及两个方向：

1. 容器访问外部世界
2. 外部世界访问容器

#### **容器访问外部世界**

在我们当前的实验环境下，docker host 是可以访问外网的。

![docker网络-32.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9mzfa0s30j30pq05sq3n.jpg)

我们看一下容器是否也能访问外网

![docker网络-33.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9mzg5o966j30mu07o750.jpg)

可见，**容器默认就能访问外网**。

请注意：这里外网指的是容器网络以外的网络环境，并非特指 internet。现象很简单，但更重要的：我们应该理解现象下的本质。

在上面的例子中，busybox 位于 `docker0` 这个私有 bridge 网络中（172.17.0.0/16），当 busybox 从容器向外 ping 时，数据包是怎样到达 bing.com 的呢？

这里的关键就是 NAT。我们查看一下 docker host 上的 iptables 规则：

![docker网络-34.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9mzj3yfkcj30u60g0tav.jpg)

`-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE`

其含义是：如果网桥 `docker0` 收到来自 172.17.0.0/16 网段的外出包，把它交给 MASQUERADE 处理。而 MASQUERADE 的处理方式是将包的源地址替换成 host 的地址发送出去，**即做了一次网络地址转换（NAT）**。

下面我们通过 tcpdump 查看地址是如何转换的。先查看 docker host 的路由表：

![docker网络-35.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n05ao8chj30qq04sdg8.jpg)

默认路由通过 enp0s3 发出去，所以我们要同时监控 enp0s3 和 docker0 上的 icmp（ping）数据包。

当 busybox ping bing.com 时，tcpdump 输出如下：

![docker网络-36.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n062imoyj310009g0uv.jpg)

docker0 收到 busybox 的 ping 包，源地址为容器 IP 172.17.0.2，这没问题，交给 MASQUERADE 处理。这时，在 enp0s3 上我们看到了变化：

![docker网络-37.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n06zoom5j30zg09aac5.jpg)

**ping 包的源地址变成了 enp0s3 的 IP 10.0.2.15**

这就是 iptable NAT 规则处理的结果，从而保证数据包能够到达外网。下面用一张图来说明这个过程：

![docker网络-38.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n07o7srvj31gq0pkdhb.jpg)

1. busybox 发送 ping 包：172.17.0.2 > `www.bing.com`。
2. docker0 收到包，发现是发送到外网的，交给 NAT 处理。
3. NAT 将源地址换成 enp0s3 的 IP：10.0.2.15 >` www.bing.com`。
4. ping 包从 enp0s3 发送出去，到达` www.bing.com`

通过 NAT，docker 实现了容器对外网的访问。

### 八. 外部世界访问通信

外部网络如何访问到容器？答案是：**端口映射**

docker 可将容器对外提供服务的端口映射到 host 的某个端口，外网通过该端口访问容器。容器启动时通过`-p`参数映射端口：

![docker网络-39.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n11tth0fj31bu0acq47.jpg)

容器启动后，可通过 `docker ps` 或者 `docker port` 查看到 host 映射的端口。在上面的例子中，httpd 容器的 80 端口被映射到 host 32773 上，这样就可以通过 `<host ip>:<32773>` 访问容器的 web 服务了。

![docker网络-40.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n12jo5ocj30hm03o74p.jpg)

除了映射动态端口，也可在 `-p` 中指定映射到 host 某个特定端口，例如可将 80 端口映射到 host 的 8080 端口：

![docker网络-41.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n13s725bj30oy06kwf3.jpg)

每一个映射的端口，host 都会启动一个 `docker-proxy` 进程来处理访问容器的流量：

![docker网络-42.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n1615a2yj31pu05sq44.jpg)

以 0.0.0.0:32773->80/tcp 为例分析整个过程：

![docker网络-43.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g9n16jkqv8j31gq0pkgnr.jpg)

1. docker-proxy 监听 host 的 32773 端口。
2. 当 curl 访问 10.0.2.15:32773 时，docker-proxy 转发给容器 172.17.0.2:80。
3. httpd 容器响应请求并返回结果。