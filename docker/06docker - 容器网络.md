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

