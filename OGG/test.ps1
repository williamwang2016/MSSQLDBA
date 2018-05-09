$src_server = 'S1'
$src_mgr_port = 7809
$ogg_home = 'C:\OGG'
$dsn = 'ogg_dsn'
$tgt_server = 'S2'
$tgt_mgr_port = 7809

############################
##Execute GGSCI commands
##Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $ogg_home, $ggsci_command
############################
$ggsci_command = @"
DBLOGIN SOURCEDB $dsn
ADD TRANDATA dbo.*
"@

Set-Location $PSScriptRoot
$s = New-PSSession -ComputerName $src_server
Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $ogg_home, $ggsci_command

############################
##Create/Edit Param file
##Invoke-Command -Session $s -FilePath Edit-OggPram.ps1 -ArgumentList $ogg_home, $proc_name, $statement
##(TBD) Add -append switch
############################
$type = 'EXTRACT'
$proc_name = 'cdcext'
$trail_name = 'ce'
$statement = @"
$type $proc_name
SOURCEDB $dsn
EXTTRAIL ./dirdat/$trail_name

TABLE dbo.*;
"@

Invoke-Command -Session $s -FilePath Edit-OggPram.ps1 -ArgumentList $ogg_home, $proc_name, $statement

$type = 'EXTRACT'
$proc_name = 'cdcpmp'
$trail_name = 'cp'
$statement = @"
$type $proc_name
RMTHOST $tgt_server MGRPORT $tgt_mgr_port
RMTTRAIL ./dirdat/$trail_name

TABLE dbo.*;
"@

Invoke-Command -Session $s -FilePath Edit-OggPram.ps1 -ArgumentList $ogg_home, $proc_name, $statement



Remove-PSSession $s

