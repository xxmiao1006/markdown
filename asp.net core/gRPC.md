## gRPC

### 一. protobuf管理参考

可以手动添加引用的方式将proto文件引入项目，也可以使用`dotnet-grpc`.net core全局工具管理proto引用，这个工具可以用于添加、刷新、删除和列出 Protobuf 引用。

在项目中可以通过以下两种方式添加protobuf引用。

Protobuf 引用用于生成 C# 客户端和/或服务器资产。 `dotnet-grpc` 工具可以：

- 从磁盘上的本地文件（相对路径或绝对路径）创建 Protobuf 引用。
- 从 URL 指定的远程文件创建 Protobuf 引用。



确保将正确的 gRPC 包依赖项添加到项目。

例如，将 `Grpc.AspNetCore` 包添加到 Web 应用。 `Grpc.AspNetCore` 包含 gRPC 服务器和客户端库以及工具支持。 或者，将 `Grpc.Net.Client`、`Grpc.Tools` 和 `Google.Protobuf` 包（其中仅包含 gRPC 客户端库和工具支持）添加到控制台应用。



### 1.添加本地文件的方式

项目目录结构

![项目目录结构.png](http://ww1.sinaimg.cn/large/0072fULUgy1gs9a2tq4i7j60c4082dfw02.jpg)



可以手动将**<ItemGroup>标签**加到.csproj文件中

```c#
<ItemGroup>
    <PackageReference Include="Google.Protobuf" Version="3.17.3" />
    <PackageReference Include="Grpc.AspNetCore.Server.ClientFactory" Version="2.38.0" />
    <PackageReference Include="Grpc.Net.ClientFactory" Version="2.38.0" />
    <PackageReference Include="Grpc.Tools" Version="2.38.1">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>

  <ItemGroup>
    <Protobuf Include="Protos\*.proto" GrpcServices="Client" />
  </ItemGroup>
```

也可以使用`dotnet-grpc`工具，在cmd中操作

```bash
dotnet grpc add-file [options] <files>...
```

#### 参数

| 参数 | 描述                                                         |
| :--- | :----------------------------------------------------------- |
| 文件 | Protobuf 文件引用。 这些可以是本地 protobuf 文件的 glob 的路径。 |

#### 选项

| 短选项 | 长选项                   | 描述                                                         |
| :----- | :----------------------- | :----------------------------------------------------------- |
| -p     | --project                | 要操作的项目文件的路径。 如果未指定文件，则该命令会在当前目录中搜索一个文件。 |
| -S     | --services               | 应生成的 gRPC 服务的类型。 如果指定 `Default`，则 `Both` 用于 Web 项目，而 `Client` 用于非 Web 项目。 接受的值包括 `Both`、`Client`、`Default`、`None` 和 `Server`。 |
| -o     | --additional-import-dirs | 解析 protobuf 文件的导入时要使用的其他目录。 这是以分号分隔的路径列表。 |
|        | --access                 | 要用于生成的 C# 类的访问修饰符。 默认值为 `Public`。 接受的值为 `Internal` 和 `Public`。 |

测试

添加引用，将Protos文件下的所有proto文件以客户端的类型引入

```bash
$ dotnet grpc add-file Protos\*.proto -s client
Adding file reference Protos\greet.proto.
```

也可以添加不在当前项目下的Proto文件(相对路径绝对路径都可以)，

```bash
#相对路径
$dotnet grpc add-file ..\StreamTest\StreamTest\Protos\*.proto -s client
Adding file reference ..\StreamTest\StreamTest\Protos\greet.proto.
Adding file reference ..\StreamTest\StreamTest\Protos\LuCat.proto.
##绝对路径
$ dotnet grpc add-file E:\VsProjects\Grpc-dotnet\StreamTest\StreamTest\Protos\*.proto -s client
Adding file reference E:\VsProjects\Grpc-dotnet\StreamTest\StreamTest\Protos\greet.proto.
Adding file reference E:\VsProjects\Grpc-dotnet\StreamTest\StreamTest\Protos\LuCat.proto.
```

通过这种形式添加的proto文件在csproj文件中会则会添加一个 `Link` 元素，以在 Visual Studio 中的虚拟文件夹 `Protos` 下显示该文件。

```c#
//相对路径
<ItemGroup>
    <Protobuf Include="..\StreamTest\StreamTest\Protos\greet.proto" GrpcServices="Client" Link="Protos\greet.proto" />
    <Protobuf Include="..\StreamTest\StreamTest\Protos\LuCat.proto" GrpcServices="Client" Link="Protos\LuCat.proto" />
</ItemGroup>

//绝对路径
<ItemGroup>
    <Protobuf Include="E:\VsProjects\Grpc-dotnet\StreamTest\StreamTest\Protos\greet.proto" GrpcServices="Client" Link="Protos\greet.proto" />
    <Protobuf Include="E:\VsProjects\Grpc-dotnet\StreamTest\StreamTest\Protos\LuCat.proto" GrpcServices="Client" Link="Protos\LuCat.proto" />
</ItemGroup>

```



删除引用(只删除引用，不会删除项目里面的文件)

```bash
$ dotnet grpc remove Protos\
Removing reference to file Protos\greet.proto.
```



### 2.添加url的方式



使用`dotnet-grpc`工具

```bash
dotnet-grpc add-url [options] <url>
```

#### 参数

| 参数 | 描述                       |
| :--- | :------------------------- |
| URL  | 远程 protobuf 文件的 URL。 |

#### 选项

| 短选项 | 长选项                   | 描述                                                         |
| :----- | :----------------------- | :----------------------------------------------------------- |
| -o     | --output                 | 指定远程 protobuf 文件的下载路径。 这是必需选项。            |
| -p     | --project                | 要操作的项目文件的路径。 如果未指定文件，则该命令会在当前目录中搜索一个文件。 |
| -S     | --services               | 应生成的 gRPC 服务的类型。 如果指定 `Default`，则 `Both` 用于 Web 项目，而 `Client` 用于非 Web 项目。 接受的值包括 `Both`、`Client`、`Default`、`None` 和 `Server`。 |
| -o     | --additional-import-dirs | 解析 protobuf 文件的导入时要使用的其他目录。 这是以分号分隔的路径列表。 |
|        | --access                 | 要用于生成的 C# 类的访问修饰符。 默认值是 `Public`。 接受的值为 `Internal` 和 `Public`。 |

测试

```bash
$ dotnet-grpc add-url http://52.131.224.115:10000/file/Protos/greet.proto -o Protos/greet.proto -s client
Updating content of Protos/greet.proto with content at http://52.131.224.115:10000/file/Protos/greet.proto.
Adding file reference Protos/greet.proto with content from http://52.131.224.115:10000/file/Protos/greet.proto.
```

```c#
  <ItemGroup>
    <Protobuf Include="Protos/greet.proto" GrpcServices="Client">
      <SourceUrl>http://52.131.224.115:10000/file/Protos/greet.proto</SourceUrl>
    </Protobuf>
  </ItemGroup>
```

**注意url必须是可以下载的**

#### refresh刷新命令

`refresh` 命令用于使用来自源 URL 的最新内容更新远程引用。 下载文件路径和源 URL 都可以用于指定要更新的引用。 注意：

- 会比较文件内容的哈希，以确定是否应更新本地文件。
- 不会比较时间戳信息。

如果需要更新，则该工具始终将本地文件替换为远程文件。

```bash
dotnet-grpc refresh [options] [<references>...]
```

##### 参数

| 参数 | 描述                                                         |
| :--- | :----------------------------------------------------------- |
| 引用 | 应更新的远程 protobuf 引用的 URL 或文件路径。 将此参数保留为空，以刷新所有远程引用。 |

##### 选项

| 短选项 | 长选项    | 描述                                                         |
| :----- | :-------- | :----------------------------------------------------------- |
| -p     | --project | 要操作的项目文件的路径。 如果未指定文件，则该命令会在当前目录中搜索一个文件。 |
|        | --dry-run | 输出将更新的文件的列表，而不下载任何新内容。                 |



测试

首先去服务器上更改proto文件  然后使用refresh命令去更新

```bash
##加--dry-run只输出要更新的内容，但是不会更新
E:\VsProjects\TestGrpcWebApi
$ dotnet-grpc refresh Protos\ --dry-run
Updating content of Protos/greet.proto with content at http://52.131.224.115:10000/file/Protos/greet.proto.

E:\VsProjects\TestGrpcWebApi
$ dotnet-grpc refresh Protos\
Updating content of Protos/greet.proto with content at http://52.131.224.115:10000/file/Protos/greet.proto.
```



最佳实践推荐使用单独的git仓库来管理所有的proto文件，利用文件服务器或者git submodule的形式使用。客户端服务端通过远程引用来引用同一份proto通信协议，并且强制性确保所有proto文件向下兼容。

关于proto文件管理具体请查看官网： [通过dotnet-grpc工具管理Protobuf参考](https://docs.microsoft.com/zh-cn/aspnet/core/grpc/dotnet-grpc?view=aspnetcore-5.0)



### 二. gRPC熔断重试

​		gRPC 重试属于客户端重试， [Grpc.Net.Client](https://www.nuget.org/packages/Grpc.Net.Client) 2.36.0 或更高版本gRPC的客户端包内置了重试的功能。首先需要弄清楚什么样的，什么时候的重试才是有意义的：

* 网络连接状况不好的情况重试，即只在故障是暂时性，以及在重新尝试后操作至少有一些成功的可能性时，才应重试操作。
* 服务幂等，接口不幂等的情况下重试可能会发现不可预料的情况，而像get接口等获取数据的接口才建议配置重试策略。



#### 配置 gRPC 重试策略

下表描述了用于配置 gRPC 重试策略的选项：

| 选项                   | 描述                                                         |
| :--------------------- | :----------------------------------------------------------- |
| `MaxAttempts`          | 最大调用尝试次数，包括原始尝试。 此值受 `GrpcChannelOptions.MaxRetryAttempts`（默认值为 5）的限制。 必须为该选项提供值，且值必须大于 1。 |
| `InitialBackoff`       | 重试尝试之间的初始退避延迟。 介于 0 与当前退避之间的随机延迟确定何时进行下一次重试尝试。 每次尝试后，当前退避将乘以 `BackoffMultiplier`。 必须为该选项提供值，且值必须大于 0。 |
| `MaxBackoff`           | 最大退避会限制指数退避增长的上限。 必须为该选项提供值，且值必须大于 0。 |
| `BackoffMultiplier`    | 每次重试尝试后，退避将乘以该值，并将在乘数大于 1 的情况下以指数方式增加。 必须为该选项提供值，且值必须大于 0。 |
| `RetryableStatusCodes` | 状态代码的集合。 具有匹配状态的失败 gRPC 调用将自动重试。 有关状态代码的更多信息，请参阅[状态代码及其在 gRPC 中的用法](https://grpc.github.io/grpc/core/md_doc_statuscodes.html)。 至少需要提供一个可重试的状态代码。 |

创建webAPI项目，引入Grpc.Net.Client包。在startup文件里面注入gRPC客户端，并加入以下配置

```c#
public void ConfigureServices(IServiceCollection services)
{
    services.AddControllers();


    var defaultMethodConfig = new MethodConfig
    {
        Names = { MethodName.Default },
        RetryPolicy = new RetryPolicy
        {
            MaxAttempts = 5,
            InitialBackoff = TimeSpan.FromSeconds(1),
            MaxBackoff = TimeSpan.FromSeconds(5),
            BackoffMultiplier = 1.5,
            // StatusCode.DeadlineExceeded, StatusCode.Unavailable, 
            RetryableStatusCodes = { StatusCode.Cancelled }
        }
    };


    services.AddGrpcClient<Greeter.GreeterClient>(o =>
         {
               o.Address = new Uri("https://localhost:5001");
         })
        //配置超时取消令牌
        .EnableCallContextPropagation()
        .EnableCallContextPropagation(o => o.SuppressContextNotFoundErrors = true)
        //配置取消https认证
        .ConfigurePrimaryHttpMessageHandler(() =>
         {
             var handler = new HttpClientHandler();
             handler.ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
             return handler;
         })
        //配置重试
        .ConfigureChannel(grpcChannelOptions =>
        {
             grpcChannelOptions.ServiceConfig = new ServiceConfig { MethodConfigs = { defaultMethodConfig } };
         });

}
```

注意上面`RetryPolicy`中的`RetryableStatusCodes`，这个属性声明了会进行重试的回复状态码，这里我将他改成了`Cancelled`,方便后面进行测试，一般情况下我们配置的是`Unavailable`，为了方便测试，在gRPC服务端实现了如下方法，声明了一个全局变量，在抛出三次RPC异常后才成功来测试我们的重试策略。代码如下

```c#
//private static Int32 _retryTime = 0;
public override Task<TestRetryReply> TestRetry(TestRetryRequest request, ServerCallContext context)
{
    if (_retryTime <= 3)
    {
        _retryTime++;
        //抛出Cancelled异常配合测试
        throw new RpcException(Status.DefaultCancelled);
    }
    _retryTime--;
    Console.WriteLine("请求重试次数-----------" + _retryTime);
    return Task.FromResult(new TestRetryReply { Message = "testRetry success，retry times:" + _retryTime });
}
```

客户端调用代码，就是一个简单的调用，重试策略在startup文件里面配置好，调用时和普通调用是一样的。

```c#
[HttpGet("TestRetry")]
public ActionResult<string> TestRetry()
{
    var result = _client.TestRetry(new TestRetryRequest { });
    return result.Message;
}
```

调用结果,可以看的我们第一次调用失败，然后进行了三次重试，第四次重试返回了成功，

![gRPC重试策略测试.png](http://ww1.sinaimg.cn/large/0072fULUgy1gsagdb26nvj60uu0mlq4g02.jpg)



gRPC还有一种重试策略 hedging策略， hedging策略可以再不等待响应的情况下直接进行重试，所以使用这种策略必须保证服务方法是幂等的。

总体来看的话gPRC要实现重试是非常方便的，但是提供的配置策略不够灵活，无法根据请求方法类型等进行更多维度的重试策略配置，如果需要生产级别使用的话还是推荐使用polly。

gRPC重试策略具体请查看官方文档[暂时性故障处理](https://docs.microsoft.com/zh-cn/aspnet/core/grpc/retries?view=aspnetcore-5.0)





Protocol Buffer 的性能好，主要体现在 序列化后的数据体积小 & 序列化速度快，最终使得传输效率高，其原因如下：
序列化速度快的原因：
a. 编码 / 解码 方式简单（只需要简单的数学运算 = 位移等等）
b. 采用 Protocol Buffer 自身的框架代码 和 编译器 共同完成序列化后的数据量体积小（即数据压缩效果好）的原因：
a. 采用了独特的编码方式，如 Varint、Zigzag 编码方式等等
b. 采用T - L - V 的数据存储方式：减少了分隔符的使用 & 数据存储得紧凑




基于Protobuf序列化原理分析，为了有效降低序列化后数据量的大小，可以采用以下措施：

1. 字段标识号（Field_Number）尽量只使用1-15，且不要跳动使用  Tag是需要占字节空间的。如果Field_Number>16时，Field_Number的编码就会占用2个字节，那么Tag在编码时就会占用更多的字节；如果将字段标识号定义为连续递增的数值，将获得更好的编码和解码性能
2. 若需要使用的字段值出现负数，请使用sint32/sint64，不要使用int32/int64。 采用sint32/sint64数据类型表示负数时，会先采用Zigzag编码再采用Varint编码，从而更加有效压缩数据
3. 对于repeated字段，尽量增加packed=true修饰  增加packed=true修饰，repeated字段会采用连续数据存储方式，即T - L - V - V -V方式

[常见的序列化框架及Protobuf序列化原理](https://www.jianshu.com/p/657fbf347934)

