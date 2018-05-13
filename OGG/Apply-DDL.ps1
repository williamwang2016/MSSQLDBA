function Invoke-GGSCI ($ComputerName, $OggHome, $Command) {
    $filename = 'ggsci_command_' + (Get-Date).ToString('yyyyMMddHHmmssfff')
    $output_path = "$OggHome\dirout"
    $obey_filename = $filename + '.oby'   #e.g. ggsci_command_20180512062332780.oby
    $output_filename = $filename + '.out' #e.g. ggsci_command_20180512062332780.out
    
    $exp = @"
            New-Item -Force -Path $output_path -ItemType Directory |  Out-Null
            '$Command' | Out-File -FilePath $output_path\$obey_filename -Encoding ascii -Force
            CMD /c echo OBEY $output_path\$obey_filename | $OggHome\ggsci.exe > $output_path\$output_filename
            Get-Content $output_path\$output_filename
"@
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Invoke-Expression $Using:exp}
}

function Add-Trandata ($ComputerName, $DsnName, $OggHome, $SchemaName, $TableName) {
    $ggsci_command = @"
        DBLOGIN SOURCEDB $DsnName
        ADD TRANDATA $SchemaName.$TableName
"@

    Invoke-GGSCI -ComputerName $ComputerName -OggHome $OggHome -Command $ggsci_command
}

function Delete-Trandata ($ComputerName, $DsnName, $OggHome, $SchemaName, $TableName) {
    $ggsci_command = @"
        DBLOGIN SOURCEDB $DsnName
        DELETE TRANDATA $SchemaName.$TableName
"@

    Invoke-GGSCI -ComputerName $ComputerName -OggHome $OggHome -Command $ggsci_command
}

function Add-Param ($ComputerName, $OggHome, $ProcessName, $Statement){
    $expr = "'$Statement' | Out-File $OggHome\dirprm\$ProcessName.prm -Encoding ascii -Append"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Invoke-Expression $Using:expr}
}

function Delete-Param ($ComputerName, $OggHome, $ProcessName, $Statement){

}

function Get-DDLEvent ($ServerInstance) {
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query 'SELECT TOP 1 * FROM msdb.dbo.view_ddl WHERE is_completed = 0 ORDER BY id'
}

function Update-DDLEvent ($ServerInstance, $EventID) {
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query "UPDATE msdb.dbo.ddl_event SET is_completed = 1, completion_time = GETDATE() WHERE id = $EventID"
}

$src_server = 'sqlserver-0'
$tgt_server = 'sqlserver-1'
$src_mgr_port = 7809
$tgt_mgr_port = 7809
$src_ogg_home = 'C:\OGG'
$tgt_ogg_home = 'C:\OGG'
$src_dsn = 'ogg_dsn'
$tgt_dsn = 'ogg_dsn'
$db_name = 'Demo'
$extract_name = 'cdcext'
$pump_name = 'cdcpmp'
$local_trail_name = 'ce'
$remote_trail_name = 'cp'
$replicat_name = 'cdcrep'


$ddl_event = Get-DDLEvent -ServerInstance $src_server

while ($ddl_event -ne $null) {

    $id = $ddl_event.id
    $event_type = $ddl_event.event_type
    $database_name = $ddl_event.database_name
    $ddl_command = $ddl_event.ddl_command
    $schema_name = $ddl_event.schema_name
    $object_name = $ddl_event.object_name
    $object_type = $ddl_event.object_type

    switch ($event_type) {

        'CREATE_TABLE' {
            Add-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
            Break
        }

        'ALTER_TABLE' {
            Delete-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
            Add-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
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
    }
    
    #Execute DDL on target
    Invoke-Sqlcmd -ServerInstance $tgt_server -Query $ddl_command -Database $database_name

    #Stagger sequence so that one side is even number, the other side is odd number
    if ($event_type -eq 'CREATE_SEQUENCE')
    {
        $query = "SELECT start_value FROM sys.sequences WHERE name = '$object_name'"
        $start_value = Invoke-Sqlcmd -ServerInstance $tgt_server -Query $query -Database $database_name
        $new_start_value = $start_value.start_value + 1
        $query = "ALTER SEQUENCE $schema_name.$object_name RESTART WITH $new_start_value"
        Invoke-Sqlcmd -ServerInstance $tgt_server -Query $query -Database $database_name
    }

    #Mark event as completed and update the completion time
    Update-DDLEvent -ServerInstance $src_server -EventID $id

    #Start processing the next DDL event
    $ddl_event = Get-DDLEvent -ServerInstance $src_server
}
