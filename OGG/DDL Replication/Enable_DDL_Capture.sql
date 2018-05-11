--Create tracking table in msdb and grant INSERT permission to the public role on this table
USE [msdb]
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ddl_event')
	DROP TABLE [dbo].[ddl_event]
GO
CREATE TABLE [dbo].[ddl_event](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[is_completed] [bit] NOT NULL,
	[completion_time] [datetime] NULL,
	[event_data] [xml] NULL,
 CONSTRAINT [PK_ddl_event] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ddl_event] ADD  CONSTRAINT [DF_ddl_event_is_completed]  DEFAULT ((0)) FOR [is_completed]
GO
GRANT INSERT ON OBJECT::dbo.ddl_event to public
GO

USE [msdb]
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'view_ddl')
	DROP VIEW [dbo].[view_ddl]
GO
CREATE VIEW view_ddl
AS
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
GO


--Create a database level DDL trigger
--For more type of events, refer to 
--https://docs.microsoft.com/en-us/sql/relational-databases/triggers/ddl-event-groups?view=sql-server-2017
USE [Demo]
GO

CREATE TRIGGER [catpure_ddl]
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
if EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]','nvarchar(max)') NOT IN ('ogg','cdc') AND EVENTDATA().value('(/EVENT_INSTANCE/UserName)[1]','nvarchar(max)') <> 'cdc'
    INSERT msdb.dbo.ddl_event(event_data) select EVENTDATA()

GO

ENABLE TRIGGER [catpure_ddl] ON DATABASE
GO


--USE [Demo]
--GO
--DROP TRIGGER [catpure_ddl] ON DATABASE
--DROP TABLE msdb.dbo.ddl_event
