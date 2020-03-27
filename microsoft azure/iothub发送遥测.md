## Iothub发送遥测





```bash
#获取订阅列表
az account list --output table

#资源组
az group list --output table

#切换到的订阅 ID 或名称使用 az account set
az account set --subscription "efos"

#删除资源组
az group delete --name ExampleResourceGroup
```





### demo

1. 创建设备标识 YourIoTHubName：IoT 中心选择的名称 MyDotnetDevice：这是所注册的设备的名称

```bash
az iot hub device-identity create --hub-name efosTestIot --device-id MyDotnetDevice
```

2. 获取刚注册设备的_设备连接字符串_：

```bash
az iot hub device-identity show-connection-string --hub-name efosTestIot --device-id MyDotnetDevice --output table

ConnectionString
---------------------------------------------------------------------------------------------------------------------------
HostName=efosTestIot.azure-devices.net;DeviceId=MyDotnetDevice;SharedAccessKey=JjNEXBMpXI5wMGQ8xy8aCEFvnbaQrosx+j3QaHASxlM=
```

获取到的连接字符串：

ConnectionString
HostName=efosTestIot.azure-devices.net;DeviceId=MyDotnetDevice;SharedAccessKey=JjNEXBMpXI5wMGQ8xy8aCEFvnbaQrosx+j3QaHASxlM=

3. 还需要使用来自 IoT 中心的与事件中心兼容的终结点、与事件中心兼容的路径和服务主密钥，确保后端应用程序能连接到 IoT 中心并检索消息 。 以下命令可检索 IoT 中心的这些值：

```bash
az iot hub show --query properties.eventHubEndpoints.events.endpoint --name efos-iothub

az iot hub show --query properties.eventHubEndpoints.events.path --name efos-iothub

az iot hub policy show --name service --query primaryKey --hub-name efos-iothub
```

"sb://ihsuprodsgres008dednamespace.servicebus.windows.net/"

"iothub-ehub-efostestio-3100248-ed75745a84"

"uZ0XTw6QzjMCaRPIK0rUnBe3lXPbuAngdvV+VLq8G9M="

4. 设备应用程序会连接到 IoT 中心上特定于设备的终结点，并发送模拟的温度和湿度遥测数据

本地终端窗口中，导航到示例 C# 项目的根文件夹。 然后导航到 **iot-hub\Quickstarts\simulated-device** 文件夹,在所选文本编辑器中打开 SimulatedDevice.cs 文件,将 `s_connectionString` 变量的值替换为之前记下的设备连接字符串。 然后将更改保存到 **SimulatedDevice.cs**

```bash
dotnet restore
dotnet run
```

5. 应用程序会接收模拟设备发送的设备到云的消息

另一本地终端窗口中，导航到示例 C# 项目的根文件夹。 然后导航到 iot-hub\Quickstarts\read-d2c-messages 文件夹,在所选文本编辑器中打开 ReadDeviceToCloudMessages.cs 文件 。 更新以下变量并保存对文件所做的更改

| 变量                            | 值                                                 |
| :------------------------------ | :------------------------------------------------- |
| `s_eventHubsCompatibleEndpoint` | 将变量的值替换为之前记下的与事件中心兼容的终结点。 |
| `s_eventHubsCompatiblePath`     | 将变量的值替换为之前记下的与事件中心兼容的路径。   |
| `s_iotHubSasKey`                | 将变量的值替换为之前记下的服务主密钥。             |

本地终端窗口中，运行以下命令

```bash
dotnet run
```

