## dotnet-dump

 ### dotnet-dump collect

用命令按照dotnet抓取dump和分析dump的工具

```bash
 dotnet tool install --global dotnet-dump
```

假如进程30865 Hyd.CDC.ComputeServices.ObjectHistory 假死

抓取假死的进程的dump文件（包括内存、调用堆栈）

```bash
dotnet-dump collect -p 30865
```

查看假死进程那个线程所占用的cpu最高，将使用cpu最高的线程pid记下来

```bash
top -Hp 30865
```

将占用cpu最高的线程id打成16进制  记录下输出的16进制线程id 等下分析dump要用

```bash
printf ‘%x\n’ 15671
```

注意，做完这步再重启服务，不然找不到占用cpu或者内存较高的线程id，无法分析dump文件

### dotnet-dump analyze

以Hyd.CDC.ComputeServices.ObjectHistory服务为例，在34抓了一个dump文件

`dotnet-dump analyze ./core_20210322_154915`开始分析刚刚dump下来的文件

```bash
dotnet-dump analyze ./core_20210322_154915
Loading core dump: ./core_20210322_154915 ...
Ready to process analysis commands. Type 'help' to list available commands or 'help [command]' to get detailed help on a command.
Type 'quit' or 'exit' to exit the session.

```

将线程全部打印出来

```bash
> clrthreads                                                                                                                                                                                                                                                              
ThreadCount:      36
UnstartedThread:  0
BackgroundThread: 32
PendingThread:    0
DeadThread:       3
Hosted Runtime:   no
                                                                                                            Lock  
 DBG   ID     OSID ThreadOBJ           State GC Mode     GC Alloc Context                  Domain           Count Apt Exception
  29    1     7891 000000000218E220  2020020 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
  39    2     7c45 00000000022C7390    21220 Preemptive  00007F6D935D04C0:00007F6D935D1B78 00000000021A19F0 0     Ukn (Finalizer) 
  41    3     7c8c 00007F6B680009F0  1020220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn (Threadpool Worker) 
  42    7     7f6a 0000000002572320    21220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
  43    8     7fff 00000000025B3760  2021220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   1    9      1cb 00000000025E5CB0    21220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   2    5      7b6 00007F6B84000BD0    21220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   3   14      7b7 00007F6B84001CA0    21220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   4   15      7ba 00007F6B840030B0    21220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   5   16      7bb 00007F6B84004E30    21220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   6   17      7bc 00007F6B84006CC0    21220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   7   18      7c0 00007F6B84008A40    21220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
  40   31     7c6d 00007F6B6404DBA0    20220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   9   13     174f 00007F6B64071780  2021220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn 
   8   60      e97 00007F6ACC003830  1021220 Preemptive  00007F6B937C4398:00007F6B937C6300 00000000021A19F0 0     Ukn (Threadpool Worker) 
XXXX   55        0 00007F6B080172E0  1031820 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn (Threadpool Worker) 
  10   30     19a4 00007F6B0000BC90  1021220 Preemptive  00007F6C147AB2D0:00007F6C147ABFD0 00000000021A19F0 2     Ukn (Threadpool Worker) 
XXXX   42        0 00007F6B3001F180  1031820 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn (Threadpool Worker) 
  11   72     260d 00007F6AE4003650  1021220 Preemptive  00007F6D94891B00:00007F6D948933F0 00000000021A19F0 2     Ukn (Threadpool Worker) 
XXXX   22        0 00007F6B5C01F2C0  1031820 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn (Threadpool Worker) 
  12   35     2645 00007F6ACC002D60  1021220 Preemptive  00007F6D149F5358:00007F6D149F72C0 00000000021A19F0 0     Ukn (Threadpool Worker) 
  13   26     3253 00007F6B5C0FB430  1021220 Preemptive  00007F6C14349640:00007F6C1434A980 00000000021A19F0 0     Ukn (Threadpool Worker) 
  21   70     325e 00007F6AD80EB830  1021220 Preemptive  00007F6D942BE4B8:00007F6D942BF9E0 00000000021A19F0 0     Ukn (Threadpool Worker) 
  17   51     3259 00007F6B3000BD10  1021220 Preemptive  00007F6B937C9688:00007F6B937CA470 00000000021A19F0 0     Ukn (Threadpool Worker) 
  18   10     325a 00007F6AF816CA60  1021220 Preemptive  00007F6E14D1F740:00007F6E14D20F18 00000000021A19F0 0     Ukn (Threadpool Worker) 
  14   39     3254 00007F6B5C005140  1021220 Preemptive  00007F6D942B3DF0:00007F6D942B59E0 00000000021A19F0 0     Ukn (Threadpool Worker) 
  15   44     3255 00007F6B5C019650  1021220 Preemptive  00007F6D14E25510:00007F6D14E27160 00000000021A19F0 2     Ukn (Threadpool Worker) 
  19   62     325b 00007F6B4801BA20  1021220 Preemptive  00007F6D942B7ED8:00007F6D942B99E0 00000000021A19F0 0     Ukn (Threadpool Worker) 
  16   74     3256 00007F6B5C0228A0  1021220 Preemptive  00007F6C942530C8:00007F6C94253520 00000000021A19F0 0     Ukn (Threadpool Worker) 
  27   75     3264 00007F6AE0006F80  1021220 Preemptive  00007F6B939F59C0:00007F6B939F6CA0 00000000021A19F0 2     Ukn (Threadpool Worker) 
  22   32     325f 00007F6AE4003D70  1021220 Preemptive  00007F6B939E52F8:00007F6B939E6CA0 00000000021A19F0 2     Ukn (Threadpool Worker) 
  23   50     3260 00007F6B5800DB60  1021220 Preemptive  00007F6C942567F0:00007F6C942575D8 00000000021A19F0 0     Ukn (Threadpool Worker) 
  24   46     3261 00007F6B30003180  1021220 Preemptive  00007F6D942BAE50:00007F6D942BB9E0 00000000021A19F0 0     Ukn (Threadpool Worker) 
  25    4     3262 00007F6AF0000AD0  1021220 Preemptive  00007F6B937CC4C8:00007F6B937CE470 00000000021A19F0 0     Ukn (Threadpool Worker) 
  26   52     3263 00007F6AF801D3B0  1021220 Preemptive  0000000000000000:0000000000000000 00000000021A19F0 0     Ukn (Threadpool Worker) 
  20   57     325d 00007F6ACC000B00  1021220 Cooperative 00007F6C949DB000:00007F6C949DC7B8 00000000021A19F0 0     Ukn (Threadpool Worker) 
```

选择刚刚打印出来的占用cpu最高的线程模型16进制线程id前面的DBG，比如刚刚打印出来的`260d`,DBG为11

```bash
setthread 11
```

打印该线程的调用堆栈 可以查到问题代码行数以及方法、参数

```bash
>clrstack                                                                                                                                                                                                                                                                
OS Thread Id: 0x260d (11)
        Child SP               IP Call Site
00007F6B2CFF7B40 00007f6f7aee5b6d [InlinedCallFrame: 00007f6b2cff7b40] Interop+Sys.ReceiveMessage(System.Runtime.InteropServices.SafeHandle, MessageHeader*, System.Net.Sockets.SocketFlags, Int64*)
00007F6B2CFF7B40 00007f6f0185475b [InlinedCallFrame: 00007f6b2cff7b40] Interop+Sys.ReceiveMessage(System.Runtime.InteropServices.SafeHandle, MessageHeader*, System.Net.Sockets.SocketFlags, Int64*)
00007F6B2CFF7B30 00007F6F0185475B ILStubClass.IL_STUB_PInvoke(System.Runtime.InteropServices.SafeHandle, MessageHeader*, System.Net.Sockets.SocketFlags, Int64*)
00007F6B2CFF7BD0 00007F6F01860088 System.Net.Sockets.SocketPal.Receive(System.Net.Sockets.SafeSocketHandle, System.Net.Sockets.SocketFlags, System.Span`1<Byte>, Byte[], Int32 ByRef, System.Net.Sockets.SocketFlags ByRef, Error ByRef)
00007F6B2CFF7C80 00007F6F0185FED1 System.Net.Sockets.SocketPal.TryCompleteReceiveFrom(System.Net.Sockets.SafeSocketHandle, System.Span`1<Byte>, System.Collections.Generic.IList`1<System.ArraySegment`1<Byte>>, System.Net.Sockets.SocketFlags, Byte[], Int32 ByRef, Int32 ByRef, System.Net.Sockets.SocketFlags ByRef, System.Net.Sockets.SocketError ByRef)
00007F6B2CFF7CE0 00007F6F038CDCA1 System.Net.Sockets.SocketAsyncContext.ReceiveFrom(System.Memory`1<Byte>, System.Net.Sockets.SocketFlags ByRef, Byte[], Int32 ByRef, Int32, Int32 ByRef)
00007F6B2CFF7D80 00007F6F038CDAAD System.Net.Sockets.SocketPal.Receive(System.Net.Sockets.SafeSocketHandle, Byte[], Int32, Int32, System.Net.Sockets.SocketFlags, Int32 ByRef)
00007F6B2CFF7E20 00007F6F038CD7B6 System.Net.Sockets.Socket.Receive(Byte[], Int32, Int32, System.Net.Sockets.SocketFlags, System.Net.Sockets.SocketError ByRef)
00007F6B2CFF7E70 00007F6F038CD3D0 System.Net.Sockets.NetworkStream.Read(Byte[], Int32, Int32)
00007F6B2CFF7EC0 00007F6F04EE6480 System.Data.SqlClient.SNI.SNITCPHandle.Receive(System.Data.SqlClient.SNI.SNIPacket ByRef, Int32)
00007F6B2CFF7F20 00007F6F04EE622F System.Data.SqlClient.SNI.TdsParserStateObjectManaged.ReadSyncOverAsync(Int32, UInt32 ByRef)
00007F6B2CFF7F60 00007F6F04EE5FFE System.Data.SqlClient.TdsParserStateObject.ReadSniSyncOverAsync()
00007F6B2CFF7FE0 00007F6F04EE5F01 System.Data.SqlClient.TdsParserStateObject.TryReadNetworkPacket()
00007F6B2CFF8000 00007F6F04EEBB14 System.Data.SqlClient.TdsParserStateObject.TryPrepareBuffer()
00007F6B2CFF8020 00007F6F04ECD802 System.Data.SqlClient.TdsParserStateObject.TryReadByte(Byte ByRef)
00007F6B2CFF8040 00007F6F03943196 System.Data.SqlClient.TdsParser.TryRun(System.Data.SqlClient.RunBehavior, System.Data.SqlClient.SqlCommand, System.Data.SqlClient.SqlDataReader, System.Data.SqlClient.BulkCopySimpleResultSet, System.Data.SqlClient.TdsParserStateObject, Boolean ByRef)
00007F6B2CFF81B0 00007F6F04EF2065 System.Data.SqlClient.TdsParser.Run(System.Data.SqlClient.RunBehavior, System.Data.SqlClient.SqlCommand, System.Data.SqlClient.SqlDataReader, System.Data.SqlClient.BulkCopySimpleResultSet, System.Data.SqlClient.TdsParserStateObject)
00007F6B2CFF81F0 00007F6F04F03012 System.Data.SqlClient.SqlBulkCopy.RunParser(System.Data.SqlClient.BulkCopySimpleResultSet)
00007F6B2CFF8230 00007F6F04F38854 System.Data.SqlClient.SqlBulkCopy.CreateAndExecuteInitialQueryAsync(System.Data.SqlClient.BulkCopySimpleResultSet ByRef)
00007F6B2CFF8270 00007F6F04F3849C System.Data.SqlClient.SqlBulkCopy.WriteToServerInternalRestAsync(System.Threading.CancellationToken, System.Threading.Tasks.TaskCompletionSource`1<System.Object>)
00007F6B2CFF8300 00007F6F04F37CD0 System.Data.SqlClient.SqlBulkCopy.WriteToServerInternalAsync(System.Threading.CancellationToken)
00007F6B2CFF8340 00007F6F04F37775 System.Data.SqlClient.SqlBulkCopy.WriteRowSourceToServerAsync(Int32, System.Threading.CancellationToken)
00007F6B2CFF8390 00007F6F04F373AF System.Data.SqlClient.SqlBulkCopy.WriteToServer(System.Data.DataTable, System.Data.DataRowState)
00007F6B2CFF83F0 00007F6F04EC06F3 Hyd.Commons.DbHelpers.SqlHelper.BulkCopy[[System.__Canon, System.Private.CoreLib]](System.Collections.Generic.List`1<System.__Canon>, System.String)
00007F6B2CFF84F0 00007F6F0396A403 Hyd.CDC.DataAccessLayer.efoscollectdata.HistoryDeviceParameterDataDAL.SaveDeviceData(System.Collections.Generic.List`1<Hyd.CDC.DataAccessLayer.efoscollectdata.Models.DeviceParams>) [/var/www/gitlab/p02-datacollect/code/p02-solution/Hyd.CDC.DataAccessLayer/efoscollectdata/HistoryDeviceParameterDataDAL.cs @ 39]
00007F6B2CFF8580 00007F6F03924E8D Hyd.CDC.ComputeServices.ObjectHistory.BLL.HistoryBLL+<>c__DisplayClass7_0.<SaveDeviceData>b__0(System.Object) [/var/www/gitlab/p02-datacollect/code/p02-solution/Hyd.CDC.ComputeServices.ObjectHistory/BLL/HistoryBLL.cs @ 157]
00007F6B2CFF8840 00007F6F04F0CEF1 System.Threading.ExecutionContext.RunFromThreadPoolDispatchLoop(System.Threading.Thread, System.Threading.ExecutionContext, System.Threading.ContextCallback, System.Object)
00007F6B2CFF8880 00007F6F04F0BC0C System.Threading.Tasks.Task.ExecuteWithThreadLocal(System.Threading.Tasks.Task ByRef, System.Threading.Thread)
00007F6B2CFF8900 00007F6F0185F2A9 System.Threading.ThreadPoolWorkQueue.Dispatch()
00007F6B2CFF8D10 00007f6f796f45ef [DebuggerU2MCatchHandlerFrame: 00007f6b2cff8d10]
```

加入-a可以查看方法参数

```bash
> clrstack -a                                                                                                                                                                                                                                                             
OS Thread Id: 0x260d (11)
        Child SP               IP Call Site
00007F6B2CFF7B40 00007f6f7aee5b6d [InlinedCallFrame: 00007f6b2cff7b40] Interop+Sys.ReceiveMessage(System.Runtime.InteropServices.SafeHandle, MessageHeader*, System.Net.Sockets.SocketFlags, Int64*)
00007F6B2CFF7B40 00007f6f0185475b [InlinedCallFrame: 00007f6b2cff7b40] Interop+Sys.ReceiveMessage(System.Runtime.InteropServices.SafeHandle, MessageHeader*, System.Net.Sockets.SocketFlags, Int64*)
00007F6B2CFF7B30 00007F6F0185475B ILStubClass.IL_STUB_PInvoke(System.Runtime.InteropServices.SafeHandle, MessageHeader*, System.Net.Sockets.SocketFlags, Int64*)
    PARAMETERS:
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF7BD0 00007F6F01860088 System.Net.Sockets.SocketPal.Receive(System.Net.Sockets.SafeSocketHandle, System.Net.Sockets.SocketFlags, System.Span`1<Byte>, Byte[], Int32 ByRef, System.Net.Sockets.SocketFlags ByRef, Error ByRef)
    PARAMETERS:
        socket = <no data>
        flags = <no data>
        buffer = <no data>
        socketAddress = <no data>
        socketAddressLen = <no data>
        receivedFlags = <no data>
        errno = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF7C80 00007F6F0185FED1 System.Net.Sockets.SocketPal.TryCompleteReceiveFrom(System.Net.Sockets.SafeSocketHandle, System.Span`1<Byte>, System.Collections.Generic.IList`1<System.ArraySegment`1<Byte>>, System.Net.Sockets.SocketFlags, Byte[], Int32 ByRef, Int32 ByRef, System.Net.Sockets.SocketFlags ByRef, System.Net.Sockets.SocketError ByRef)
    PARAMETERS:
        socket = <no data>
        buffer = <no data>
        buffers = <no data>
        flags = <no data>
        socketAddress = <no data>
        socketAddressLen = <no data>
        bytesReceived = <no data>
        receivedFlags = <no data>
        errorCode = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF7CE0 00007F6F038CDCA1 System.Net.Sockets.SocketAsyncContext.ReceiveFrom(System.Memory`1<Byte>, System.Net.Sockets.SocketFlags ByRef, Byte[], Int32 ByRef, Int32, Int32 ByRef)
    PARAMETERS:
        this = <no data>
        buffer = <no data>
        flags = <no data>
        socketAddress = <no data>
        socketAddressLen = <no data>
        timeout = <no data>
        bytesReceived = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF7D80 00007F6F038CDAAD System.Net.Sockets.SocketPal.Receive(System.Net.Sockets.SafeSocketHandle, Byte[], Int32, Int32, System.Net.Sockets.SocketFlags, Int32 ByRef)
    PARAMETERS:
        handle = <no data>
        buffer = <no data>
        offset = <no data>
        count = <no data>
        socketFlags = <no data>
        bytesTransferred = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>

00007F6B2CFF7E20 00007F6F038CD7B6 System.Net.Sockets.Socket.Receive(Byte[], Int32, Int32, System.Net.Sockets.SocketFlags, System.Net.Sockets.SocketError ByRef)
    PARAMETERS:
        this = <no data>
        buffer = <no data>
        offset = <no data>
        size = <no data>
        socketFlags = <no data>
        errorCode = <no data>
    LOCALS:
        <no data>

00007F6B2CFF7E70 00007F6F038CD3D0 System.Net.Sockets.NetworkStream.Read(Byte[], Int32, Int32)
    PARAMETERS:
        this = <no data>
        buffer = <no data>
        offset = <no data>
        size = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>

00007F6B2CFF7EC0 00007F6F04EE6480 System.Data.SqlClient.SNI.SNITCPHandle.Receive(System.Data.SqlClient.SNI.SNIPacket ByRef, Int32)
    PARAMETERS:
        this = <no data>
        packet = <no data>
        timeoutInMilliseconds = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF7F20 00007F6F04EE622F System.Data.SqlClient.SNI.TdsParserStateObjectManaged.ReadSyncOverAsync(Int32, UInt32 ByRef)
    PARAMETERS:
        this = <no data>
        timeoutRemaining = <no data>
        error = <no data>
    LOCALS:
        <no data>
        <no data>

00007F6B2CFF7F60 00007F6F04EE5FFE System.Data.SqlClient.TdsParserStateObject.ReadSniSyncOverAsync()
    PARAMETERS:
        this = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>

00007F6B2CFF7FE0 00007F6F04EE5F01 System.Data.SqlClient.TdsParserStateObject.TryReadNetworkPacket()
    PARAMETERS:
        this = <no data>

00007F6B2CFF8000 00007F6F04EEBB14 System.Data.SqlClient.TdsParserStateObject.TryPrepareBuffer()
    PARAMETERS:
        this = <no data>

00007F6B2CFF8020 00007F6F04ECD802 System.Data.SqlClient.TdsParserStateObject.TryReadByte(Byte ByRef)
    PARAMETERS:
        this = <no data>
        value = <no data>
    LOCALS:
        <no data>

00007F6B2CFF8040 00007F6F03943196 System.Data.SqlClient.TdsParser.TryRun(System.Data.SqlClient.RunBehavior, System.Data.SqlClient.SqlCommand, System.Data.SqlClient.SqlDataReader, System.Data.SqlClient.BulkCopySimpleResultSet, System.Data.SqlClient.TdsParserStateObject, Boolean ByRef)
    PARAMETERS:
        this (<CLR reg>) = 0x00007f6c127a6338
        runBehavior = <no data>
        cmdHandler (<CLR reg>) = 0x0000000000000000
        dataStream (<CLR reg>) = 0x0000000000000000
        bulkCopyHandler (<CLR reg>) = 0x00007f6d94891a88
        stateObj (<CLR reg>) = 0x00007f6c127a63d0
        dataReady (<CLR reg>) = 0xfffffffffffffffc
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF81B0 00007F6F04EF2065 System.Data.SqlClient.TdsParser.Run(System.Data.SqlClient.RunBehavior, System.Data.SqlClient.SqlCommand, System.Data.SqlClient.SqlDataReader, System.Data.SqlClient.BulkCopySimpleResultSet, System.Data.SqlClient.TdsParserStateObject)
    PARAMETERS:
        this = <no data>
        runBehavior = <no data>
        cmdHandler = <no data>
        dataStream = <no data>
        bulkCopyHandler = <no data>
        stateObj = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF81F0 00007F6F04F03012 System.Data.SqlClient.SqlBulkCopy.RunParser(System.Data.SqlClient.BulkCopySimpleResultSet)
    PARAMETERS:
        this = <no data>
        bulkCopyHandler = <no data>
    LOCALS:
        <no data>

00007F6B2CFF8230 00007F6F04F38854 System.Data.SqlClient.SqlBulkCopy.CreateAndExecuteInitialQueryAsync(System.Data.SqlClient.BulkCopySimpleResultSet ByRef)
    PARAMETERS:
        this = <no data>
        result = <no data>
    LOCALS:
        <no data>
        <no data>

00007F6B2CFF8270 00007F6F04F3849C System.Data.SqlClient.SqlBulkCopy.WriteToServerInternalRestAsync(System.Threading.CancellationToken, System.Threading.Tasks.TaskCompletionSource`1<System.Object>)
    PARAMETERS:
        this = <no data>
        cts = <no data>
        source = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF8300 00007F6F04F37CD0 System.Data.SqlClient.SqlBulkCopy.WriteToServerInternalAsync(System.Threading.CancellationToken)
    PARAMETERS:
        this = <no data>
        ctoken = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF8340 00007F6F04F37775 System.Data.SqlClient.SqlBulkCopy.WriteRowSourceToServerAsync(Int32, System.Threading.CancellationToken)
    PARAMETERS:
        this = <no data>
        columnCount = <no data>
        ctoken = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF8390 00007F6F04F373AF System.Data.SqlClient.SqlBulkCopy.WriteToServer(System.Data.DataTable, System.Data.DataRowState)
    PARAMETERS:
        this = <no data>
        table = <no data>
        rowState = <no data>
    LOCALS:
        <no data>

00007F6B2CFF83F0 00007F6F04EC06F3 Hyd.Commons.DbHelpers.SqlHelper.BulkCopy[[System.__Canon, System.Private.CoreLib]](System.Collections.Generic.List`1<System.__Canon>, System.String)
    PARAMETERS:
        this (0x00007F6B2CFF84C0) = 0x00007f6d9487a5c0
        data (0x00007F6B2CFF84B0) = 0x00007f6d9487a638
        tableName (0x00007F6B2CFF84A8) = 0x00007f6e12e45658
    LOCALS:
        0x00007F6B2CFF84A0 = 0x00007f6d9488b050
        0x00007F6B2CFF8498 = 0x00007f6d94891348
        0x00007F6B2CFF8490 = 0x00007f6d9488c0b0
        0x00007F6B2CFF8488 = 0x0000000000000000
        0x00007F6B2CFF8484 = 0x0000000000000000

00007F6B2CFF84F0 00007F6F0396A403 Hyd.CDC.DataAccessLayer.efoscollectdata.HistoryDeviceParameterDataDAL.SaveDeviceData(System.Collections.Generic.List`1<Hyd.CDC.DataAccessLayer.efoscollectdata.Models.DeviceParams>) [/var/www/gitlab/p02-datacollect/code/p02-solution/Hyd.CDC.DataAccessLayer/efoscollectdata/HistoryDeviceParameterDataDAL.cs @ 39]
    PARAMETERS:
        this (0x00007F6B2CFF8560) = 0x00007f6d9487a520
        models (0x00007F6B2CFF8558) = 0x00007f6d94872c08
    LOCALS:
        0x00007F6B2CFF8550 = 0x00007f6d9487a5c0
        0x00007F6B2CFF8548 = 0x00007f6d9487a638

00007F6B2CFF8580 00007F6F03924E8D Hyd.CDC.ComputeServices.ObjectHistory.BLL.HistoryBLL+<>c__DisplayClass7_0.<SaveDeviceData>b__0(System.Object) [/var/www/gitlab/p02-datacollect/code/p02-solution/Hyd.CDC.ComputeServices.ObjectHistory/BLL/HistoryBLL.cs @ 157]
    PARAMETERS:
        this (0x00007F6B2CFF8820) = 0x00007f6c12cf9c90
        p (0x00007F6B2CFF8818) = 0x00007f6d92f6a8a0
    LOCALS:
        0x00007F6B2CFF8810 = 0x00007f6d92f6a8a0
        0x00007F6B2CFF8808 = 0x00007f6d94872c08
        0x00007F6B2CFF87F0 = 0x00007f6d92f6a8c0
        0x00007F6B2CFF87E8 = 0x00007f6d9487a1a0
        0x00007F6B2CFF87E0 = 0x00007f6d9487a240
        0x00007F6B2CFF87D8 = 0x00007f6d938b7748
        0x00007F6B2CFF87D0 = 0x00007f6d9487a3c8
        0x00007F6B2CFF87CC = 0x0000000000000001
        0x00007F6B2CFF87C0 = 0x0000000000000000
        0x00007F6B2CFF87B8 = 0x0000000000003f56
        0x00007F6B2CFF87B0 = 0x00007f6d9487a460
        0x00007F6B2CFF87AC = 0x0000000000000001
        0x00007F6B2CFF87A0 = 0x0000000000000000

00007F6B2CFF8840 00007F6F04F0CEF1 System.Threading.ExecutionContext.RunFromThreadPoolDispatchLoop(System.Threading.Thread, System.Threading.ExecutionContext, System.Threading.ContextCallback, System.Object)
    PARAMETERS:
        threadPoolThread = <no data>
        executionContext = <no data>
        callback = <no data>
        state = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF8880 00007F6F04F0BC0C System.Threading.Tasks.Task.ExecuteWithThreadLocal(System.Threading.Tasks.Task ByRef, System.Threading.Thread)
    PARAMETERS:
        this = <no data>
        currentTaskSlot = <no data>
        threadPoolThread = <no data>
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF8900 00007F6F0185F2A9 System.Threading.ThreadPoolWorkQueue.Dispatch()
    LOCALS:
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>
        <no data>

00007F6B2CFF8D10 00007f6f796f45ef [DebuggerU2MCatchHandlerFrame: 00007f6b2cff8d10] 
```

使用`dumpobj`可以查看到方法参数,这里可以看到 projectId = 993

```bash
> dumpobj 0x00007f6d9487a520                                                                                                                                                                                                                                              
Name:        Hyd.CDC.DataAccessLayer.efoscollectdata.HistoryDeviceParameterDataDAL
MethodTable: 00007f6f04dec800
EEClass:     00007f6f04dfed10
Size:        24(0x18) bytes
File:        /var/www/gitlab/Hyd.CDC.ComputeServices.ObjectHistory/Hyd.CDC.DataAccessLayer.dll
Fields:
              MT    Field   Offset                 Type VT     Attr            Value Name
00007f6f00370f90  4000026        8        System.String  0 instance 00007f6c127a3eb0 <ConnectionString>k__BackingField
> dumpobj 0x00007f6d94872c08                                                                                                                                                                                                                                              
Name:        System.Collections.Generic.List`1[[Hyd.CDC.DataAccessLayer.efoscollectdata.Models.DeviceParams, Hyd.CDC.DataAccessLayer]]
MethodTable: 00007f6f04deb478
EEClass:     00007f6f003e6fa0
Size:        32(0x20) bytes
File:        /usr/share/dotnet/shared/Microsoft.NETCore.App/3.1.4/System.Private.CoreLib.dll
Fields:
              MT    Field   Offset                 Type VT     Attr            Value Name
00007f6f0095ee00  4001b10        8     System.__Canon[]  0 instance 00007f6d94878970 _items
00007f6f0036a0e8  4001b11       10         System.Int32  1 instance               42 _size
00007f6f0036a0e8  4001b12       14         System.Int32  1 instance               42 _version
00007f6f0095ee00  4001b13        8     System.__Canon[]  0   static dynamic statics NYI                 s_emptyArray
> dumpobj 0x00007f6d92f6a8a0                                                                                                                                                                                                                                              
Name:        Hyd.CDC.ComputeServices.ObjectHistory.BLL.ProjectDeviceCache
MethodTable: 00007f6f02387668
EEClass:     00007f6f0230fb58
Size:        32(0x20) bytes
File:        /var/www/gitlab/Hyd.CDC.ComputeServices.ObjectHistory/Hyd.CDC.ComputeServices.ObjectHistory.dll
Fields:
              MT    Field   Offset                 Type VT     Attr            Value Name
00007f6f0036a0e8  4000007       10         System.Int32  1 instance              993 <ProjectId>k__BackingField
00007f6f024d8170  4000008        8 ...Private.CoreLib]]  0 instance 00007f6d92f6a8c0 <DeviceIds>k__BackingField

```



[使用dotnet-dump 查找 .net core 3.0 占用CPU 100%的原因](https://blog.csdn.net/ma_jiang/article/details/93631472)
[vs调试dump](https://blog.csdn.net/qq_33630104/article/details/106498400)