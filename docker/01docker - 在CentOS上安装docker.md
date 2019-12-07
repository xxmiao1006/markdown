### 在CentOS上安装docker

doceker支持以下的CentOS版本

* CentOS 7(64bit)
* CentOS 6.5(64bit)或更高的版本 

#### 前提条件
目前，CentOS 仅发行版本中的内核支持 Docker。
Docker 运行在 CentOS 7 上，要求系统为64位、系统内核版本为 3.10 以上。
Docker 运行在 CentOS-6.5 或更高的版本的 CentOS 上，要求系统为64位、系统内核版本为 2.6.32-431 或者更高版本。

#### 使用yum安装
Docker 要求 CentOS 系统的内核版本高于 3.10 ，查看本页面的前提条件来验证你的CentOS 版本是否支持 Docker 。
通过` uname -r `命令查看你当前的内核版本

``` bash
[root@miao ~]# uname -r
```

##### 安装Docker

从 2017 年 3 月开始 docker 在原来的基础上分为两个分支版本: Docker CE 和 Docker EE。
Docker CE 即社区免费版，Docker EE 即企业版，强调安全，但需付费使用。

* 移除旧版本

```bash
$ sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine
```

* 安装一些必要的系统工具

```bash
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

* 添加软件源信息

```bash
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

* 更新yum缓存

```bash
sudo yum makecache fast
```

* 安装Docker-ce

```bash
sudo yum -y install docker-ce
```

* 启动Docker后台服务

```bash
sudo systemctl start docker
```

* hellow-word

```bash
docker run hello-world
```

##### 安装镜像加速

对于使用 [systemd](https://www.freedesktop.org/wiki/Software/systemd/) 的系统，请在 `/etc/docker/daemon.json` 中写入如下内容（如果文件不存在请新建该文件）

```json
{
  "registry-mirrors": [
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com"
  ]
}
```

之后重新启动服务。

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

输入`docker info`，可以看到如下，说明配置成功

```bash
 Registry Mirrors:
  https://registry.deoker-cn.com/
```

在生产系统中，应该使用特定版本的Docker CE，而不是始终使用最新版本。可以通过sort -r命令按版本号对结果进行排序

```bash
yum list docker-ce  --showduplicates | sort -r  #
```

