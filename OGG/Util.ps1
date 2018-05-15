#Utilities

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


function Get-Datestr {
    (Get-Date).ToString('yyyyMMddHHmmssfff')
}


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
    $r = $r[11..($r.Length-1)] | Out-String #filter out header

    if ($r -match 'ERROR:') {
        Write-ErrorLog -log $Global:errorlog -msg "[error] Error found in GGSCI result"
        Write-ErrorLog -log $Global:errorlog -msg $r
        Throw "Error found in GGSCI result"
    }
    else {
        Write-ErrorLog -log $Global:errorlog -msg $r
    }
}


function Add-Trandata ($ComputerName, $DsnName, $OggHome, $SchemaName, $TableName) {
    $ggsci_command = @"
        DBLOGIN SOURCEDB $DsnName
        ADD TRANDATA $SchemaName.$TableName
"@
    Write-ErrorLog -log $Global:errorlog -msg "[info] Add Trandata for $SchemaName.$TableName"
    try {
        Invoke-GGSCI -ComputerName $ComputerName -OggHome $OggHome -Command $ggsci_command
    }
    catch {
        Write-ErrorLog -log $Global:errorlog -msg "[error] Failed to Add Trandata for $SchemaName.$TableName"
        Throw "Failed to Add Trandata for $SchemaName.$TableName"
    }
}


function Delete-Trandata ($ComputerName, $DsnName, $OggHome, $SchemaName, $TableName) {
    $ggsci_command = @"
        DBLOGIN SOURCEDB $DsnName
        DELETE TRANDATA $SchemaName.$TableName
"@

    Write-ErrorLog -log $Global:errorlog -msg "[info] Delete Trandata for $SchemaName.$TableName"
    try {
        Invoke-GGSCI -ComputerName $ComputerName -OggHome $OggHome -Command $ggsci_command
    }
    catch {
        Write-ErrorLog -log $Global:errorlog -msg "[error] Failed to Delete Trandata for $SchemaName.$TableName"
        Throw "Failed to Delete Trandata for $SchemaName.$TableName"
    }
}


function Add-Param ($ComputerName, $OggHome, $ProcessName, $Statement){
    $prm_filepath = "$OggHome\dirprm\$ProcessName.prm"
    $bak_prm_filepath = "$OggHome\dirprm\$ProcessName.prm." + (Get-Datestr) + ".bak"

    $expr = @"
        Copy-Item $prm_filepath -Destination $bak_prm_filepath
        '$Statement' | Out-File $OggHome\dirprm\$ProcessName.prm -Encoding ascii -Append
"@
    Write-ErrorLog -log $Global:errorlog -msg "[info] Add the following statements to $prm_filepath on $ComputerName"
    Write-ErrorLog -log $Global:errorlog -msg $Statement
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Invoke-Expression $Using:expr}
}


function Delete-Param ($ComputerName, $OggHome, $ProcessName, $Statement){
    $prm_filepath = "$OggHome\dirprm\$ProcessName.prm"
    $temp_prm_filepath = "$prm_filepath.temp"
    $backup_prm_filename = "$ProcessName.prm." + (Get-Datestr) + ".bak"

    $expr = @"
        Get-Content $prm_filepath | Where-Object {`$_ -notmatch "$Statement"} | Set-Content $temp_prm_filepath -Encoding Ascii
        Rename-Item -Path $prm_filepath -NewName $backup_prm_filename
        Rename-Item -Path $temp_prm_filepath -NewName $prm_filepath
"@
    Write-ErrorLog -log $Global:errorlog -msg "[info] Delete the following statements from $prm_filepath on $ComputerName"
    Write-ErrorLog -log $Global:errorlog -msg $Statement

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Invoke-Expression $Using:expr}
}


function Start-OggProcess ($ComputerName, $OggHome, $ProcessName) {
    $ggsci_command = @"
    START $ProcessName
"@
    Write-ErrorLog -log $Global:errorlog -msg "[info] Start $ProcessName on $ComputerName"
    Invoke-GGSCI -ComputerName $ComputerName -OggHome $OggHome -Command $ggsci_command
}


function Stop-OggProcess ($ComputerName, $OggHome, $ProcessName) {
    $ggsci_command = @"
    STOP $ProcessName
"@
    Write-ErrorLog -log $Global:errorlog -msg "[info] Stop $ProcessName on $ComputerName"
    Invoke-GGSCI -ComputerName $ComputerName -OggHome $OggHome -Command $ggsci_command
}


function Get-OggStatus ($ComputerName, $OggHome) {
    $ggsci_command = @"
    INFO ALL
"@
    Write-ErrorLog -log $Global:errorlog -msg "[info] Get Status on $ComputerName"
    Invoke-GGSCI -ComputerName $ComputerName -OggHome $OggHome -Command $ggsci_command
}

function Validate-Heartbeat ($SourceServerName, $TargetServerName, $DatabaseName) {
    #Trigger a heartbeat on source
    Invoke-Sqlcmd -ServerInstance $SourceServerName -Database $DatabaseName -Query "EXEC ogg.GG_UPDATE_HB_TAB"

    $retry_counter = 0
    $retry_interval = 1
    $retry_max = 90
    $heartbeat_age = (Invoke-Sqlcmd -ServerInstance $TargetServerName -Database $DatabaseName -Query "SELECT incoming_heartbeat_age FROM ogg.GG_LAG").incoming_heartbeat_age

    while ($retry_counter -le $retry_max) {
        Start-Sleep -Seconds 1
        $next_heartbeat_age = (Invoke-Sqlcmd -ServerInstance $TargetServerName -Database $DatabaseName -Query "SELECT incoming_heartbeat_age FROM ogg.GG_LAG").incoming_heartbeat_age
        if ($next_heartbeat_age -gt $heartbeat_age) { #Not Sync Yet
            $heartbeat_age = $next_heartbeat_age
            $retry_counter++
        }
        else {
        return $true
        }
    }

    return $false
}
