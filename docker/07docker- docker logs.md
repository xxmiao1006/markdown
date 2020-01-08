## docker logs

### 一 . docker logs

我们首先来看一看默认配置下 Docker 的日志功能。

对于一个运行的容器，Docker 会将日志发送到 **容器的** 标准输出设备（STDOUT）和标准错误设备（STDERR），STDOUT 和 STDERR 实际上就是容器的控制台终端。

举个例子，用下面的命令运行 httpd 容器

`docker run -p 80:80 httpd`

![dockerlogs-1.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9dv0tu6o0j31ua066mz3.jpg)

因为我们在启动日志的时候没有用 `-d` 参数，httpd 容器以前台方式启动，日志会直接打印在当前的终端窗口。

如果加上 `-d` 参数以后台方式运行容器，我们就看不到输出的日志了。

![dockerlogs-2.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9dv1iywcbj30ps03o3yr.jpg)

这种情况下如果要查看容器的日志，有两种方法：

1. attach 到该容器。
2. 用 `docker logs` 命令查看日志。

先来看 attach 的方法。运行 `docker attach` 命令。

![dockerlogs-3.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9dv2o3ol6j30gw042aa9.jpg)

attach 到了 httpd 容器，但并没有任何输出，这是因为当前没有新的日志信息。

为了产生一条新的日志，可以在 host 的另一个命令行终端执行 `curl localhost`

![dockerlogs-4.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9dv46avy3j30hs03sq3b.jpg)

这时，attach 的终端就会打印出新的日志。

![dockerlogs-5.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9dvcv5xo7j30qe0643z0.jpg)

attach 的方法在实际使用中不太方便，因为：

1. 只能看到 attach 之后的日志，以前的日志不可见。
2. 退出 attach 状态比较麻烦（Ctrl+p 然后 Ctrl+q 组合键），一不小心很容易将容器杀掉（比如按下 Ctrl+C）。

查看容器日志推荐的方法是用 `docker logs` 命令。

`docker logs` 能够打印出自容器启动以来完整的日志，并且 `-f` 参数可以继续打印出新产生的日志，效果上与 Linux 命令 `tail -f` 一样。

![dockerlogs-6.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9dvebznucj31uc06mac6.jpg)

### 二 . docker多日志方案

将容器日志发送到 STDOUT 和 STDERR是 Docker 的默认日志行为。实际上，Docker 提供了多种日志机制帮助用户从运行的容器中提取日志信息。这些机制被称作 logging driver。

Docker 的默认 logging driver 是 `json-file`。

`docker info |grep 'Logging Driver'`

` Logging Driver: json-file`

如果容器在启动时没有特别指明，就会使用这个默认的 logging driver。

`json-file` 会将容器的日志保存在 json 文件中，Docker 负责格式化其内容并输出到 STDOUT 和 STDERR。

我们可以在 Host 的容器目录中找到这个文件，器路径为 `/var/lib/docker/containers/<contariner ID>/<contariner ID>-json.log`

比如我们可以查看前面 httpd 容器 json 格式的日志文件。

![dockerlogs-7.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9i7auynyij313m0fyae1.jpg)

除了 `json-file`，Docker 还支持多种 logging driver。完整列表可访问官方文档 https://docs.docker.com/config/containers/logging/configure/

![dockerlogs-8.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1g9i7eun20oj30lc0h93zw.jpg)

`none` 是 disable 容器日志功能。

`syslog` 和 `journald` 是 Linux 上的两种日志管理服务。

`awslogs`、`splunk` 和 `gcplogs` 是第三方日志托管服务。

`gelf` 和 `fluentd` 是两种开源的日志管理方案，我们会在后面分别讨论。

容器启动时可以通过 `--log-driver` 指定使用的 logging driver。如果要设置 Docker 默认的 logging driver，需要修改 Docker daemon 的启动脚本，指定 `--log-driver` 参数，比如：

```bash
ExecStart=/usr/bin/dockerd -H fd:// --log-driver=syslog --log-opt ......
```

每种 logging driver 都有自己的 `--log-opt`，使用时请参考官方文档。

