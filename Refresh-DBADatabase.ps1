param($src_server, $src_port, $src_database, dest_folder, $dest_server, $dest_port, $dest_database)
Import-Module sqlps

$backup_files = Get-DBALatestBackupFiles $src_server $src_port $src_database

foreach ($b in $backup_files)
{
    Write-Host "Copy $b to $dest_folder"
    Copy-Item -Path "Microsoft.PowerShell.Core\FileSystem::$b" -Destination $dest_folder
    
    $dest_file = "$dest_folder\" + $b.Split("\")[-1]
    
    if ($dest_file.Split(".")[-1] -eq "bak")
    {
        $query_restore = "sp_restore_database @backup_file = '$dest_file', @db_name = '$dest_database', @status = 'NORECOVERY'"
    }
    else
    {
        $query_restore = "RESTORE LOG $dest_database FROM DISK = '$dest_file' WITH NORECOVERY"
    }

    $query_restore
    Invoke-Sqlcmd -ServerInstance "$dest_server,$dest_port" -Query $query_restore -QueryTimeout 65535
    #$query_restore | Out-File c:\install\restore.txt -Append
   
    Write-Host "Remove $dest_file"
    #Remove-Item $dest_file
}

Invoke-Sqlcmd -ServerInstance "$dest_server,$dest_port" -Query "RESTORE LOG $dest_database" -QueryTimeout 65535
