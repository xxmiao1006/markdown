## asp.net core 3.0使用grpc

首先新建一个webapi项目，引入nuget包，这个包含所需要的包以及grpc工具包

![grpc-1.png](https://ws1.sinaimg.cn/large/0072fULUgy1g95vt1tnakj311o0f2tai.jpg)

新建存放proto文件的Grpc文件夹，将proto文件放到该目录下

![grpc-2.png](https://ws1.sinaimg.cn/large/0072fULUgy1g95vv5dy5zj30dt067aa2.jpg)

然后在项目的csproj文件中引入该文件夹

![grpc-3.png](https://ws1.sinaimg.cn/large/0072fULUgy1g95vwd1e77j30lo04jglp.jpg)

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

