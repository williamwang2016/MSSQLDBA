IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_restore_database]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_restore_database]
GO
CREATE PROCEDURE sp_restore_database
@backup_file varchar(1024),
@db_name varchar(255) = NULL,
@replace varchar(7) = NULL,
@status varchar(1024) = 'RECOVERY',
@data_dir varchar(1024) = NULL,
@log_dir varchar (1024) = NULL

AS
SET NOCOUNT ON

--Get @db_name from @backup_file if @db_name is not specified
IF @db_name IS NULL
BEGIN
/* --parse db name from the name of the native backup file such as myDB_backup_2015_05_08_010000_8087336.bak
	declare @reversed_backup_file varchar(1024)
	SET @reversed_backup_file = REVERSE(@backup_file)

	select @db_name = REVERSE(SUBSTRING(@reversed_backup_file, 
										PATINDEX('%_pukcab_%', @reversed_backup_file) + len('_pukcab_'), 
										PATINDEX('%\%', @reversed_backup_file) - (PATINDEX('%_pukcab_%', @reversed_backup_file) + len('_pukcab_'))
										))
*/

--parse db name from backup file through RESTORE HEADERONLY
	CREATE TABLE #BackupHeader
		  (
				BackupName  nvarchar(128),
				BackupDescription  nvarchar(255) ,
				BackupType  smallint ,
				ExpirationDate  datetime ,
				Compressed  bit ,
				Position  smallint ,
				DeviceType  tinyint ,
				UserName  nvarchar(128) ,
				ServerName  nvarchar(128) ,
				DatabaseName  nvarchar(128) ,
				DatabaseVersion  int ,
				DatabaseCreationDate  datetime ,
				BackupSize  numeric(20,0) ,
				FirstLSN  numeric(25,0) ,
				LastLSN  numeric(25,0) ,
				CheckpointLSN  numeric(25,0) ,
				DatabaseBackupLSN  numeric(25,0) ,
				BackupStartDate  datetime ,
				BackupFinishDate  datetime ,
				SortOrder  smallint ,
				CodePage  smallint ,
				UnicodeLocaleId  int ,
				UnicodeComparisonStyle  int ,
				CompatibilityLevel  tinyint ,
				SoftwareVendorId  int ,
				SoftwareVersionMajor  int ,
				SoftwareVersionMinor  int ,
				SoftwareVersionBuild  int ,
				MachineName  nvarchar(128) ,
				Flags  int ,
				BindingID  uniqueidentifier ,
				RecoveryForkID  uniqueidentifier ,
				Collation  nvarchar(128) ,
				FamilyGUID  uniqueidentifier ,
				HasBulkLoggedData  bit ,
				IsSnapshot  bit ,
				IsReadOnly  bit ,
				IsSingleUser  bit ,
				HasBackupChecksums  bit ,
				IsDamaged  bit ,
				BeginsLogChain  bit ,
				HasIncompleteMetaData  bit ,
				IsForceOffline  bit ,
				IsCopyOnly  bit ,
				FirstRecoveryForkID  uniqueidentifier ,
				ForkPointLSN  numeric(25,0) NULL,
				RecoveryModel  nvarchar(60) ,
				DifferentialBaseLSN  numeric(25,0) NULL,
				DifferentialBaseGUID  uniqueidentifier ,
				BackupTypeDescription  nvarchar(60) ,
				BackupSetGUID  uniqueidentifier NULL,
				CompressedBackupSize  bigint
		  )
	IF @@MICROSOFTVERSION/power(2, 24) > 10 -- SQL2012+ has an additional column
		ALTER TABLE #BackupHeader ADD containment tinyint
	IF @@MICROSOFTVERSION/power(2, 24) > 11 -- SQL2014+ has an additional column
	BEGIN
		ALTER TABLE #BackupHeader ADD KeyAlgorithm nvarchar(32)
		ALTER TABLE #BackupHeader ADD EncryptorThumbprint varbinary(20)
		ALTER TABLE #BackupHeader ADD EncryptorType nvarchar(32)
	END

	insert into #BackupHeader
	exec('RESTORE HEADERONLY FROM DISK = ''' + @backup_file + '''')

	SELECT @db_name = DatabaseName FROM #BackupHeader
	
END

--Get default locations for data and log if @data_dir and @log_dir are not specified
IF @data_dir IS NULL
	IF @@MICROSOFTVERSION/power(2, 24) > 10
		SELECT @data_dir = CONVERT(varchar(1024), SERVERPROPERTY('instancedefaultdatapath'))
	ELSE
		exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @data_dir OUTPUT

IF @log_dir IS NULL
	IF @@MICROSOFTVERSION/power(2, 24) > 10
		SELECT @log_dir = CONVERT(varchar(1024), SERVERPROPERTY('instancedefaultlogpath'))
	ELSE
		exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @log_dir OUTPUT

--Set @status
SET @status = UPPER(@status)
IF @status = 'STANDBY'
	SELECT @status = 'STANDBY = ' + QUOTENAME(@data_dir + '\' + @db_name + '.undo', '''')
ELSE IF @status <> 'RECOVERY' and @status <> 'NORECOVERY'
BEGIN
	PRINT '@status is not correct. Acceptable values are STANDBY, RECOVERY and NORECOVERY'
	RETURN
END

declare @ExecStr varchar(max)

--If 'Replace' is specified, remove the database if it exists
IF UPPER(@replace) = 'REPLACE' and DB_ID(@db_name) IS NOT NULL
BEGIN
	IF DATABASEPROPERTYEX (@db_name , 'STATUS') = 'ONLINE'
	BEGIN
		SET @ExecStr = 'ALTER DATABASE ' + QUOTENAME(@db_name) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
		EXEC(@ExecStr)
	END
	SET @ExecStr = 'DROP DATABASE ' + QUOTENAME(@db_name)
	EXEC(@ExecStr)
END

CREATE TABLE #BackupFileList
( LogicalName        sysname        NULL
, PhysicalName        sysname        NULL
, [Type]        char(1)
, FileGroupName        sysname NULL
, Size        bigint
, MaxSize        bigint
, FileId        smallint
, CreateLSN        numeric(25,0)
, DropLSN        numeric(25,0)
, UniqueId uniqueidentifier
, ReadOnlyLSN        numeric(25,0)
, ReadWriteLSN        numeric(25,0)
, BackupSizeInBytes        bigint
, SourceBlockSize        bigint
, FileGroupId                smallint
, LogGroupGUID        uniqueidentifier
, DifferentialBaseLSN        numeric(25,0)
, DifferentialBaseGUID        uniqueidentifier
, IsReadOnly        bit
, IsPresent        bit
--, TDEThumbPrint varbinary(32) --SQL2008+ has column TDEThumbPrint
)

IF @@MICROSOFTVERSION/power(2, 24) > 9 -- SQL2008+ has an additional column
	ALTER TABLE #BackupFileList ADD TDEThumbPrint varbinary(32)
IF @@MICROSOFTVERSION/power(2, 24) > 12 -- SQL2008+ has an additional column
	ALTER TABLE #BackupFileList ADD SnapshotUrl  NVARCHAR(360)

INSERT #BackupFileList
EXEC('RESTORE FILELISTONLY FROM DISK = ''' + @backup_file + '''')

UPDATE #BackupFileList
SET PhysicalName = @data_dir + '\' + REVERSE(SUBSTRING(REVERSE(PhysicalName), 1, PATINDEX('%\%', REVERSE(PhysicalName)) -1))
WHERE Type = 'D'

UPDATE #BackupFileList
SET PhysicalName = @log_dir  + '\' + REVERSE(SUBSTRING(REVERSE(PhysicalName), 1, PATINDEX('%\%', REVERSE(PhysicalName)) -1))
WHERE Type = 'L'

SET @ExecStr = 'RESTORE DATABASE ' + QUOTENAME(@db_name) + ' FROM DISK = ' + QUOTENAME(@backup_file, '''') + ' WITH '

DECLARE FileListCursor CURSOR FAST_FORWARD FOR 
	SELECT LogicalName, PhysicalName FROM #BackupFileList

OPEN FileListCursor
DECLARE @LogicalName sysname, @PhysicalName sysname
FETCH NEXT FROM FileListCursor INTO @LogicalName, @PhysicalName 
WHILE (@@fetch_status = 0)
BEGIN
	SELECT @ExecStr = @ExecStr +
	'MOVE ' + QUOTENAME(@LogicalName, '''') + ' TO ' + QUOTENAME(@PhysicalName, '''') + ', '

	FETCH NEXT FROM FileListCursor INTO @LogicalName, @PhysicalName
END

SET @ExecStr = @ExecStr + @status + ', STATS = 5'

CLOSE FileListCursor
DEALLOCATE FileListCursor
DROP TABLE #BackupFileList

EXEC(@ExecStr)
