/****** Object:  Job [DatabaseBackup - SYSTEM_DATABASES - FULL] ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance] ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'DatabaseBackup - SYSTEM_DATABASES - FULL')
    EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseBackup - SYSTEM_DATABASES - FULL', @delete_unused_schedule=1

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DatabaseBackup - SYSTEM_DATABASES - FULL', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'Source: https://ola.hallengren.com', 
        @category_name=N'Database Maintenance', 
        @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseBackup - SYSTEM_DATABASES - FULL] ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DatabaseBackup - SYSTEM_DATABASES - FULL', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'EXECUTE [dbo].[DatabaseBackup]
@Databases = ''SYSTEM_DATABASES'',
@BackupType = ''FULL'',
@Verify = ''Y'',
@CleanupTime = 360,
@CheckSum = ''Y'',
@LogToTable = ''Y''', 
        @database_name=N'master', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'daily12am', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20210226, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=235959, 
        @schedule_uid=N'f4c37ea9-12b7-404d-891e-a88283ffc12e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



/****** Object:  Job [DatabaseBackup - USER_DATABASES - FULL]    Script Date: 2/26/2021 5:24:15 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 2/26/2021 5:24:15 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'DatabaseBackup - USER_DATABASES - FULL')
    EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseBackup - USER_DATABASES - FULL', @delete_unused_schedule=1

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DatabaseBackup - USER_DATABASES - FULL', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'Source: https://ola.hallengren.com', 
        @category_name=N'Database Maintenance', 
        @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseBackup - USER_DATABASES - FULL]    Script Date: 2/26/2021 5:24:15 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DatabaseBackup - USER_DATABASES - FULL', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'EXECUTE [dbo].[DatabaseBackup]
@Databases = ''USER_DATABASES'',
@BackupType = ''FULL'',
@Verify = ''Y'',
@CopyOnly=''Y'',
@CheckSum = ''Y'',
@LogToTable = ''Y'',
@CleanupTime = 360,
@NumberOfFiles = 8,
@BufferCount = 16,
@MaxTransferSize = 4194304',
        @database_name=N'master', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sunday12am', 
        @enabled=1, 
        @freq_type=8, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=1, 
        @active_start_date=20210226, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=235959, 
        @schedule_uid=N'266c462f-8170-4e3f-810a-3d1e567a7712'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


/****** Object:  Job [DatabaseBackup - USER_DATABASES - LOG]    Script Date: 2/26/2021 5:28:38 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 2/26/2021 5:28:38 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'DatabaseBackup - USER_DATABASES - LOG')
    EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseBackup - USER_DATABASES - LOG', @delete_unused_schedule=1

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DatabaseBackup - USER_DATABASES - LOG', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'Source: https://ola.hallengren.com', 
        @category_name=N'Database Maintenance', 
        @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseBackup - USER_DATABASES - LOG]    Script Date: 2/26/2021 5:28:38 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DatabaseBackup - USER_DATABASES - LOG', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'EXECUTE [dbo].[DatabaseBackup]
@Databases = ''USER_DATABASES'',
@BackupType = ''LOG'',
@Verify = ''Y'',
@CleanupTime = 360,
@CheckSum = ''Y'',
@LogToTable = ''Y''', 
        @database_name=N'master', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'every5min', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=4, 
        @freq_subday_interval=5, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20210226, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=235959, 
        @schedule_uid=N'ee7ffbc0-f9d0-43b8-8a39-ef9421803099'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


/****** Object:  Job [CommandLog Cleanup]    Script Date: 2/26/2021 5:05:23 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 2/26/2021 5:05:23 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'CommandLog Cleanup')
    EXEC msdb.dbo.sp_delete_job @job_name=N'CommandLog Cleanup', @delete_unused_schedule=1

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CommandLog Cleanup', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'Source: https://ola.hallengren.com', 
        @category_name=N'Database Maintenance', 
        @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CommandLog Cleanup]    Script Date: 2/26/2021 5:05:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CommandLog Cleanup', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'DELETE FROM [dbo].[CommandLog]
WHERE StartTime < DATEADD(dd,-30,GETDATE())', 
        @database_name=N'master', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'daily12am', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20210226, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=235959, 
        @schedule_uid=N'f4c37ea9-12b7-404d-891e-a88283ffc12e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [sp_delete_backuphistory]    Script Date: 2/26/2021 5:10:40 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 2/26/2021 5:10:40 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'sp_delete_backuphistory')
    EXEC msdb.dbo.sp_delete_job @job_name=N'sp_delete_backuphistory', @delete_unused_schedule=1

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'sp_delete_backuphistory', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'Source: https://ola.hallengren.com', 
        @category_name=N'Database Maintenance', 
        @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [sp_delete_backuphistory]    Script Date: 2/26/2021 5:10:40 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'sp_delete_backuphistory', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'DECLARE @CleanupDate datetime
SET @CleanupDate = DATEADD(dd,-30,GETDATE())
EXECUTE dbo.sp_delete_backuphistory @oldest_date = @CleanupDate', 
        @database_name=N'msdb', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'daily12am', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20210226, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=235959, 
        @schedule_uid=N'f4c37ea9-12b7-404d-891e-a88283ffc12e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [sp_purge_jobhistory]    Script Date: 2/26/2021 5:11:40 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 2/26/2021 5:11:40 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'sp_purge_jobhistory')
    EXEC msdb.dbo.sp_delete_job @job_name=N'sp_purge_jobhistory', @delete_unused_schedule=1

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'sp_purge_jobhistory', 
        @enabled=1, 
        @notify_level_eventlog=2, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'Source: https://ola.hallengren.com', 
        @category_name=N'Database Maintenance', 
        @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [sp_purge_jobhistory]    Script Date: 2/26/2021 5:11:40 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'sp_purge_jobhistory', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'DECLARE @CleanupDate datetime
SET @CleanupDate = DATEADD(dd,-30,GETDATE())
EXECUTE dbo.sp_purge_jobhistory @oldest_date = @CleanupDate', 
        @database_name=N'msdb', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'daily12am', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20210226, 
        @active_end_date=99991231, 
        @active_start_time=0, 
        @active_end_time=235959, 
        @schedule_uid=N'f4c37ea9-12b7-404d-891e-a88283ffc12e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'DatabaseIntegrityCheck - USER_DATABASES')
    EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseIntegrityCheck - USER_DATABASES', @delete_unused_schedule=1

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'DatabaseIntegrityCheck - SYSTEM_DATABASES')
    EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseIntegrityCheck - SYSTEM_DATABASES', @delete_unused_schedule=1

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'IndexOptimize - USER_DATABASES')
    EXEC msdb.dbo.sp_delete_job @job_name=N'IndexOptimize - USER_DATABASES', @delete_unused_schedule=1

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'DatabaseBackup - USER_DATABASES - DIFF')
    EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseBackup - USER_DATABASES - DIFF', @delete_unused_schedule=1

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'Output File Cleanup')
    EXEC msdb.dbo.sp_delete_job @job_name=N'Output File Cleanup', @delete_unused_schedule=1
