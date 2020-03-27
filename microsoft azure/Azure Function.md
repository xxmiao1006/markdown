## Azure Function

### 1. 创建Function应用

​		可通过Azure partal先创建好应用，然后再通过Visual Studio创建和编写函数，再发布到我们创建好的函数应用。

​		Azure Functions 应用托管一个或多个 Azure Functions。 它为函数提供了环境和运行时。Azure 目前提供运行 Azure Functions 所需的两个版本的运行时环境。 版本 1 (v1) 使用 .NET Framework 4.7，而版本 2 (v2) 使用 .NET Core 2 运行。Azure Functions 由事件触发，而不是直接从应用程序调用（如http触发器可通过http请求直接调用，但不推荐）。 可指定将触发函数应用中函数的事件类型。 可用事件包括：

- **Blob 触发器**。 在 Azure Blob 存储中上传或修改文件时，会运行此函数类型。
- **事件中心触发器**。 事件中心收到消息时，事件中心触发器会运行函数。
- **Azure Cosmos DB 触发器**。 当文档添加到 Azure Cosmos DB 数据库或在其中进行修改时，此触发器会运行。 可使用此触发器将 Azure Cosmos DB 与其他服务集成。 例如，如果将表示客户订单的文档添加到数据库，则可使用触发器将订单副本发送到队列进行处理。
- **HTTP 触发器**。 当 Web 应用中发生 HTTP 请求时，HTTP 触发器会运行该函数。 还可使用此触发器响应 Webhook。 Webhook 是在修改网站托管的项时发生的回叫。 例如，可创建一个 Azure Functions，当存储库中的项发生更改时，该函数将由 GitHub 存储库中的 Webhook 触发。
- **队列触发器**。 当新项添加到 Azure 存储队列时，此触发器将触发函数。
- **服务总线队列触发器**。 当新项添加到 Azure 服务总线队列时，使用此触发器运行函数。
- **服务总线主题触发器**。 此触发器运行该函数以响应到达服务总线主题的新消息。
- **计时器触发器**。 使用此事件可以按照你定义的计划在常规域间运行 Azure Functions。

由 HTTP 请求触发的 Azure Functions 支持三个级别的访问权限：

- **匿名**。 无需身份验证，任何用户都可以触发该函数。
- **函数**。 HTTP 请求必须提供一个密钥，使 Azure Functions 运行时能够授权请求。 可单独创建此密钥，也可使用 Azure 门户对其进行维护。
- **管理员**。这类似于 Function，因为用户必须使用触发该函数的 HTTP 请求指定密钥。 区别在于此密钥是管理员密钥。 此密钥可用于访问函数应用中的任何函数。 使用功能键，可单独创建此密钥

​        如果正在创建由 HTTP 请求以外的事件触发的函数，则需要提供连接字符串以及函数应用访问触发事件的资源所需的其他详细信息。 例如，如果正在编写由 Blob 存储事件触发的函数，则必须为相应的 Blob 存储帐户指定连接字符串。

具体通过visual Studio创建Functions请参阅[创建第一个Function(c#)并发布](https://docs.microsoft.com/zh-cn/azure/azure-functions/functions-create-your-first-function-visual-studio)

### 2.Azure Functions 的结构

​		Azure Functions 作为静态类实现。 此类提供名为 `Run` 的静态异步方法，可充当函数的入口点。

传递给 `Run` 方法的参数提供触发器的上下文。 对于 HTTP 触发器，该函数接收 HttpRequest 对象。 此对象包含请求的标头和主体。 可使用任何 HTTP 应用程序中提供的相同技术访问请求中的数据。 应用于此属性的属性指定授权要求（在本例中为 Anonymous），以及 Azure 函数响应的 HTTP 操作（GET 和 POST）。

Visual Studio 生成的示例代码（如下所示）检查作为请求 URL 一部分所提供的查询字符串，并查找名为 name 的参数。 该代码还使用 StreamReader 来反序列化请求的主体，并尝试从请求中读取名为 name 的属性的值。 如果在查询字符串或请求主体中找到 name，则会在响应中返回，否则该函数会生成错误响应，并显示消息“请在查询字符串上或在请求主体中传递名称”。

```c#
public static class Function1
{
    [FunctionName("Function1")]
    public static async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
        ILogger log)
    {
        log.LogInformation("C# HTTP trigger function processed a request.");

        string name = req.Query["name"];

        string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
        dynamic data = JsonConvert.DeserializeObject(requestBody);
        name = name ?? data?.name;

        return name != null
            ? (ActionResult)new OkObjectResult($"Hello, {name}")
            : new BadRequestObjectResult("Please pass a name on the query string or in the request body");
    }
}
```

该函数返回一个包含任何输出数据和结果的值，包装在 IActionResult 对象中。 该值将在请求的 HTTP 响应主体中返回。

不同类型的触发器接收不同的输入参数和返回类型。 下一个示例显示为 Blob 触发器生成的代码。 在此示例中，可以通过 Stream 对象访问 blob 的内容，还提供了 blob 的名称。 触发器不返回任何数据；其目的是读取和处理命名 blob 中的数据：

```c#
public static class Function2
{
    [FunctionName("Function2")]
    public static void Run([BlobTrigger("samples-workitems/{name}", Connection = "xxxxxxxxxxxxxxxxxxxxxxx")]Stream myBlob, string name, ILogger log)
    {
        log.LogInformation($"C# Blob trigger function Processed blob\n Name:{name} \n Size: {myBlob.Length} Bytes");
    }
}
```

Azure Functions 还包含指定触发器类型的元数据以及任何其他特定信息和安全要求。 可使用 HttpTrigger、BlobTrigger 或其他触发器属性修改此元数据，如示例中所示。 函数前面的 **FunctionName** 属性是函数应用使用的函数的标识符。 此名称不必与函数名称相同，但最好保持它们同步以避免混淆。

### 3. 本地测试

可使用 Visual Debugger 在本地生成和测试 Functions 应用。 按 F5 或选择“调试”菜单上的“开始调试”。 函数运行时的本地版本将启动。 函数可用于测试。 该示例显示托管 Function1 的运行时。 这是由 HTTP 事件触发的函数。 URL 指示该函数当前附加到的终结点。

![function_4.jpg](https://wx1.sinaimg.cn/large/0072fULUgy1gd8ay1ixcsj30rl0efjtj.jpg)

### 4. 参考

[Azure Functions 文档](https://docs.microsoft.com/zh-cn/azure/azure-functions/)

[使用 Visual Studio 创建你的第一个函数](https://docs.microsoft.com/zh-cn/azure/azure-functions/functions-create-your-first-function-visual-studio)

[使用 Visual Studio 开发、测试和部署 Azure Functions](https://docs.microsoft.com/zh-cn/learn/modules/develop-test-deploy-azure-functions-with-visual-studio/)

[管理 Azure Functions 中的连接](https://docs.microsoft.com/zh-cn/azure/azure-functions/manage-connections)

[不当实例化反模式](https://docs.microsoft.com/zh-cn/azure/architecture/antipatterns/improper-instantiation/)

[Azure Functions 触发器和绑定概念](https://docs.microsoft.com/zh-cn/azure/azure-functions/functions-triggers-bindings)

