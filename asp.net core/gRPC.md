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





### 二. gRPC熔断重试