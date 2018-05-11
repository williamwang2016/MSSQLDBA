SELECT * FROM msdb.dbo.view_ddl WHERE is_completed = 0 ORDER BY id
select * from msdb.dbo.ddl_event
truncate table msdb.dbo.ddl_event

:connect lvs1-ieodn-001
--delete from demo.dbo.t1
insert into demo.dbo.t1 values (1)
go
select count(*) from demo.dbo.t1
go

:connect lvs1-ieodn-002
select count(*) from demo.dbo.t1
go

select * from msdb.dbo.ddl_event

:connect lvs1-ieodn-001
--delete from demo.dbo.t1
insert into demo.testch.t3 values (2, 'b')
go
select * from demo.testch.t3
go

:connect lvs1-ieodn-002
select * from demo.testch.t3
go


SELECT id
, is_completed
, completion_time
, event_data.value('(/EVENT_INSTANCE/EventType)[1]','nvarchar(max)') as event_type
, event_data.value('(/EVENT_INSTANCE/DatabaseName)[1]','nvarchar(max)') as database_name
, event_data.value('(/EVENT_INSTANCE/SchemaName)[1]','nvarchar(max)') as schema_name
, event_data.value('(/EVENT_INSTANCE/ObjectName)[1]','nvarchar(max)') as object_name
, event_data.value('(/EVENT_INSTANCE/ObjectType)[1]','nvarchar(max)') as object_type
, event_data.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)') as ddl_command

FROM msdb.dbo.ddl_event
