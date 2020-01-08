## Skywalking接入.net core客户端

Skywalking服务端的搭建前一篇已经介绍过了，本篇我们将在.net core客户端接入探针，监控.net core应用。

### 一. 引入nuget包

自己新建一个webAPI项目或者拿以前的项目都行。在包管理器里面搜索nuget包：SkyAPM.Agent.AspNetCore，本次使用的是0.8.0版本

![skyapm .net core nuget包.png](https://wx1.sinaimg.cn/large/0072fULUgy1g7v7buc8tcj312d0budh7.jpg)

### 二. 添加环境变量

添加环境变量ASPNETCORE_HOSTINGSTARTUPASSEMBLIES=SkyAPM.Agent.AspNetCore，添加环境变量有以下几种方式

* 直接添加系统环境变量，这样全部的项目都生效

  ![系统环境变量.png](https://wx1.sinaimg.cn/large/0072fULUgy1g7v7gazl24j30ro0cht9q.jpg)

* 在项目中添加，可以在`launchSettings.json`或者是在启动项配置里面添加，两个效果都是一样的

### 三. 添加配置文件

这里也有几种添加配置的方式，从源码中发现，配置的加载顺序是先加载默认配置（ *可以进入 AddSkyWalkingDefaultConfig 查看源码，里面含 skywalking.json 所有默认配置项* ），然后加载 appsettings.json、skywalking.json，所有 skywalking.json 的默认配置完全可以先去掉，需要的时候再设置，更简洁点其实我们并需要 skywalking.json ，只需要使用 appsettings.json 就可以。

```c#
builder.AddSkyWalkingDefaultConfig();

builder.AddJsonFile("appsettings.json", true).AddJsonFile($"appsettings.{environmentProvider.EnvironmentName}.json", true);

builder.AddJsonFile("skywalking.json", true).AddJsonFile($"skywalking.{environmentProvider.EnvironmentName}.json", true);
```



#### 1. 通过SkyWalking的脚本命令自动生成

首先通过以下命令安装 SkyWalking DotNet CLI

```bash
dotnet tool install -g SkyWalking.DotNet.CLI
```

这一步安装完成后，也可以选择将.net core Agent到当前机器上（可选，后面写怎么用）

```bash
dotnet skywalking install
```

这一步的安装需要注意以下几项：

* 使用管理员权限运行 cmd
* 必须切到 C 盘路径下执行命令
* 如果出现 “Access to the path ‘06806e6c49431d12b85aaa5db07b8705d5b317’ is denied” 错误，请删除 “C:/Users/用户名/AppData/Local/Temp/skywalking.agent.aspnetcore” 后，重新执行；

安装可能会比较慢，但是一定要等到最终输出`SkyWalking .NET Core Agent was successfully installed` 才代表成功

接下来就可以使用命令来生成`skywalking.json`配置文件

```bash
dotnet skywalking config [application_code] [collector_server]
```

```json
{
  "SkyWalking": {
    "ServiceName": "your_service_name",
    "Namespace": "",
    "HeaderVersions": [
      "sw6"
    ],
    "Sampling": {
      "SamplePer3Secs": -1,
      "Percentage": -1.0
    },
    "Logging": {
      "Level": "Information",
      "FilePath": "logs/skyapm-{Date}.log"
    },
    "Transport": {
      "Interval": 3000,
      "ProtocolVersion": "v6",
      "QueueSize": 30000,
      "BatchSize": 3000,
      "gRPC": {
        "Servers": "localhost:11800",
        "Timeout": 10000,
        "ConnectTimeout": 10000,
        "ReportTimeout": 600000
      }
    }
  }
}
```

#### 2. 直接使用.net core的配置文件appsettings.json

这种方式就比较简单了，直接在项目里的appsettings.json里加入skywalking的配置节点就行

```json
"SkyWalking": {
    //服务名
    "ServiceName": "Aggreg_2",
    "Logging": {
      "Level": "Information",
      "FilePath": "logs\\skyapm-{Date}.log"
    },
    "Transport": {
      "gRPC": {
        //采集的地址
        "Servers": "192.168.1.219:11800"
      }
    }
  }
```

### 四. 启动服务

启动服务后，可以在项目文件下的log文件夹里面看到按照格式生成的日志

![生成日志.png](https://wx1.sinaimg.cn/large/0072fULUgy1g7v8ed8kwmj30rf09mjrr.jpg)

看到一下信息就表示接入成功了

![日志.png](https://wx1.sinaimg.cn/large/0072fULUgy1g7v8fphjxej30ws03r3z3.jpg)

接下来可以请求几次，去UI界面看效果了，从图中可以看到服务名，请求都有了

![效果图.png](https://wx1.sinaimg.cn/large/0072fULUgy1g7v8jwux8gj313e0ay0tx.jpg)

### 五. 扩展

目前安装.net core Agent是通过引入nuget包，如果服务比较多的话，每一个服务都需要引入探针，由于现在skywalking的发展非常迅速，如果到时候升级的话需要更换所有服务的nuget包，非常麻烦，所以这个时候就可以用到之前提到过的安装本地探针的方式来接入.net core应用（这个方式目前还没试过，不过参考了相关博客），同意配置好环境变量和配置文件后，运行以下命令即可

```bash
set DOTNET_ADDITIONAL_DEPS=%PROGRAMFILES%\dotnet\x64\additionalDeps\skywalking.agent.aspnetcore

dotnet run
```

当然，现在skywalking发展非常迅速，很多组件也会慢慢支持，不过目前就查询接口和sql的功能来说已经完成够用了。

