## 搭建nuget私有服务器

### 一. 使用docker搭建nuget私有服务器

使用现有的镜像直接运行容器，非常简单，记住NUGET_API_KEY，后面会用到。

```bash
docker run -d  -p 8085:80 -v /home/nuget/db:/var/www/db -v /home/nuget/packages:/var/www/packagefiles -e NUGET_API_KEY=ee28314c-f7fe-2550-bd77-e09eda3d0119  sunside/simple-nuget-server
```


![使用docker搭建服务器.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w8gce3lsj312r01o747.jpg)      这里将容器的80端口映射到了host的8085端口，所以访问host的8085端口。

![搭建成功.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w8i327lej30x2088wet.jpg)

### 二. 将应用打包成nuget包并上传

* 1.在vs中

![生成nuget包.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w8ptet30j31040fimxq.jpg)



设置完成后rebuild,在此目录下会生成nuget包

* 2.在命令行打包

  ```bash
  dotnet pack -p:PackageVersion=1.0.0
  ```

![生成nuget包1.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w8qj3b96j30ol06uaa5.jpg)

然后在这个目录打开powerhell,使用命令将nuget包推送到私有服务器，这里会使用到搭建nuget服务器时填写的NUGET_API_KEY，因为之前已经推送过1.0.0版本的包，所以这里重新生成了一个1.0.1版本的包推送上去，后续可以看到包的版本


```bash
dotnet nuget push *.nupkg -k ee28314c-f7fe-2550-bd77-e09eda3d0119 -s http://192.168.1.36:8085
```

![推送成功.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w8zqaz8xj30r30b70sr.jpg)

### 三. 使用外部包源

在vs选项中搜索nuget，然后添加外部源

![vs中配置外部包源.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w93i2kjjj30l20dqjru.jpg)

 然后打开包管理器，选择外部源

![vs中使用nuget.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w9aby5j7j312f0iqgn6.jpg)

然后选中需要的包install就行了

![vs中导入nuget包.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w9chn0yxj30yv0dedgr.jpg)





### 四. 在linux上使用外部包源

在vs中我们可以通过选项去配置外部包源，但是现在要在linux中进行编译代码，这样代码势必会找不要外部包源，这里我将代码传到linux上，执行命令`dotnet-restore`

![编译找不到包源2.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w9hleaudj312z031wej.jpg)

这里会提示我们那三个包找不到，这里有两种解决办法

* #### 1.添加nuget.config文件

```
<?xml version="1.0" encoding="utf-8"?>

<configuration>

  <packageSources>

    <add key="AspNetCore" value="https://dotnet.myget.org/F/aspnetcore-ci-dev/api/v3/index.json" />

    <add key="AspNetCoreTools" value="https://dotnet.myget.org/F/aspnetcore-tools/api/v3/index.json" />

    <add key="NuGet" value="https://api.nuget.org/v3/index.json" />

    <!--这里添加自己的包地址-->

    <add key="MyNuGet" value="http://192.168.1.37:8085/" />

  </packageSources>

</configuration>
```

后面这个--configfile可加可不加，如果不加项目中有nuget.config会默认去找nuget.config

```bash
dotnet restore --configfile "nuget.config"
```

* #### 2.restore的时候加上所有源

```bash
dotnet restore -s "http://192.168.1.37:8085/" -s "https://dotnet.myget.org/F/aspnetcore-ci-dev/api/v3/index.json" -s "https://dotnet.myget.org/F/aspnetcore-tools/api/v3/index.json" -s "https://api.nuget.org/v3/index.json"
```

![restore加上所有包源.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w9wpdvouj312t079aau.jpg)

这种方式不需要多添加配置文件，但这个restore会特别慢，有时还会超时，但最后还是能跑起来

![这种方式耗时比较长.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8w9vrq5akj312t088mxt.jpg)



### 五.  其他

#### 1. 清除本地缓存

```bash
dotnet nuget locals all -c
```

#### 2. 删除包源

需要用到nuget.exe，安装nuget.exe之后，将nuget.exe所在的目录加到环境变量里面去

```bash
nuget delete Hyd.Commons 1.0.0 -Source http://192.168.1.37:8085/ -apikey ee28314c-f7fe-2550-bd77-e09eda3d0119
```

![删除包源.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8wdu6ee0wj30qv0470sp.jpg)



#### 3.遗留问题

尝试将应用打包成docker镜像，在构建镜像时去还原包，但是一直失败，不使用docker直接使用dotnet命令行是可以还原包的。看原因初步怀疑是因为在docker里面因为网络原因连接不到源（no route to host）

![编译找不到包源.png](https://wx1.sinaimg.cn/large/0072fULUgy1g8wdyg5g44j30y70i4di1.jpg)

Dockerfile:

```
FROM mcr.microsoft.com/dotnet/core/aspnet:3.0-buster-slim AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/core/sdk:3.0-buster AS build
WORKDIR /src
COPY ["testNuget.csproj", ""]
COPY ["nuget.config",""]
RUN dotnet restore "./testNuget.csproj" --configfile "nuget.config"
COPY . .
WORKDIR "/src/."
RUN dotnet build "testNuget.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "testNuget.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "testNuget.dll"]
```

#### 4. 更多参考

https://docs.microsoft.com/zh-cn/nuget/reference/nuget-exe-cli-reference

https://docs.microsoft.com/zh-cn/dotnet/core/tools/dotnet-pack