## 在linux上搭建sonarqube

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

