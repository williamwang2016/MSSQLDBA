Validate-HeartBeat -SourceServerName $src_server -TargetServerName $tgt_server -DatabaseName $db_name


$ggsci_command = @"
INFO ALL
"@
Invoke-GGSCI -ComputerName $src_server -OggHome $src_ogg_home -Command $ggsci_command
Invoke-GGSCI -ComputerName $tgt_server -OggHome $tgt_ogg_home -Command $ggsci_command

<#
$ggsci_command = @"
INFO ALL
"@
Invoke-GGSCI -ComputerName $src_server -OggHome $src_ogg_home -Command $ggsci_command
#>

<#
$schema_name = 'dbo'
$object_name = 't2'
Add-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
Delete-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
#>

<#
#Example:
$extract_stmt = "TABLE sch1.*;"
Add-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name -Statement $extract_stmt
Add-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name -Statement $extract_stmt
$replicat_stmt = "MAP sch1.*, TARGET sch1.*;"
Add-Param -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name -Statement $replicat_stmt
#>

<#
$extract_stmt = "TABLE testch.*;"
Delete-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name -Statement $extract_stmt
Delete-Param -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name -Statement $extract_stmt
$replicat_stmt = "MAP sch1.*, TARGET sch1.*;"
Delete-Param -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name -Statement $replicat_stmt
#>

<#
#Example:
Add-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
Delete-Trandata -ComputerName $src_server -DsnName $src_dsn -OggHome $src_ogg_home -SchemaName $schema_name -TableName $object_name
#>


#Example:
Stop-OggProcess -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name
Stop-OggProcess -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name
Stop-OggProcess -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name

Start-OggProcess -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $extract_name
Start-OggProcess -ComputerName $src_server -OggHome $src_ogg_home -ProcessName $pump_name
Start-OggProcess -ComputerName $tgt_server -OggHome $tgt_ogg_home -ProcessName $replicat_name

Get-OggStatus -ComputerName $src_server -OggHome $src_ogg_home
Get-OggStatus -ComputerName $tgt_server -OggHome $tgt_ogg_home

#Example: Validate Heartbeat
$retry_counter = 0
$retry_interval = 1
$retry_max = 60

$heartbeat_age = (Invoke-Sqlcmd -ServerInstance $tgt_server -Database $db_name -Query "SELECT incoming_heartbeat_age FROM ogg.GG_LAG").incoming_heartbeat_age

while ($retry_counter -le $retry_max) {
    Start-Sleep -Seconds 1
    $next_heartbeat_age = (Invoke-Sqlcmd -ServerInstance $tgt_server -Database $db_name -Query "SELECT incoming_heartbeat_age FROM ogg.GG_LAG").incoming_heartbeat_age
    if ($next_heartbeat_age -gt $heartbeat_age) { #Not Sync Yet
        $heartbeat_age = $next_heartbeat_age
        $retry_counter++
    }
    else {
        return $true
    }
}

return $false

$object_id = (Invoke-Sqlcmd -ServerInstance $src_server -Database $db_name -Query "SELECT OBJECT_ID('dbo.t2') AS object_id").object_id
    if ($object_id) {
        return $true
    }
    else {
        return $false
    }

$object_id.GetType()


$ggsci_command = 'INFO ALL'
$ComputerName, $OggHome, $Command = $src_server, $src_ogg_home, $ggsci_command

function Invoke-GGSCI ($ComputerName, $OggHome, $Command) {
    $filename = 'ggsci_command_' + (Get-Datestr)
    $output_path = "$OggHome\dirout"
    $obey_filename = $filename + '.oby'   #e.g. ggsci_command_20180512062332780.oby
    $output_filename = $filename + '.out' #e.g. ggsci_command_20180512062332780.out
    
    $exp = @"
            New-Item -Force -Path $output_path -ItemType Directory |  Out-Null
            '$Command' | Out-File -FilePath $output_path\$obey_filename -Encoding ascii -Force
            CMD /c echo OBEY $output_path\$obey_filename | $OggHome\ggsci.exe > $output_path\$output_filename
            Get-Content $output_path\$output_filename
"@
    Write-ErrorLog -log $Global:errorlog -msg "[info] Invoke GGSCI command:"
    Write-ErrorLog -log $Global:errorlog -msg $Command

    $r = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Invoke-Expression $Using:exp}

    if ($r -match 'ERROR:') {
        Write-ErrorLog -log $Global:errorlog -msg "[error] Error found in GGSCI result"
        Write-ErrorLog -log $Global:errorlog -msg $r
        Throw "Error found in GGSCI result"
    }
    else {
        Write-ErrorLog -log $Global:errorlog -msg $r
    }
}

$r = $r[11..($r.Length-1)] | Out-String
function Write-ErrorLog {
	param($log, $msg)
	$now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss -')
    try{
        $log_dir = Split-Path $log
        New-Item -Path $log_dir -Force -ItemType Directory | Out-Null
	    "$now $msg" | Out-File -FilePath $log -Append
	    Write-Verbose "$now $msg"
    }
    catch {
        Throw "Failed to write to error log"
    }
}

$s = $r | Out-String
Write-Verbose "$now $s"

Invoke-GGSCI -ComputerName $src_server -OggHome $src_ogg_home -Command "INFO ALL"