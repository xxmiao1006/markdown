## docker的两类存储资源                                                                                                                                       

Docker 为容器提供了两种存放数据的资源：

1. 由 storage driver 管理的镜像层和容器层。
2. Data Volume。

### 一. storage driver

在前面镜像章节我们学习到 Docker 镜像的分层结构

![dockersave-1.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8ygtk4um7j30ir0d1aam.jpg)

容器由最上面一个可写的容器层，以及若干只读的镜像层组成，容器的数据就存放在这些层中。这样的分层结构最大的特性是 Copy-on-Write：

1. 新数据会直接存放在最上面的容器层。
2. 修改现有数据会先从镜像层将数据复制到容器层，修改后的数据直接保存在容器层中，镜像层保持不变。
3. 如果多个层中有命名相同的文件，用户只能看到最上面那层中的文件。

分层结构使镜像和容器的创建、共享以及分发变得非常高效，而这些都要归功于 Docker storage driver。正是 storage driver 实现了多层数据的堆叠并为用户提供一个单一的合并之后的统一视图。

Docker 支持多种 storage driver，有 AUFS、Device Mapper、Btrfs、OverlayFS、VFS 和 ZFS。它们都能实现分层的架构，同时又有各自的特性。对于 Docker 用户来说，具体选择使用哪个 storage driver 是一个难题，因为：

1. 没有哪个 driver 能够适应所有的场景。
2. driver 本身在快速发展和迭代。

**优先使用 Linux 发行版默认的 storage driver**。

Docker 安装时会根据当前系统的配置选择默认的 driver。默认 driver 具有最好的稳定性，因为默认 driver 在发行版上经过了严格的测试。

可以使用命令`docker info`来查看系统默认的driver

对于某些容器，直接将数据放在由 storage driver 维护的层中是很好的选择，比如那些无状态的应用。无状态意味着容器没有需要持久化的数据，随时可以从镜像直接创建。

比如 busybox，它是一个工具箱，我们启动 busybox 是为了执行诸如 wget，ping 之类的命令，不需要保存数据供以后使用，使用完直接退出，容器删除时存放在容器层中的工作数据也一起被删除，这没问题，下次再启动新容器即可。

但对于另一类应用这种方式就不合适了，它们有持久化数据的需求，容器启动时需要加载已有的数据，容器销毁时希望保留产生的新数据，也就是说，这类容器是有状态的。

### 二. data volume

Data Volume 本质上是 Docker Host 文件系统中的目录或文件，能够直接被 mount 到容器的文件系统中。Data Volume 有以下特点：

1. Data Volume 是目录或文件，而非没有格式化的磁盘（块设备）。
2. 容器可以读写 volume 中的数据。
3. volume 数据可以被永久的保存，即使使用它的容器已经销毁。

volume 实际上是 docker host 文件系统的一部分，所以 volume 的容量取决于文件系统当前未使用的空间，目前还没有方法设置 volume 的容量。

在具体的使用上，docker 提供了两种类型的 volume：bind mount 和 docker managed volume。

### 1. bind mount

bind mount 是将 host 上已存在的目录或文件 mount 到容器。

例如 docker host 上有目录 $HOME/htdocs：

![dockersave-2.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8yi3s1excj30s803w3z0.jpg)

通过 `-v` 将其 mount 到 httpd 容器：

![dockersave-3.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yi4hyk0gj30vq03sdg9.jpg)

`-v` 的格式为 `<host path>:<container path>`。/usr/local/apache2/htdocs 就是 apache server 存放静态文件的地方。由于 /usr/local/apache2/htdocs 已经存在，原有数据会被隐藏起来，取而代之的是 host $HOME/htdocs/ 中的数据，这与 linux `mount` 命令的行为是一致的。

![dockersave-4.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8yi7lvf48j30rs03q74r.jpg)

curl 显示当前主页确实是 $HOME/htdocs/index.html 中的内容。

下面我们将容器销毁，看看对 bind mount 有什么影响：

![dockersave-5.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yibbv3tdj30fq07kwev.jpg)

可见，即使容器没有了，bind mount 也还在。

另外，bind mount 时还可以指定数据的读写权限，默认是可读可写，可指定为只读：

![dockersave-6.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yigwzov8j30xm08iabd.jpg)

使用 bind mount 单个文件的场景是：只需要向容器添加文件，不希望覆盖整个目录。在上面的例子中，我们将 html 文件加到 apache 中，同时也保留了容器原有的数据

使用单一文件有一点要注意：host 中的源文件必须要存在，不然会当作一个新目录 bind mount 给容器。

mount point 有很多应用场景，比如我们可以将源代码目录 mount 到容器中，在 host 中修改代码就能看到应用的实时效果。再比如将 mysql 容器的数据放在 bind mount 里，这样 host 可以方便地备份和迁移数据

bind mount 的使用直观高效，易于理解，但它也有不足的地方：bind mount 需要指定 host 文件系统的特定路径，这就限制了容器的可移植性，当需要将容器迁移到其他 host，而该 host 没有要 mount 的数据或者数据不在相同的路径时，操作会失败。

移植性更好的方式是 docker managed volume

### 2. docker managed volume

docker managed volume 与 [bind mount在使用上的最大区别是不需要指定 mount 源，指明 mount point 就行了。还是以 httpd 容器为例

![dockersave-7.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yippc368j30se03qmxu.jpg)

我们通过 `-v` 告诉 docker 需要一个 data volume，并将其 mount 到 /usr/local/apache2/htdocs。那么这个 data volume 具体在哪儿呢？

这个答案可以在容器的配置信息中找到，执行 `docker inspect` 命令：`docker inspect 21accc2ca072`

```bash
"Mounts": [
    {
        "Name": "f4a0a1018968f47960efe760829e3c5738c702533d29911b01df9f18babf3340",
        "Source": "/var/lib/docker/volumes/f4a0a1018968f47960efe760829e3c5738c702533d29911b01df9f18babf3340/_data",
        "Destination": "/usr/local/apache2/htdocs",
        "Driver": "local",
        "Mode": "",
        "RW": true,
        "Propagation": ""
    }
```

`docker inspect` 的输出很多，我们感兴趣的是 `Mounts` 这部分，这里会显示容器当前使用的所有 data volume，包括 bind mount 和 docker managed volume。

`Source` 就是该 volume 在 host 上的目录。

每当容器申请 mount docker manged volume 时，docker 都会在`/var/lib/docker/volumes` 下生成一个目录（例子中是 "/var/lib/docker/volumes/f4a0a1018968f47960efe760829e3c5738c702533d29911b01df9f18babf3340/_data ），这个目录就是 mount 源

volume 的内容跟容器原有 /usr/local/apache2/htdocs 完全一样，这是怎么回事呢？

这是因为：如果 mount point 指向的是已有目录，原有数据会被复制到 volume 中。

但要明确一点：此时的 /usr/local/apache2/htdocs 已经不再是由 storage driver 管理的层数据了，它已经是一个 data volume。我们可以像 bind mount 一样对数据进行操作，例如更新数据：

![dockersave-8.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yj5z1xt8j313u06kwf5.jpg)

回顾一下 docker managed volume 的创建过程：

1. 容器启动时，简单的告诉 docker "我需要一个 volume 存放数据，帮我 mount 到目录 /abc"。
2. docker 在 /var/lib/docker/volumes 中生成一个随机目录作为 mount 源。
3. 如果 /abc 已经存在，则将数据复制到 mount 源，
4. 将 volume mount 到 /abc

除了通过 `docker inspect` 查看 volume，我们也可以用 `docker volume` 命令：

![dockersave-9.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yj6vnp6yj313q0fugnc.jpg)

目前，`docker volume` 只能查看 docker managed volume，还看不到 bind mount；同时也无法知道 volume 对应的容器，这些信息还得靠`docker inspect`。

我们已经学习了两种 data volume 的原理和基本使用方法，下面做个对比：

1. 相同点：两者都是 host 文件系统中的某个路径。

2. 不同点：

|                        |          bind mount          |    docker managed volume     |
| :--------------------: | :--------------------------: | :--------------------------: |
|      volume 位置       |          可任意指定          | /var/lib/docker/volumes/...  |
| 对已有mount point 影响 |     隐藏并替换为 volume      |    原有数据复制到 volume     |
|    是否支持单个文件    |             支持             |      不支持，只能是目录      |
|        权限控制        | 可设置为只读，默认为读写权限 |     无控制，均为读写权限     |
|         移植性         | 移植性弱，与 host path 绑定  | 移植性强，无需指定 host 目录 |

### 三. 共享数据

之前学习过两种docker的存储资源，想要多个容器共享一个资源，最简单的一种方法就是多个文件mount host的一个文件，这里就不多赘述。

![dockersave-10.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yjvg9x4gj30zi09kwg3.jpg)

#### 用 volume container 共享数据

volume container 是专门为其他容器提供 volume 的容器。它提供的卷可以是 bind mount，也可以是 docker managed volume。下面我们创建一个 volume container：

![dockersave-11.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yo921aigj30pc06mmxo.jpg)

我们将容器命名为 `vc_data`（vc 是 volume container 的缩写）。注意这里执行的是 `docker create` 命令，这是因为 volume container 的作用只是提供数据，它本身不需要处于运行状态。容器 mount 了两个 volume

1. bind mount，存放 web server 的静态文件。
2. docker managed volume，存放一些实用工具（当然现在是空的，这里只是做个示例）。

通过 `docker inspect vc_data`可以查看到这两个 volume。

```bash
"Mounts": [
    {
        "Source": "/root/htdocs",
        "Destination": "/usr/local/apache2/htdocs",
        "Mode": "",
        "RW": true,
        "Propagation": "rprivate"
    },
    {
        "Name": "1b603669398d117e499449862636a56c4f4c804d447c680e7b3ba7c7f5e52205",
        "Source": "/var/lib/docker/volumes/1b603669398d117e499449862636a56c4f4c804d447c680e7b3ba7c7f5e52205/_data",
        "Destination": "/other/useful/tools",
        "Driver": "local",
        "Mode": "",
        "RW": true,
        "Propagation": ""
    }
],
```

其他容器可以通过 `--volumes-from` 使用 `vc_data` 这个 volume container：

![dockersave-12jpg.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yobghc6kj30ua09c75s.jpg)

三个 httpd 容器都使用了 vc_data，看看它们现在都有哪些 volume，以 web1 为例：

```bash
docker inspect web1
"Mounts": [
    {
        "Source": "/root/htdocs",
        "Destination": "/usr/local/apache2/htdocs",
        "Mode": "",
        "RW": true,
        "Propagation": "rprivate"
    },
    {
        "Name": "1b603669398d117e499449862636a56c4f4c804d447c680e7b3ba7c7f5e52205",
        "Source": "/var/lib/docker/volumes/1b603669398d117e499449862636a56c4f4c804d447c680e7b3ba7c7f5e52205/_data",
        "Destination": "/other/useful/tools",
        "Driver": "local",
        "Mode": "",
        "RW": true,
        "Propagation": ""
    }
],
```

web1 容器使用的就是 vc_data 的 volume，而且连 mount point 都是一样的。验证一下数据共享的效果：

![dockersave-13.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g8yodhpjlbj31fa0eywgq.jpg)

可见，三个容器已经成功共享了 volume container 中的 volume。

下面我们讨论一下 volume container 的特点：

1. 与 bind mount 相比，不必为每一个容器指定 host path，所有 path 都在 volume container 中定义好了，容器只需与 volume container 关联，**实现了容器与 host 的解耦**。
2. 使用 volume container 的容器其 mount point 是一致的，有利于配置的规范和标准化，但也带来一定的局限，使用时需要综合考虑。

