## asp.net core 3.0使用grpc

首先新建一个webapi项目，引入nuget包，这个包含所需要的包以及grpc工具包

![grpc-1.png](https://wx1.sinaimg.cn/large/0072fULUgy1g95vt1tnakj311o0f2tai.jpg)

新建存放proto文件的Grpc文件夹，将proto文件放到该目录下

![grpc-2.png](https://wx1.sinaimg.cn/large/0072fULUgy1g95vv5dy5zj30dt067aa2.jpg)

然后在项目的csproj文件中引入该文件夹

![grpc-3.png](https://wx1.sinaimg.cn/large/0072fULUgy1g95vwd1e77j30lo04jglp.jpg)

最后在start.up中进行依赖注入

```c#
services.AddGrpcClient<ProjectAreaer.ProjectAreaerClient>(o =>
            {
                o.Address = new Uri("");
            }).ConfigurePrimaryHttpMessageHandler(() =>
            {
                var handler = new HttpClientHandler();
                handler.ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
                return handler;
            });
```

最后在聚合层（控制层）引入使用



```c#


private readonly ProjectAreaer.ProjectAreaerClient ProjectAreaClient;
        public WisdomToiletScreenController(ProjectAreaer.ProjectAreaerClient ProjectAreaClient)
        {
            this.ProjectAreaClient = ProjectAreaClient;
        }


public override async Task SayHellos(HelloRequest request,
        IServerStreamWriter<HelloReply> responseStream, ServerCallContext context)
    {
        // Forward the call on to the greeter service
        using (var call = _client.SayHellos(request))
        {
            await foreach (var response in call.ResponseStream.ReadAllAsync())
            {
                await responseStream.WriteAsync(response);
            }
        }
    }
```

-------

### 关于一些使用gRPC的测试

```c#
var channel = GrpcChannel.ForAddress("https://localhost:5001");
            var client = new Greeter.GreeterClient(channel);

//忽略ssl证书
var channel = GrpcChannel.ForAddress(HYD_GRPCSERVICES_CORE, new GrpcChannelOptions
            {
                HttpClient = new HttpClient(new HttpClientHandler
                {
                    ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator
                })
            });

            var client = new CoreDataQueryer.CoreDataQueryerClient(channel);
```

创建一个客户端，客户端会绑定一个端口，当使用同一个客户端发送请求时，端口是一样的，并且不会有端口占用的问题。



### gRPC Interceptor

 ```c#
public virtual TResponse BlockingUnaryCall<TRequest, TResponse>();
public virtual AsyncUnaryCall<TResponse> AsyncUnaryCall<TRequest, TResponse>();
public virtual AsyncServerStreamingCall<TResponse> AsyncServerStreamingCall<TRequest, TResponse>();
public virtual AsyncClientStreamingCall<TRequest, TResponse> AsyncClientStreamingCall<TRequest, TResponse>();
public virtual AsyncDuplexStreamingCall<TRequest, TResponse> AsyncDuplexStreamingCall<TRequest, TResponse>();
public virtual Task<TResponse> UnaryServerHandler<TRequest, TResponse>();
public virtual Task<TResponse> ClientStreamingServerHandler<TRequest, TResponse>();
public virtual Task ServerStreamingServerHandler<TRequest, TResponse>();
public virtual Task DuplexStreamingServerHandler<TRequest, TResponse>();
 ```

| 方法名称                     | 作用                                   |
| :--------------------------- | :------------------------------------- |
| BlockingUnaryCall            | 拦截阻塞调用                           |
| AsyncUnaryCall               | 拦截异步调用                           |
| AsyncServerStreamingCall     | 拦截异步服务端流调用                   |
| AsyncClientStreamingCall     | 拦截异步客户端流调用                   |
| AsyncDuplexStreamingCall     | 拦截异步双向流调用                     |
| UnaryServerHandler           | 用于拦截和传入普通调用服务器端处理程序 |
| ClientStreamingServerHandler | 用于拦截客户端流调用的服务器端处理程序 |
| ServerStreamingServerHandler | 用于拦截服务端流调用的服务器端处理程序 |
| DuplexStreamingServerHandler | 用于拦截双向流调用的服务器端处理程序   |

在客户端项目新建一个类，命名为 `ClientLoggerInterceptor`，继承拦截器基类 `Interceptor`。

我们在前面使用的Demo，定义了撸猫服务，其中 `SuckingCatAsync`方法为异步调用，所以我们重写拦截器的 `AsyncUnaryCall`方法

```c#
public class ClientLoggerInterceptor:Interceptor
{
  public override AsyncUnaryCall<TResponse> AsyncUnaryCall<TRequest, TResponse>(
    TRequest request,
    ClientInterceptorContext<TRequest, TResponse> context,
    AsyncUnaryCallContinuation<TRequest, TResponse> continuation)
  {
    LogCall(context.Method);

    return continuation(request, context);
  }

  private void LogCall<TRequest, TResponse>(Method<TRequest, TResponse> method)
    where TRequest : class
    where TResponse : class
  {
    var initialColor = Console.ForegroundColor;
    Console.ForegroundColor = ConsoleColor.Green;
    Console.WriteLine($"Starting call. Type: {method.Type}. Request: {typeof(TRequest)}. Response: {typeof(TResponse)}");
    Console.ForegroundColor = initialColor;
  }
}
```

```c#
var channel = GrpcChannel.ForAddress("https://localhost:5001");
//注册拦截器
var invoker = channel.Intercept(new ClientLoggerInterceptor());
var catClient = new LuCat.LuCatClient(invoker);
var catReply = await catClient.SuckingCatAsync(new Empty());
Console.WriteLine("调用撸猫服务："+ catReply.Message);
```

在服务端项目新建一个类，命名为 `ServerLoggerInterceptor`，继承拦截器基类 `Interceptor`。

我们在服务端需要实现的方法是 `UnaryServerHandler`

```c#
public class ServerLoggerInterceptor: Interceptor
{
  private readonly ILogger<ServerLoggerInterceptor> _logger;

  public ServerLoggerInterceptor(ILogger<ServerLoggerInterceptor> logger)
  {
    _logger = logger;
  }

  public override Task<TResponse> UnaryServerHandler<TRequest, TResponse>(
    TRequest request,
    ServerCallContext context,
    UnaryServerMethod<TRequest, TResponse> continuation)
  {
    LogCall<TRequest, TResponse>(MethodType.Unary, context);
    return continuation(request, context);
  }

  private void LogCall<TRequest, TResponse>(MethodType methodType, ServerCallContext context)
    where TRequest : class
    where TResponse : class
  {
    _logger.LogWarning($"Starting call. Type: {methodType}. Request: {typeof(TRequest)}. Response: {typeof(TResponse)}");
  }
}
```

startup里面注册拦截器：

```c#
public void ConfigureServices(IServiceCollection services)
{
  services.AddGrpc(options =>
  {
    options.Interceptors.Add<ServerLoggerInterceptor>();
  });
}
```

远程连接proto文件

```c#
<ItemGroup>
    <Protobuf Include="..\..\StreamTest\StreamTest\Protos\LuCat.proto" GrpcServices="Client">
      <Link>Protos\LuCat.proto</Link>
    </Protobuf>
    <Protobuf Include="Protos\greet.proto" GrpcServices="Client">
      <SourceUri>http://192.168.1.31:9999/files/protos/greet.proto</SourceUri>
    </Protobuf>
  </ItemGroup>
```

