--首先更新摄像头类型
update project_camera set CameraType = 6001 where CameraType = 1;
update project_camera set CameraType = 6000 where CameraType = 2;
update project_camera set CameraType = 6002 where CameraType = 3;
update project_camera set CameraType = 6004 where CameraType is null;



go
declare @cameraId varchar(100);
declare @areaId int;
declare @projectId int;
declare @cameraName varchar(100);
declare @cameraType varchar(100);
declare @use int;
declare @liveUrl varchar(500);
declare @sort int;
declare @longitude varchar(100);
declare @latitude varchar(100);
declare @coverUrl varchar(100);
declare @remark varchar(100);
declare @state int;
declare @position int;
declare @isOnline bit;

declare @autoId int;

DECLARE cursor_1 CURSOR FOR --定义游标
	select * From project_camera
OPEN cursor_1 --打开游标
FETCH NEXT FROM cursor_1 INTO @CameraId,@areaId,@projectId, @cameraName,@cameraType,@use,@liveUrl,@sort,@longitude,@latitude,@coverUrl,@remark,@state,@position,@isOnline --抓取下一行游标数据
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @cameraId
	PRINT @areaId
	PRINT @projectId
	PRINT @cameraName
	PRINT @cameraType
	PRINT @use
	PRINT @liveUrl
	PRINT @sort
	PRINT @longitude
	PRINT @latitude
	PRINT @coverUrl
	PRINT @remark
	PRINT @state
	PRINT @position
	PRINT @isOnline

	INSERT INTO [efoscore].[dbo].[iot] (IotCode,AreaId,ProjectId,IotName,IotType,IotModel,IotUse,LiveUrl,Sort,Longitude,Latitude,Remark,State,Position,IsMonitor)
		VALUES (@cameraId,@areaId,@projectId,@cameraName,4,@cameraType,@use,@liveUrl,@sort,@longitude,@latitude,@remark,@state,@position,0);

	set @autoId =  @@identity
	--PRINT '自增id:'
	--PRINT @autoId

	INSERT INTO [efoscore].[dbo].iot_realtime(IotId,IsOnline)
		VALUES (@autoId,@isOnline)
	

	FETCH NEXT FROM cursor_1 INTO @CameraId,@areaId,@projectId, @cameraName,@cameraType,@use,@liveUrl,@sort,@longitude,@latitude,@coverUrl,@remark,@state,@position,@isOnline
END
CLOSE cursor_1 --关闭游标
DEALLOCATE cursor_1 --释放游标
go

go
-- 删除外键约束
alter table project_control_condition_camera drop constraint FK_Reference_70;

alter table project_device_param_alarm_camera drop constraint FK_Reference_74;
--给另外两张表替换数据
go
declare @temp int;
DECLARE @ConditionId int,@CameraId int
DECLARE cursor_1 CURSOR FOR --定义游标
	select * From project_control_condition_camera
OPEN cursor_1 --打开游标
FETCH NEXT FROM cursor_1 INTO  @ConditionId,@CameraId  --抓取下一行游标数据
WHILE @@FETCH_STATUS = 0
BEGIN
    --PRINT @ConditionId
	--PRINT @CameraId

	--取到数据  
	select @temp = IotId From [iot] where IotCode = @CameraId;
	--更新数据
	update project_control_condition_camera set CameraId = @temp where ConditionId = @ConditionId and CameraId = @CameraId;

    FETCH NEXT FROM cursor_1 INTO @ConditionId,@CameraId
END
CLOSE cursor_1 --关闭游标
DEALLOCATE cursor_1 --释放游标
---第二张表
DECLARE @Id varchar(36)
DECLARE cursor_2 CURSOR FOR --定义游标
	select * From project_device_param_alarm_camera
OPEN cursor_2 --打开游标
FETCH NEXT FROM cursor_2 INTO  @Id,@CameraId  --抓取下一行游标数据
WHILE @@FETCH_STATUS = 0
BEGIN
    --PRINT @Id
	--PRINT @CameraId

	--取到数据  
	select @temp = IotId From [iot] where IotCode = @CameraId;
	--更新数据
	update project_device_param_alarm_camera set CameraId = @temp where Id = @Id and CameraId = @CameraId;

    FETCH NEXT FROM cursor_2 INTO @Id,@CameraId
END
CLOSE cursor_2 --关闭游标
DEALLOCATE cursor_2 --释放游标

go
ALTER TABLE [dbo].[project_control_condition_camera] ADD CONSTRAINT [FK_Reference_70] FOREIGN KEY ([CameraId]) REFERENCES [dbo].[iot] (IotId) ON DELETE NO ACTION ON UPDATE NO ACTION

ALTER TABLE [dbo].[project_device_param_alarm_camera] ADD CONSTRAINT [FK_Reference_74] FOREIGN KEY ([CameraId]) REFERENCES [dbo].[iot] (IotId) ON DELETE NO ACTION ON UPDATE NO ACTION