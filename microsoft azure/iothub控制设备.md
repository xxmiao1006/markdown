## Iothub控制设备

创建iothub，详情见上节

1. 创建设备标识

```bash
az iot hub device-identity create --hub-name {YourIoTHubName} --device-id MyDotnetDevice
```

2. 获取刚注册设备的_设备连接字符串_

```bash
az iot hub device-identity show-connection-string \
  --hub-name {YourIoTHubName} \
  --device-id MyDotnetDevice \
  --output table
```

3.  IoT 中心服务连接字符串，以便后端应用程序能够连接到中心并检索消息

```bash
az iot hub show-connection-string --policy-name service --name {YourIoTHubName} --output table
```

4. 发送模拟遥测数据

本地终端窗口中，导航到示例 C# 项目的根文件夹。 然后导航到 **iot-hub\Quickstarts\simulated-device-2** 文件夹,所选文本编辑器中打开 SimulatedDevice.cs 文件,将 `s_connectionString` 变量的值替换为之前记下的设备连接字符串。 然后将更改保存到 **SimulatedDevice.cs**。生成并运行模拟设备应用程序

```bash
dotnet restore
dotnet run
```

5. 后端应用程序会连接到 IoT 中心

在另一本地终端窗口中，导航到示例 C# 项目的根文件夹。 然后导航到 iot-hub\Quickstarts\back-end-application 文件夹,在所选文本编辑器中打开 BackEndApplication.cs 文件。将 `s_connectionString` 变量的值替换为以前记下的服务连接字符串。 然后将更改保存到 **BackEndApplication.cs**。

