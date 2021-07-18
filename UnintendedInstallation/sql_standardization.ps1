param ($VirtualServerName)

$sql_setMaxMemory = @"
declare @max_memory int
select @max_memory = (total_physical_memory_kb*7)/(1024*8) from sys.dm_os_sys_memory
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
EXEC sys.sp_configure N'max server memory (MB)', @max_memory
RECONFIGURE WITH OVERRIDE
"@

$sql_enableBackupCompression = @"
EXEC sys.sp_configure N'show advanced options', N'1'
RECONFIGURE WITH OVERRIDE
EXEC sys.sp_configure N'backup compression default', N'1'
RECONFIGURE WITH OVERRIDE
"@

$sql_hardening = @"
USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, 3
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 12
EXEC sp_configure 'show advanced option', '1';
RECONFIGURE;
EXEC sp_configure 'remote access', '0';
RECONFIGURE
GO
"@

$sql_configTempdb = @"
declare @CPUNum int
declare @PathToTempdb varchar(255)
declare @InitFileSize varchar(255)
declare @FileGrowth varchar(255)

select @CPUNum = cpu_count from sys.dm_os_sys_info

SELECT @PathToTempdb = SUBSTRING(physical_name, 1, CHARINDEX(N'tempdb.mdf', LOWER(physical_name)) - 2)
FROM master.sys.master_files
WHERE database_id = 2 AND FILE_ID = 1


if @CPUNum > 8
begin
	set @CPUNum = 8
end

set @InitFileSize = '2GB'
set @FileGrowth = '200MB'

-- dynamic sql
declare @D_SQL varchar(max)

--
-- move tempdb to @PathToTempdb
--
-- note: char(13) new line
SET @D_SQL =          'USE master' + char(13)

SET @D_SQL = @D_SQL + '-----------------------------------------------------------------------------' + char(13)
SET @D_SQL = @D_SQL + '-- move tempdb' + char(13)

SET @D_SQL = @D_SQL + 'ALTER DATABASE tempdb' + char(13)
					+ 'MODIFY FILE (NAME = tempdev, FILENAME = ''' + @PathToTempdb + '\tempdb.mdf''' + ',' + char(13)
					+ 'SIZE = ' + @InitFileSize + ',' + char(13)
					+ 'FILEGROWTH = ' + @FileGrowth + ')' + char(13)

SET @D_SQL = @D_SQL + 'ALTER DATABASE tempdb' + char(13)
					+ 'MODIFY FILE (NAME = templog, FILENAME = ''' + @PathToTempdb + '\templog.ldf''' +',' + char(13)
					+ 'SIZE = ' + @InitFileSize + ',' + char(13)
					+ 'FILEGROWTH = ' + @FileGrowth + ')' + char(13)


--
-- add datafiles, total number of datafiles equal to number of physical CPU.
--
SET @D_SQL = @D_SQL + '-----------------------------------------------------------------------------' + CHAR(13)
SET @D_SQL = @D_SQL + '-- add datafiles' + char(13)

declare @i int
set @i=1
while (@i < @CPUNum)
begin
	SET @D_SQL = @D_SQL + 'ALTER DATABASE tempdb' + char(13)
						+ 'ADD FILE (NAME = tempdev_' + convert(varchar(20), @i) + ',' + char(13)
						+ 'FILENAME = ''' + @PathToTempdb + '\tempdev_' + convert(varchar(20), @i) + '.ndf''' +',' + char(13)
						+ 'SIZE = ' + @InitFileSize + ',' + char(13)
						+ 'FILEGROWTH = ' + @FileGrowth + ')' + char(13)
    
    set @i = @i + 1
end

EXEC(@D_SQL)
"@

$sql_verifyDefaultLoction = @"
declare @DefaultData nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefaultData OUTPUT

declare @DefaultLog nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefaultLog OUTPUT

declare @DefaultBackup nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @DefaultBackup OUTPUT

PRINT 'DefaultData: ' + ISNULL(@DefaultData,N'Not Found')
PRINT 'DefaultLog: ' + ISNULL(@DefaultLog,N'Not Found')
PRINT 'DefaultBackup: ' + ISNULL(@DefaultBackup,N'Not Found')
"@

if ($VirtualServerName.Contains("WC"))
{
	$InstanceName = 'SQL'+$VirtualServerName[-1]
	$sqlConnection = "$VirtualServerName\$InstanceName"
}
else
{
	$sqlConnection = $VirtualServerName
}

Write-Host "Setting max memory",$sqlConnection
sqlcmd -S $sqlConnection -E -Q "$sql_setMaxMemory"

Write-Host "Enabling backup compression"
sqlcmd -S $sqlConnection -E -Q "$sql_enableBackupCompression"

Write-Host "Disabling login audit"
sqlcmd -S $sqlConnection -E -Q "$sql_hardening"

Write-Host "Verify the default locations are correct"
sqlcmd -S $sqlConnection -E -Q "$sql_verifyDefaultLoction"

#-------Set xxxx as the port
[System.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null
$wmi = new-object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer')
$wmi.ServerInstances | ForEach-Object { 
$tcp = $wmi.ServerInstances[$_.Name].ServerProtocols['Tcp'] 
$tcp.IPAddresses['IPAll'].IPAddressProperties['TcpPort'].Value="xxxx"
$tcp.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value=""
$tcp.Alter()
}
#-------Set xxxx as the port---END

if ($VirtualServerName.Contains("WC"))
{
	#Configure tempdb for clusters only
	Write-Host "Configuring tempdb"
	sqlcmd -S $sqlConnection -E -Q "$sql_configTempdb"
	
	#-------Configure the cluster resources
	Import-Module FailoverClusters
#	Remove-ClusterResourceDependency -Resource "SQL Server ($InstanceName)" -Provider "$($InstanceName)_BACKUP" | Out-Null
	(Get-ClusterResource "SQL Server agent ($InstanceName)").RestartAction = 1
#	(Get-ClusterResource "$($InstanceName)_backup").restartaction = 1
	if (Get-ClusterResource | Where-Object {$_.name -eq "Analysis Services ($InstanceName)"})
	{
		Remove-ClusterResourceDependency -Resource "Analysis Services ($InstanceName)" -Provider "$($InstanceName)_BACKUP" | Out-Null
		(Get-ClusterResource "Analysis Services ($InstanceName)").restartaction = 2
	}
	Move-ClusterGroup "$InstanceName" | Out-Null
	Move-ClusterGroup "$InstanceName" | Out-Null
	#-------Configure the cluster resources---END
}
