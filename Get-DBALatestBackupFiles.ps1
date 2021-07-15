param($src_server, $src_port, $src_database)

#$src_server = ''
#$src_port = 1433
#$src_database = ''

$query_fullbackup = @"
WITH FULLBACKUP
AS (
	SELECT s.database_name AS DatabaseName
		,s.backup_finish_date AS LastFullBackupTime
		,f.physical_device_name AS LastFullBackupFile
		,ROW_NUMBER() OVER (
			PARTITION BY s.database_name ORDER BY backup_finish_date DESC
			) AS RowNum
	FROM msdb.dbo.backupset s
	INNER JOIN [msdb].[dbo].[backupmediafamily] f ON s.[media_set_id] = f.[media_set_id]
	WHERE s.type = 'D' and s.database_name = '$src_database'
	)

	SELECT DatabaseName
		,LastFullBackupTime
		,LastFullBackupFile
	FROM FULLBACKUP 
	WHERE RowNum = 1
"@

$full_backup = Invoke-Sqlcmd -ServerInstance "$src_server,$src_port" -Database $src_database -Query $query_fullbackup -QueryTimeout 120

$query_differentialbackup = @"
WITH DIFFBACKUP
AS (
	SELECT s.database_name AS DatabaseName
		,s.backup_finish_date AS LastDifferentialBackupTime
		,f.physical_device_name AS LastDifferentialBackupFile
		,ROW_NUMBER() OVER (
			PARTITION BY s.database_name ORDER BY backup_finish_date DESC
			) AS RowNum
	FROM msdb.dbo.backupset s
	INNER JOIN [msdb].[dbo].[backupmediafamily] f ON s.[media_set_id] = f.[media_set_id]
	WHERE s.type = 'I' and s.database_name = '$src_database' and s.backup_finish_date >= '$($full_backup.LastFullBackupTime)'
	)

	SELECT DatabaseName
		,LastDifferentialBackupTime
		,LastDifferentialBackupFile
	FROM DIFFBACKUP 
	WHERE RowNum = 1
"@

$differential_backup = Invoke-Sqlcmd -ServerInstance "$src_server,$src_port" -Database $src_database -Query $query_differentialbackup -QueryTimeout 120

if ($differential_backup) {$tlog_backup_time = $differential_backup.LastDifferentialBackupTime} else {$tlog_backup_time = $full_backup.LastFullBackupTime}

$query_tlogbackup = @"
WITH TLOGBACKUP
AS (
	SELECT s.database_name AS DatabaseName
		,s.backup_finish_date AS TLogBackupTime
		,f.physical_device_name AS TlogBackupFile
		,ROW_NUMBER() OVER (
			PARTITION BY s.database_name ORDER BY backup_finish_date DESC
			) AS RowNum
	FROM msdb.dbo.backupset s
	INNER JOIN [msdb].[dbo].[backupmediafamily] f ON s.[media_set_id] = f.[media_set_id]
	WHERE s.type = 'L' and s.database_name = '$src_database' and s.backup_finish_date >= '$tlog_backup_time'
	)

	SELECT DatabaseName
		,TLogBackupTime
		,TlogBackupFile
	FROM TLOGBACKUP order by RowNum DESC
"@

$tlog_backup = Invoke-Sqlcmd -ServerInstance "$src_server,$src_port" -Database $src_database -Query $query_tlogbackup -QueryTimeout 120

$backup_files = @()
$backup_files += $full_backup.LastFullBackupFile
$backup_files += $differential_backup.LastDifferentialBackupFile
foreach ($tlog in $tlog_backup) {$backup_files += $tlog.TlogBackupFile}
$backup_files = $backup_files -replace '^(.):', "\\$src_server\`$1$"
$backup_files

# Example
# $backup = Get-DBALatestBackupFiles.ps1 Server1 1433 master
