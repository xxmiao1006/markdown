## MySQL日志





7. MySQL为什么要有redo log和binlog两份日志系统？为什么binlog没有crash-safe能力？

​      只有两份日记才有crash-safe功能 为什么binlog不能做到crash-safe？ 假如只有binlog，有可能先提交事务再写binlog，有可能事务提交数据更新之后数据库崩了，还没来得及写binlog。我们都知道binlog一般用来做数据库的主从复制或恢复数据库，这样就导致主从数据库不一致或者无法恢复数据库了。同样即使先写binlog再提交事务更新数据库，还是有可能写binlog成功之后数据库崩掉而导致数据库更新失败，这样也会导致主从数据库不一致或者无法恢复数据库。所以只有binlog做不到crash-safe。为了支持crash-safe，需要redolog，而且为了保证逻辑一致，事务提交需要两个阶段：prepare阶段和commit阶段。写redolog并落入磁盘(prepare状态)-->写binlog-->commit。commit的时候是不会落盘的。 

​    1 prepare阶段 2 写binlog 3 commit 当在2之前崩溃时 重启恢复：后发现没有commit，回滚。备份恢复：没有binlog 。 一致 当在3之前崩溃 重启恢复：虽没有commit，但满足prepare和binlog完整，所以重启后会自动commit。备份：有binlog(怎么检查有binlog呢?). 一致 疑问: 如果要检查binlog，那prepare存在的意义是什么，我直接检验binlog的完整性就可以了。任何涉及两个系统提交的任务都会存在不一致的可能性，而且这种可能性无法完全消除，只能减少这种风险，prepare机制是把写binlog时间段的风险降低到commit更低时间段，从而降低不一致的风险，分布式事务也是同理，不管怎么设计，都是存在不一致风险的 解答: binlog 只记录逻辑操作，并无操作状态，即无法确定该操作是否完成。redo log是有状态的，所以没办法直接检查binlog。只有在redo log状态为prepare时，才会去检查binlog是否存在，否则只校验redo log是否是 commit就可以啦。 怎么检查binlog: 一个完整事物binlog结尾有固定的格式.

**我再来说下自己的理解 。**

**1 prepare阶段 2 写binlog 3 commit**
**当在2之前崩溃时**
**重启恢复：后发现没有commit，回滚。备份恢复：没有binlog 。**
**一致**
**当在3之前崩溃**
**重启恢复：虽没有commit，但满足prepare和binlog完整，所以重启后会自动commit。备份：有binlog. 一致**

​		这两种日志有以下三点不同。

redo log 是 InnoDB 引擎特有的；binlog 是 MySQL 的 Server 层实现的，所有引擎都可以使用。

redo log 是物理日志，记录的是“在某个数据页上做了什么修改”；binlog 是逻辑日志，记录的是这个语句的原始逻辑，比如“给 ID=2 这一行的 c 字段加 1 ”。

redo log 是循环写的，空间固定会用完；binlog 是可以追加写入的。“追加写”是指 binlog 文件写到一定大小后会切换到下一个，并不会覆盖以前的日志。

​       写入方式的问题，binlog是追加写，crash时不能判定binlog中哪些内容是已经写入到磁盘，哪些还没被写入。而redolog是循环写，从check point到write pos间的内容都是未写入到磁盘的。







重点：

   1. redo log的概念是什么? 为什么会存在.
      2. 什么是WAL(write-ahead log)机制, 好处是什么.
      3. redo log 为什么可以保证crash safe机制.
      4. binlog的概念是什么, 起到什么作用, 可以做crash safe吗?
      5. binlog和redolog的不同点有哪些?
      6. 物理一致性和逻辑一直性各应该怎么理解?
      7. 执行器和innoDB在执行update语句时候的流程是什么样的?
      8. 如果数据库误操作, 如何执行数据恢复?
      9. 什么是两阶段提交, 为什么需要两阶段提交, 两阶段提交怎么保证数据库中两份日志间的逻辑一致性(什么叫逻辑一致性)?
          10. 如果不是两阶段提交, 先写redo log和先写bin log两种情况各会遇到什么问题?



1. redo log是重做日志。主要用于MySQL异常重启后的一种数据恢复手段，确保了数据的一致性。归根到底是MySQL为了实现WAL机制的一种手段。因为MySQL进行更新操作，为了能够快速响应，所以采用了异步写回磁盘的技术，写入内存后就返回。但是会存在crash后内存数据丢失的隐患，而redo log具备crash safe能力。
2. WAL机制是写前日志，也就是MySQL更新操作后在真正把数据写入到磁盘前先记录日志。好处是不用每一次操作都实时把数据写盘，就算crash后也可以通过redo log重放恢复，所以能够实现快速响应SQL语句。
3. 因为redo log是每次更新操作完成后，就一定会写入的，如果写入失败，这说明此次操作失败，事务也不可能提交。redo log内部结构是基于页的，记录了这个页的字段值变化，只要crash后读取redo log进行重放就可以恢复数据。（因为redo log是循环写的，如果满了InnoDB就会执行真正写盘）
4. bin log是归档日志，属于MySQL Server层的日志。可以起到全量备份的作用。当需要恢复数据时，可以取出某个时间范围内的bin log进行重放恢复。但是bin log不可以做crash safe，因为crash之前，bin log可能没有写入完全MySQL就挂了。所以需要配合redo log才可以进行crash safe。
5. bin log是Server层，追加写，不会覆盖，记录了逻辑变化，是逻辑日志。redo log是存储引擎层，是InnoDB特有的。循环写，满了就覆盖从头写，记录的是基于页的物理变化，是物理日志，具备crash safe操作。
6. 前者是数据的一致性，后者是行为一致性。（不清楚）
7. 执行器在优化器选择了索引后，调用InnoDB读接口，读取要更新的行到内存中，执行SQL操作后，更新到内存，然后写redo log，写bin log，此时即为完成。后续InnoDB会在合适的时候把此次操作的结果写回到磁盘。
8. 数据库在某一天误操作，就可以找到距离误操作最近的时间节点前的bin log，重放到临时数据库里，然后选择当天误删的数据恢复到线上数据库。
9. 两阶段提交就是对于三步操作而言：1.prepare阶段 2. 写入bin log 3. commit
redo log在写入后，进入prepare状态，然后bin log写入后，进入commit状态，事务可以提交。
如果不用两阶段提交的话，可能会出现bin log写入之前，机器crash导致重启后redo log继续重放crash之前的操作，而当bin log后续需要作为备份恢复时，会出现数据不一致的情况。所以需要对redo log进行回滚。
如果是bin log commit之前crash，那么重启后，发现redo log是prepare状态且bin log完整（bin log写入成功后，redo log会有bin log的标记），就会自动commit，让存储引擎提交事务。
10.先写redo log，crash后bin log备份恢复时少了一次更新，与当前数据不一致。先写bin log，crash后，由于redo log没写入，事务无效，所以后续bin log备份恢复时，数据不一致。





binlog为什么说是逻辑日志呢？它里面有内容也会存储成物理文件，怎么说是逻辑而不是物理

作者回复: 这样理解哈。

逻辑日志可以给别的数据库，别的引擎使用，已经大家都讲得通这个“逻辑”；

物理日志就只有“我”自己能用，别人没有共享我的“物理格式”





系统表空间就是用来放系统信息的，比如数据字典什么的，对应的磁盘文件是ibdata1,
数据表空间就是一个个的表数据文件，对应的磁盘文件就是 表名.ibd





  在源实例上
vi my.table
XXXX.table1

xtrabackup --defaults-file=/home/meinian/data/backup-my.cnf --tables-file='XXXX.table1' --backup --target-dir=/home/meinian/data/0111backuptest
下载对应文件ibd文件，需要复制到需要备份的文件目录

在目标实例
首先创建一个一模一样的表
alter table table1 discard tablespace;
上传文件，主要使用mysql账户进行操作
alter table table1 import tablespace;

select count(1) from table1; -- 测试数据是否正常  