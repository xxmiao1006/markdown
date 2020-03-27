## Azure Cosmos DB

### 1 创建cosmosdb

```bash
# Set variables for the new SQL API account, database, and container
resourceGroupName='myResourceGroup'
location='chinaeast'

# The Azure Cosmos account name must be multiple-regionally unique, make sure to update the `mysqlapicosmosdb` value before you run the command
accountName='mysqlapicosmosdb'

# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location

# Create a SQL API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --kind GlobalDocumentDB \
    --locations regionName="China East" failoverPriority=0 --locations regionName="China North" failoverPriority=1 \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true
```



### 2 .net core 使用cosmosdb

https://sourcegraph.com/github.com/Azure/azure-cosmos-dotnet-v3/-/blob/Microsoft.Azure.Cosmos.Samples/Usage/ContainerManagement/Program.cs#L27

1. 新建 .NET  core应用 并且添加cosmosnuget包

```bash
dotnet new console --langVersion 7.1 -n todo
dotnet add package Microsoft.Azure.Cosmos
```

2. 从 Microsoft Azure 门户复制 Azure Cosmos 帐户凭据，可以将其设置为环境变量

```bash
setx EndpointUrl "<Your_Azure_Cosmos_account_URI>"
setx PrimaryKey "<Your_Azure_Cosmos_account_PRIMARY_KEY>"
```



- [CosmosClient](https://docs.microsoft.com/dotnet/api/microsoft.azure.cosmos.cosmosclient?view=azure-dotnet) - 此类为 Azure Cosmos DB 服务提供客户端逻辑表示。 此客户端对象用于对服务进行配置和执行请求。
- [CreateDatabaseIfNotExistsAsync](https://docs.microsoft.com/dotnet/api/microsoft.azure.cosmos.cosmosclient.createdatabaseifnotexistsasync?view=azure-dotnet) - 若数据库资源不存在，则此方法以异步操作的形式创建数据库资源；若数据库资源已存在，则此方法以异步操作的形式获取它。
- [CreateContainerIfNotExistsAsync](https://docs.microsoft.com/dotnet/api/microsoft.azure.cosmos.database.createcontainerifnotexistsasync?view=azure-dotnet) - 若容器不存在，则此方法以异步操作的形式创建容器；若容器已存在，则此方法以异步操作的形式获取它。 可查看响应中的状态代码，确定是新创建了容器 (201) 还是返回了现有容器 (200)。
- [CreateItemAsync](https://docs.microsoft.com/dotnet/api/microsoft.azure.cosmos.container.createitemasync?view=azure-dotnet) - 此方法在容器中创建项。
- [UpsertItemAsync](https://docs.microsoft.com/dotnet/api/microsoft.azure.cosmos.container.upsertitemasync?view=azure-dotnet) - 此方法在容器内创建一个项（如果该项尚不存在）或替换该项（如果该项已存在）。
- [GetItemQueryIterator](https://docs.microsoft.com/dotnet/api/microsoft.azure.cosmos.container.GetItemQueryIterator?view=azure-dotnet) - 此方法使用带有参数化值的 SQL 语句在 Azure Cosmos 数据库的容器下创建项查询。
- [DeleteAsync](https://docs.microsoft.com/dotnet/api/microsoft.azure.cosmos.database.deleteasync?view=azure-dotnet) - 从 Azure Cosmos 帐户中删除指定的数据库。 `DeleteAsync` 方法只删除数据库。 应单独处理 `Cosmosclient` 实例（DeleteDatabaseandCleanupAsync 方法中如此操作）。