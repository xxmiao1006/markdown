## docker构建镜像

对于大多数docker用户来说，最好的情况还是不需要自己创建镜像。几乎所有常用的数据库、中间件、应用软件等都有现成的Docker官方镜像或其他组织的人提供的镜像，我们只需要稍作配置就可以使用，这也是docker的一大优势，使用现成镜像的好处是除了可以省去自己做镜像的工作量之外、更重要的是可以利用前人的经验，也别是一些特别的官方镜像，docker工程师知道如何更好的在容器中运行软件。但也有比较特殊的是企业需要将自己的应用构建自己的镜像，这样镜像的构建就是不可避免的了。或者是需要在别人的镜像上加入特有的功能，这时候也需要我们自己去构建镜像。

Docker提供了两种构建镜像的方式

* docker commit 命令
* Dockerfile 构建文件

### 一. docker commit

docker commit 命令是创建新镜像最直观的方法，其过程包含三个步骤：

1. 运行容器 

2. 修改容器

3. 将容器保存为新的镜像

举个例子：在 ubuntu base 镜像中安装 vi 并保存为新镜像。

  1.运行容器,使用`-it`进入容器，并打开终端

```bash
docker run -it ubuntu
```

   2.安装 vi

```bash
apt-get install -y vim
```

   3.保存为新镜像，回到host中执行命令

```bash
docker commit container-name new-image-name
```

上面是commit方式构建镜像，但是Docker **并不建议用户通过这种方式构建镜像**，官方推荐使用Dockerfile构建镜像，但是Dockerfile（推荐方法）构建镜像，底层也是docker commit 一层一层构建新镜像的。学习 docker commit 能够帮助我们更加深入地理解构建过程和镜像的分层结构。

### 二. Dockerfile构建镜像

Dockerfile 是一个文本文件，记录了镜像构建的所有步骤。Dockerfile 一般分为四部分：基础镜像信息、维护者信息、镜像操作指令和容器启动时执行指令，’#’ 为 Dockerfile 中的注释。

docker build 基于dockerfile制作镜像的命令

```bash
docker build [OPTIONS] PATH | URL | -
```

- -t：打标签
-  -c，- cpu-shares int ：CPU份额（相对权重）
-  -m，- memory bytes：内存限制
-  --build-arg：设置构建时变量，就是构建的时候修改ARG指令的参数

用Dockerfile创建上面的ubuntu-with-vim，其内容为

![dockerfile-1.png](https://ws1.sinaimg.cn/large/0072fULUgy1g8xl7i1s9yj30m403f75h.jpg)

然后运行命令，这里注意 后面有一个`.`

```
docker build -t ubuntu-with-vi-dockerfile .
```

![dockerfile-2.png](https://ws1.sinaimg.cn/large/0072fULUgy1g8xl8vrv4pj30ju0gzmxr.jpg)

① 当前目录为 /root。

② Dockerfile 准备就绪。

③ 运行 docker build 命令，`-t` 将新镜像命名为 `ubuntu-with-vi-dockerfile`，命令末尾的 `.` 指明 build context 为当前目录。Docker 默认会从 build context 中查找 Dockerfile 文件，我们也可以通过 `-f` 参数指定 Dockerfile 的位置。

④ 从这步开始就是镜像真正的构建过程。 首先 Docker 将 build context 中的所有文件发送给 Docker daemon。build context 为镜像构建提供所需要的文件或目录。
Dockerfile 中的 ADD、COPY 等命令可以将 build context 中的文件添加到镜像。此例中，build context 为当前目录 `/root`，该目录下的所有文件和子目录都会被发送给 Docker daemon。

所以，使用 build context 就得小心了，不要将多余文件放到 build context，特别不要把 `/`、`/usr` 作为 build context，否则构建过程会相当缓慢甚至失败。

⑤ Step 1：执行 `FROM`，将 ubuntu 作为 base 镜像。
ubuntu 镜像 ID 为 f753707788c5。

⑥ Step 2：执行 `RUN`，安装 vim，具体步骤为 ⑦、⑧、⑨。

⑦ 启动 ID 为 9f4d4166f7e3 的临时容器，在容器中通过 apt-get 安装 vim。

⑧ 安装成功后，将容器保存为镜像，其 ID 为 35ca89798937。

**这一步底层使用的是类似 docker commit 的命令**。

⑨ 删除临时容器 9f4d4166f7e3。

⑩ 镜像构建成功。

通过命令`docker images`查看所有镜像

![dockerfile-3.png](https://ws1.sinaimg.cn/large/0072fULUgy1g8xlawjd2tj30nl02f3zy.jpg)

在上面的构建过程中，我们要特别注意指令 RUN 的执行过程 ⑦、⑧、⑨。Docker 会在启动的临时容器中执行操作，并通过 commit 保存为新的镜像。

### 三. 查看镜像的分层结构

ubuntu-with-vi-dockerfile 是通过在 base 镜像的顶部添加一个新的镜像层而得到的。

![dockerfile-4.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g8xlf5aeitj30n00fqdgk.jpg)

这个新镜像层的内容由 `RUN apt-get update && apt-get install -y vim` 生成。这一点我们可以通过 `docker history` 命令验证。

`docker history` 会显示镜像的构建历史，也就是 Dockerfile 的执行过程。

![dockerfile-5.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1g8xlg3wr9nj31220hu0w4.jpg)

ubuntu-with-vi-dockerfile 与 ubuntu 镜像相比，确实只是多了顶部的一层 35ca89798937，由 apt-get 命令创建，大小为 97.07MB。docker history 也向我们展示了镜像的分层结构，每一层由上至下排列。

总的来说，Dockerfile构建镜像就是这样一个过程

1. 从 base 镜像运行一个容器。
2. 执行一条指令，对容器做修改。
3. 执行类似 docker commit 的操作，生成一个新的镜像层。
4. Docker 再基于刚刚提交的镜像运行一个新容器。
5. 重复 2-4 步，直到 Dockerfile 中的所有指令执行完毕。

### 四. 镜像的缓存特性

Docker 会缓存已有镜像的镜像层，构建新镜像时，如果某镜像层已经存在，就直接使用，无需重新创建。

如果我们希望在构建镜像时不使用缓存，可以在 `docker build` 命令中加上 `--no-cache` 参数

除了构建时使用缓存，Docker 在下载镜像时也会使用。例如我们下载 httpd 镜像

![dockerfile-6.png](https://ws1.sinaimg.cn/large/0072fULUgy1g8xlqdc8emj30v409gt9r.jpg)

docker pull 命令输出显示第一层（base 镜像）已经存在，不需要下载

### 五. Dockerfile常用指令

**FROM**
		指定 base 镜像。

**MAINTAINER**
		设置镜像的作者，可以是任意字符串

**COPY**
		将文件从 build context 复制到镜像。
		COPY 支持两种形式：

1. COPY src dest
2. COPY ["src", "dest"]

注意：src 只能指定 build context 中的文件或目录。

**ADD**
		与 COPY 类似，从 build context 复制文件到镜像。不同的是，如果 src 是归档文件（tar, zip, tgz, xz 等），		文件会被自动解压到 dest。

**ENV**
		设置环境变量，环境变量可被后面的指令使用。例如：

```
ENV MY_VERSION 1.3

RUN apt-get install -y mypackage=$MY_VERSION
```

**EXPOSE**
		指定容器中的进程会监听某个端口，Docker 可以将该端口暴露出来。我们会在容器网络部分详细讨论。

**VOLUME**
		将文件或目录声明为 volume。我们会在容器存储部分详细讨论

**WORKDIR**
		为后面的 RUN, CMD, ENTRYPOINT, ADD 或 COPY 指令设置镜像中的当前工作目录。

**RUN**
		在容器中运行指定的命令。

**CMD**
		容器启动时运行指定的命令。
		Dockerfile 中可以有多个 CMD 指令，但只有最后一个生效。CMD 可以被 docker run 之后的参数替换

**ENTRYPOINT**
		设置容器启动时运行的命令。
		Dockerfile 中可以有多个 ENTRYPOINT 指令，但只有最后一个生效。CMD 或 docker run 之后的参数会被当		做参数传递给 ENTRYPOINT。

参考博客

参考博客 [dockerfile详解](https://www.cnblogs.com/along21/p/10243761.html)

