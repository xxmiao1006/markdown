## ef core

### ef core性能问题

- 在表达式没有完全写完的情况下，不能使用ToList来加载数据，否则容易导致许多表还没关联筛选就被全表查询导入内存
- 在查询的时候不要对where条件的参数进行插表查询，再次关联表时候又扫一次表性能很低
- 所有关联的表信息尽量在where条件前进行关联，where条件后进行筛选

### sqlserver

查询历史执行sql记录

```sql
SELECT     TOP 1000 QS.creation_time, SUBSTRING(ST.text, (QS.statement_start_offset / 2) + 1,
                      ((CASE QS.statement_end_offset WHEN - 1 THEN DATALENGTH(st.text) ELSE QS.statement_end_offset END - QS.statement_start_offset) / 2) + 1)
                      AS statement_text, ST.text, QS.total_worker_time, QS.last_worker_time, QS.max_worker_time, QS.min_worker_time
FROM         sys.dm_exec_query_stats QS CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) ST
WHERE     QS.creation_time BETWEEN '2019-11-27 0:00:00' AND '2019-11-27 16:00:00' AND ST.text LIKE 'Delete%%'
ORDER BY QS.creation_time DESC
```

查看sqlserver现有链接数

```sql
select count(distinct(login_time)) from sys.sysprocesses
```

sqlserver最大链接数

```sql
SELECT value_in_use
FROM sys.configurations c
WHERE c.name = 'user connections';
```

查询某一个表的字段和数据类型

```mssql
select data_type,column_name 
from information_schema.columns
where table_name = 'iot'
```

```sql
--1.按姓氏笔画排序:
Select * From TableName Order By CustomerName Collate Chinese_PRC_Stroke_ci_as

--8.如何修改数据库的名称:

sp_renamedb 'old_name', 'new_name' 

--9：获取当前数据库中的所有用户表
select Name from sysobjects where xtype='u' and status>=0

--10：获取某一个表的所有字段
select name from syscolumns where id=object_id('表名')

--11：查看与某一个表相关的视图、存储过程、函数
select a.* from sysobjects a, syscomments b where a.id = b.id and b.text like '%表名%'

--12：查看当前数据库中所有存储过程
select name as 存储过程名称 from sysobjects where xtype='P'

--13：查询用户创建的所有数据库
select * from master..sysdatabases D where sid not in(select sid from master..syslogins where name='sa')
--或者
select dbid, name AS DB_NAME from master..sysdatabases where sid <> 0x01

--14：查询某一个表的字段和数据类型
select column_name,data_type from information_schema.columns
where table_name = '表名'

```



### efcore 池化

```c#
//services.AddDbContext<efosiotContext>(options => options.UseSqlServer(EnviVariableHelper.hyd_db_efosiot));

 services.AddDbContextPool<efosiotContext>(options => options.UseSqlServer(EnviVariableHelper.hyd_db_efosiotdata), poolSize: 128);
```

连接池的最大数量要小于数据库的最大连接数

注意:池化的dbcontext有且只能有一个包含DbContextOptions参数的构造函数，否则在提示池化失败

```c#
System.InvalidOperationException: The DbContext of type 'efosiotContext' cannot be pooled because it does not have a single public constructor accepting a single parameter of type DbContextOptions.
```

```c#
var result = Parallel.For(0, 100, (i, state) =>
            {
                Console.WriteLine("i:{0}, thread id: {1}", i, Thread.CurrentThread.ManagedThreadId);

                var data = client.IotGetList(new IotGetListRequest { SelectType = 1 });

                //var reply = client.SayHelloAsync(new HelloRequest { Name = "grpc---" + Thread.CurrentThread.ManagedThreadId, Sleep = 15000 }, new Metadata { { "header", "11" } });
                //Console.WriteLine("Greeter 服务返回数据: " + reply.ResponseAsync.Result.Message);
                //if (i > 10)
                //    state.Break();

                //Thread.Sleep(10);
            });
```



[dbcontext为何只能有一个包含dbContextOptions参数的构造函数](https://blog.csdn.net/sD7O95O/article/details/105548002)

[ef core异步](https://docs.microsoft.com/zh-cn/dotnet/csharp/programming-guide/concepts/async/)

[asp.net core中使用efcore](https://docs.microsoft.com/zh-cn/aspnet/core/data/ef-rp/intro?view=aspnetcore-3.1&tabs=visual-studio)

[c# 异步](https://docs.microsoft.com/zh-cn/dotnet/csharp/programming-guide/concepts/async/)

