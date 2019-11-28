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

