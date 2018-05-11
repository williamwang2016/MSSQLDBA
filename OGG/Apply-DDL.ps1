function Add-Trandata ($ComputerName, $DsnName, $OggHome, $SchemaName, $TableName)
{
    $ggsci_command = @"
        DBLOGIN SOURCEDB $DsnName
        ADD TRANDATA $SchemaName.$TableName
"@

    Invoke-Command -ComputerName $ComputerName -FilePath Invoke-GGSCI.ps1 -ArgumentList $OggHome, $ggsci_command
    #Invoke-GGSCI -ComputerName $ComputerName -OggHome -$OggHome -Command $ggsci_command
}

function Add-Param ($ComputerName, $OggHome, $ProcessName, $Statement)
{
    $expr = "'$Statement' | Out-File $OggHome\dirprm\$ProcessName.prm -Encoding ascii -Append"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Invoke-Expression $Using:expr}
}

function Remove-Param ($ComputerName, $OggHome, $ProcessName, $Statement)
{

}

$src_server = 'lvs1-ieodn-001'
$tgt_server = 'lvs1-ieodn-002'
$src_mgr_port = 7809
$tgt_mgr_port = 7809
$src_ogg_home = 'F:\OGG'
$tgt_ogg_home = 'G:\OGG'
$src_dsn = 'ogg_dsn'
$tgt_dsn = 'ogg_dsn'
$db_name = 'Demo'

$ddl_event = Invoke-Sqlcmd -ServerInstance $src_server -Query 'SELECT TOP 1 * FROM msdb.dbo.view_ddl WHERE is_completed = 0 ORDER BY id'
while ($ddl_event -ne $null)
{
    $id = $ddl_event.id
    $event_type = $ddl_event.event_type
    $database_name = $ddl_event.database_name
    $ddl_command = $ddl_event.ddl_command
    $schema_name = $ddl_event.schema_name
    $object_name = $ddl_event.object_name
    $object_type = $ddl_event.object_type

    Invoke-Sqlcmd -ServerInstance $tgt_server -Query $ddl_command -Database $database_name

    switch ($event_type)
    {
        'CREATE_TABLE'
        {
            Add-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
            Break
        }
        'CREATE_SCHEMA'
        {
            #Add "TABLE $schema_name.*;" to Param files of Extract and Pump
            $extract_stmt = "TABLE $schema_name.*;"
            Add-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name -Statement $extract_stmt
            Add-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name -Statement $extract_stmt

            #Add "MAP $schema_name.*, TARGET $schema_name.*;" to Param file of Replicat
            $replicat_stmt = "MAP $schema_name.*, TARGET $schema_name.*;"
            Add-Param -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name -Statement $replicat_stmt
            Break
        }
        'DROP_SCHEMA'
        {
            "Edit-Param"; 
            Break
        }
        'CREATE_SEQUENCE'
        {
            #Get the first digit after 'WITH' from $ddl_command
            Break
        }
    }

    Invoke-Sqlcmd -ServerInstance $src_server -Query "UPDATE msdb.dbo.ddl_event SET is_completed = 1 WHERE id = $id" -Database $database_name
    $ddl_event = Invoke-Sqlcmd -ServerInstance $src_server -Query 'SELECT TOP 1 * FROM msdb.dbo.view_ddl WHERE is_completed = 0 ORDER BY id'
}
