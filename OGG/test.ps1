$src_server = 'S1'
$src_mgr_port = 7809
$tgt_server = 'S2'
$tgt_mgr_port = 7809
$src_ogg_home = 'C:\OGG'
$tgt_ogg_home = 'C:\OGG'
$src_dsn = 'ogg_dsn'
$tgt_dsn = 'ogg_dsn'

Set-Location $PSScriptRoot
$s = New-PSSession -ComputerName $src_server

############################
##Execute GGSCI commands
##Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $ogg_home, $ggsci_command
############################
$ggsci_command = @"
DBLOGIN SOURCEDB $src_dsn
ADD TRANDATA dbo.*
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command

############################
##Create/Edit Param file
##Invoke-Command -Session $s -FilePath Edit-OggPram.ps1 -ArgumentList $ogg_home, $proc_name, $statement
##(TBD) Add -append switch
############################
$extract_name = 'cdcext'
$local_trail_name = 'ce'

$statement = @"
EXTRACT $extract_name
SOURCEDB $src_dsn
EXTTRAIL ./dirdat/$local_trail_name

TABLE dbo.*;
"@

Invoke-Command -Session $s -FilePath Edit-OggPram.ps1 -ArgumentList $src_ogg_home, $extract_name, $statement

#Add Extract
$ggsci_command = @"
ADD EXTRACT $extract_name, TRANLOG, BEGIN NOW
ADD EXTTRAIL ./dirdat/$local_trail_name, EXTRACT $extract_name
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command

#Add Pump
$pump_name = 'cdcpmp'
$remote_trail_name = 'cp'

$statement = @"
EXTRACT $pump_name
RMTHOST $tgt_server MGRPORT $tgt_mgr_port
RMTTRAIL ./dirdat/$remote_trail_name

TABLE dbo.*;
"@

Invoke-Command -Session $s -FilePath Edit-OggPram.ps1 -ArgumentList $src_ogg_home, $pump_name, $statement


$ggsci_command = @"
ADD EXTRACT $pump_name, EXTTRAILSOURCE ./dirdat/$local_trail_name
ADD RMTTRAIL ./dirdat/$remote_trail_name, EXTRACT $pump_name
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command



Remove-PSSession $s

