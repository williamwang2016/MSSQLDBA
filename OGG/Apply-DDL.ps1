#import utilities and parameters
. .\Util.ps1
. .\Param.ps1

function Get-DDLEvent ($ServerInstance) {
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query 'SELECT TOP 1 * FROM msdb.dbo.view_ddl WHERE completion_time IS NULL ORDER BY id'
}

function Update-DDLEvent ($ServerInstance, $EventID) {
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query "UPDATE msdb.dbo.ddl_event SET completion_time = GETDATE() WHERE id = $EventID"
}

function Exists-Table ($ServerInstance, $Database, $SchemaName, $TableName) {
    $object_id = (Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query "SELECT OBJECT_ID('$SchemaName.$TableName') AS object_id").object_id
    if ($object_id.GetType().Name -eq 'DBNull') {
        return $false
    }
    else {
        return $true
    }
}

function Out-DDLLog ($Command, $Path) {
    $Command | Out-File -FilePath $Path -Append -Encoding ascii
    'GO' | Out-File -FilePath $Path -Append -Encoding ascii
}



#path to store ddl sql script on controller machine
$ddl_logdir = 'C:\OGG\dirsql'
New-Item -Force -Path $ddl_logdir -ItemType Directory |  Out-Null
$ddl_logfile = "$ddl_logdir\ddl_" + (Get-Datestr) + ".sql"
Out-File -FilePath $ddl_logfile -Force -Encoding ascii


$ddl_event = Get-DDLEvent -ServerInstance $src_server

while ($ddl_event -ne $null) {

    $id = $ddl_event.id
    $event_type = $ddl_event.event_type
    $ddl_command = $ddl_event.ddl_command
    $schema_name = $ddl_event.schema_name
    $object_name = $ddl_event.object_name
    $object_type = $ddl_event.object_type

    switch ($event_type) {

        'CREATE_TABLE' {
            if (Exists-Table -ServerInstance $src_server -Database $db_name -SchemaName $schema_name -TableName $object_name) {
                Add-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
            }
            Break
        }

        'ALTER_TABLE' {
            if (Exists-Table -ServerInstance $src_server -Database $db_name -SchemaName $schema_name -TableName $object_name) {
                Delete-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
                Add-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
            }
            Break
        }

        'CREATE_SCHEMA' {
            #Add "TABLE $schema_name.*;" to Param files of Extract and Pump
            $extract_stmt = "TABLE $schema_name.*;"
            Add-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name -Statement $extract_stmt
            Add-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name -Statement $extract_stmt

            #Add "MAP $schema_name.*, TARGET $schema_name.*;" to Param file of Replicat
            $replicat_stmt = "MAP $schema_name.*, TARGET $schema_name.*;"
            Add-Param -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name -Statement $replicat_stmt
            Break
        }

        'DROP_SCHEMA'{
            #Delete "TABLE $schema_name.*;" from Param files of Extract and Pump
            $extract_stmt = "TABLE $schema_name.*;"
            Delete-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name -Statement $extract_stmt
            Delete-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name -Statement $extract_stmt

            #Delete "MAP $schema_name.*, TARGET $schema_name.*;" from Param file of Replicat
            $replicat_stmt = "MAP $schema_name.*, TARGET $schema_name.*;"
            Delete-Param -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name -Statement $replicat_stmt
            Break
        }

        'CREATE_SEQUENCE' {
            #Stagger sequence so that one side is even number, the other side is odd number
            $query = "SELECT start_value FROM sys.sequences WHERE name = '$object_name'"
            $start_value = Invoke-Sqlcmd -ServerInstance $src_server -Query $query -Database $db_name
            $new_start_value = $start_value.start_value + 1
            $query = "ALTER SEQUENCE $schema_name.$object_name RESTART WITH $new_start_value"

            #Compose a new DDL command with a staggered start value
            $ddl_command = $ddl_command + "`r`n" + $query
            Break
        }
    }
    
    #Add ddl command to ddl log
    Out-DDLLog -Command $ddl_command -Path $ddl_logfile

    #Mark event as processed in ddl_event table
    Update-DDLEvent -ServerInstance $src_server -EventID $id

    #Start processing the next DDL event
    $ddl_event = Get-DDLEvent -ServerInstance $src_server
}

#Start Extract on source
Start-OggProcess -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name

#Execute ddl log against target
Write-ErrorLog -log $Global:errorlog -msg "[info] Apply DDL on target $tgt_server"
Write-ErrorLog -log $Global:errorlog -msg "Get-Content $ddl_logfile"
Invoke-Sqlcmd -ServerInstance $tgt_server -InputFile $ddl_logfile -Database $db_name -QueryTimeout 65535

#Start Replicat on target
Start-OggProcess -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name

#Start Pump on source
Start-OggProcess -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name

#Validating HeartBeat
Write-ErrorLog -log $Global:errorlog -msg "[info] Validating Heartbeat between $src_server and $tgt_server"
if (Validate-HeartBeat -SourceServerName $src_server -TargetServerName $tgt_server -DatabaseName $db_name) {
    Write-ErrorLog -log $Global:errorlog -msg "[info] Validated Heartbeat between $src_server and $tgt_server"
    Write-ErrorLog -log $Global:errorlog -msg "[info] DDL replication from $src_server to $tgt_server has succeeded"
    Write-ErrorLog -log $Global:errorlog -msg "[info] Successful"
}
else {
    Write-ErrorLog -log $Global:errorlog -msg "[error] Failed to validate heartbeat between $src_server and $tgt_server"
    Write-ErrorLog -log $Global:errorlog -msg "[error] Refer to the error log $Global:errorlog for more details"
    Write-ErrorLog -log $Global:errorlog -msg "[error] Failed"
    Throw "DDL replication from $src_server to $tgt_server has failed"
}

