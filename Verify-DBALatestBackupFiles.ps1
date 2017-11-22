param($src_server,$src_port,$src_database)

$backup_files = Get-DBALatestBackupFiles $src_server $src_port $src_database

Foreach ($b in $backup_files) {
    Test-Path "Microsoft.PowerShell.Core\FileSystem::$($b.LastFullBackupFile)"
}
