## 在linux上搭建sonarqube

### 一. 搭建sonarqube

下载sonarqube包，因为我用到了Mysql数据库，综合软硬件说明我选择了7.6版本的SonarQube进行下载安装。

- SonarQube 支持的数据库有：[PostgreSQL](http://www.postgresql.org/)，[Microsoft SQL Server](http://www.microsoft.com/sqlserver/)，[Oracle](http://www.oracle.com/database/)，注意7.9版本已经不对MySql进行官方的支持了，如果执意要用 Mysql 可能会遇到很多坑（我就被坑的不轻）。当然有的朋友想用Mysql数据库，那么可以选择安装 7.7 以下版本（包括7.7）。
- SonarQube 运行需要ES（ElasticSearch），当然这个不用我们安装，下载的安装包已经包含了ES。

SonarQube 的安装包是不分平台的，默认把所有平台的运行命令都下载下来，使用者根据不同环境运行不同的运行脚本。

可以去官网下载，下载下来后解压

```bash
unzip sonarqube-7.6.zip
```

- bin目录存放了各个环境的启动脚本
- conf目录存放着sonarqube的配置文件
- logs目录存放着启动和运行时的日志文件



因为sonarqube依赖java，安装前可以先去看下对应版本所需要的支持

https://docs.sonarqube.org/7.6/requirements/requirements/

安装jdk1.8，具体步骤就不详细描述了。



创建sonarqube用户 启动

```bash
useradd sonarqube
passwd sonarqube

#赋予启动用户执行权限
chown -R sonarqube:sonarqube /usr/local/sonarqube-7.6

su - sonarqube  

./sonar.sh start
```



登录`http://192.168.179.128:9000/`  登录默认admin/admin

安装中文插件 然后restart(如无法下载，可以手动下载插件jar包安装到sonarqube目录下extensions/plugins)

![sonar-1.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1ga9vn6hr3oj312m0hrgnr.jpg)



使用mysql 创建数据库以及权限

```sql

CREATE DATABASE sonar CHARACTER SET utf8 COLLATE utf8_general_ci;

CREATE USER 'sonar' IDENTIFIED BY 'sonar';

GRANT ALL ON sonar.* TO 'sonar'@'%' IDENTIFIED BY 'sonar';

GRANT ALL ON sonar.* TO 'sonar'@'localhost' IDENTIFIED BY 'sonar';

FLUSH PRIVILEGES;
```

对Sonar进行Mysql的数据库配置。进入Sonar的Conf目录下，通过vim命令对sonar.properties进行配置

### 二. 使用sonarqube分析c#

分析netcore项目，微软和sonar一起协作做了很多工作，大大简化了我们的工具使用，官网可以查看相关工具及命令：https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-msbuild/

我们按照官方提示，找到 MSBuild .NET Core Global Tool ，直接安装dotnet全局工具

```bash
dotnet tool install --global dotnet-sonarscanner --version 4.3.1
```

安装完后，我们把我们的sonar的token注入到该命令的配置中，以便在执行命令时自动关联到对应账户的sonar。

在dotnet tool的安装目录下，找到一个叫 SonarQube.Analysis.xml 的配置文件。

我的xml在该目录下

```
C:\Users\miao.dotnet\tools.store\dotnet-sonarscanner\4.3.1\dotnet-sonarscanner\4.3.1\tools\netcoreapp2.1\any
```

配置好web地址和token

![sonar-2.jpg](https://ws1.sinaimg.cn/large/0072fULUgy1ga9wia6m82j31320jkq4r.jpg)

首先随便找个项目，这个就不多说了。有了代码以后然后进入代码目录，依次输入下面命令：

开始命令，下面命令已经备注了三个参数的用途

```bash
dotnet sonarscanner begin /k:这里填SonarQube将要生成的项目的唯一编码 /n:sonarqube中将要显示的项目名称 /v:当前执行活动号（可以动态递增或使用时间戳）
```

编译命令，build 后面的参数为 dotnet core 项目的 xxx.sln 文件的完整路径

```
dotnet build xxx.csproj
```

分析并将分析结果推送到sonarqube站点

```
dotnet sonarscanner end 
```

ex:

```
dotnet sonarscanner begin /k:efos.wts /n:efos.wts /v:11

dotnet build WisdomToiletScreen.sln

dotnet sonarscanner end 
```


参考链接：http://www.imooc.com/article/290854

```bash
#测试简单部署
# 下载
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-7.9.1.zip
# 解压
/opt/sonarqube/
unzip /opt/sonarqube/bin/[OS]/sonar.sh console
# 登录宿主机http://localhost:9000 （admin/admin）


#生产环境
# 宿主机requirementes
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 4096

cat >> /etc/sysctl.conf  << EOF
vm.max_map_count=262144
fs.file-max=65536
EOF


# sonarqube不能用root用户执行
useradd sonarqube
echo "sonarqubepwd" | passwd --stdin sonarqube

# 检查系统
[root@devops-sonarqube ~]# grep SECCOMP /boot/config-$(uname -r)
CONFIG_HAVE_ARCH_SECCOMP_FILTER=y
CONFIG_SECCOMP_FILTER=y
CONFIG_SECCOMP=y

cat > /etc/security/limits.d/99-sonarqube.conf <<EOF
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOF

# sonarqube es需要安装安装jdk11
yum -y install java-11-openjdk.x86_64


# 7.9最新版本不支持mysql，数据库支持MSSQL/Oracle/PostgreSQL
# 安装PostgreSQL
# 创建sonarqube用户，授权用户create, update, and delete权限
# 如果想自定义数据库名称，不用pulic，则需要搜索路径修改
yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
yum install -y postgresql96-server postgresql96-contrib
/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl start postgresql-9.6
systemctl enable postgresql-9.6
su - postgres
psql
create user sonarqube with password 'sonarqube';
create database sonarqube owner sonarqube;
grant all  on database sonarqube to sonarqube;
\q 

# 查看postgresql监听
vi /var/lib/pgsql/9.6/data/postgresql.conf

# 配置白名单
vi /var/lib/pgsql/9.6/data/pg_hba.conf
host    all              all             127.0.0.1/32           md5
#重启服务
systemctl restart postgresql-9.6

ss -tan | grep 5432
# 创建库/用户，并授权
psql -h 127.0.0.1 -p 5432  -U postgres


# 下载软件包
cd /opt && wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-7.9.1.zip
ln -sv sonarqube-7.9.1 sonarqube
chown sonarqube.sonarqube sonarqube/* -R

# 切换到系统sonarqube用户开始安装
su - sonarqube

# 设置数据库访问，编辑$SONARQUBE-HOME/conf/sonar.properties
sonar.jdbc.username=sonarqube
sonar.jdbc.password=sonarqube
# 注意为127.0.0.1
sonar.jdbc.url=jdbc:postgresql://127.0.0.1/sonarqube

# 配置ES存储路径，编辑SONARQUBE-HOME/conf/sonar.properties 
sonar.path.data=/var/sonarqube/data
sonar.path.temp=/var/sonarqube/temp

# 配置web server，编辑SONARQUBE-HOME/conf/sonar.properties
sonar.web.host=192.0.0.1
sonar.web.port=80
sonar.web.context=/sonarqube

# web服务器性能调优
$SONARQUBE-HOME/conf/sonar.properties
sonar.web.javaOpts=-server


$SONARQUBE-HOME/conf/wrapper.conf 
wrapper.java.command=/path/to/my/jdk/bin/java


# 执行启动脚本
Start:
$SONAR_HOME/bin/linux-x86-64/sonar.sh start

Graceful shutdown:
$SONAR_HOME/bin/linux-x86-64/sonar.sh stop

Hard stop:
$SONAR_HOME/bin/linux-x86-64/sonar.sh force-stop

# 插件安装
1.Marketplace方式安装（Administration > Marketplace）
2.手动安装（将下载好的插件上传至服务器目录：$SONARQUBE_HOME/extensions/plugins，重启sonarqube服务）
```

