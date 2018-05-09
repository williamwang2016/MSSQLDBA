<#
1.	(Source system) In GGSCI, issue the SEND EXTRACT command with the LOGEND option until it returns a YES status, indicating that there is no more data to process.

SEND EXTRACT group LOGEND

2.	(Source system) In GGSCI, stop Extract and data pumps.

STOP EXTRACT group

STOP EXTRACT pump_group

3.	(Target systems) In GGSCI on each target system, issue the SEND REPLICAT command with the STATUS option until it shows a status of "At EOF" to indicate that it finished processing all of the data in the trail. This must be done on all target systems until all Replicat processes return "At EOF."

SEND REPLICAT group STATUS

4.	(Target systems) In GGSCI, stop all Replicat processes.

STOP REPLICAT group
#>

$src_server = 'SQL1'
$tgt_server = 'SQL2'

$ogg_src_home = 'C:\OGG'
$ogg_src_dsn = 'ogg_src_dsn'
$ogg_tgt_home = 'C:\OGG'
$ogg_tgt_dsn = 'ogg_tgt_dsn'

$extract_name = 'cdcext'
$pump_name = 'cdcpmp'
$replicat_name = 'cdcrep'

#1.(Source system) In GGSCI, issue the SEND EXTRACT command with the LOGEND option until it returns a YES status, indicating that there is no more data to process.
$command = "CMD /c echo SEND EXTRACT $extract_name LOGEND | $ogg_src_home\ggsci.exe"
Do
{
    $r = Invoke-Command -ComputerName $src_server -ScriptBlock {Invoke-Expression $Using:command}
    $r = $r | Out-String
    Start-Sleep 1
} While(-not ($r.Contains('YES') -or $r.Contains('not currently running')))

#2.(Source system) In GGSCI, stop Extract and data pumps.
$command = "CMD /c echo STOP EXTRACT $extract_name | $ogg_src_home\ggsci.exe"
Invoke-Command -ComputerName $src_server -ScriptBlock {Invoke-Expression $Using:command}

$command = "CMD /c echo STOP EXTRACT $pump_name | $ogg_src_home\ggsci.exe"
Invoke-Command -ComputerName $src_server -ScriptBlock {Invoke-Expression $Using:command}


#3.(Target systems) In GGSCI on each target system, issue the SEND REPLICAT command with the STATUS option until it shows a status of "At EOF" to indicate that it finished processing all of the data in the trail. This must be done on all target systems until all Replicat processes return "At EOF."
$command = "CMD /c echo SEND REPLICAT $replicat_name STATUS | $ogg_tgt_home\ggsci.exe"
Do
{
    $r = Invoke-Command -ComputerName $tgt_server -ScriptBlock {Invoke-Expression $Using:command}
    $r = $r | Out-String
    Start-Sleep 1
} While(-not $r.Contains('Current status: At EOF'))

#4.(Target systems) In GGSCI, stop all Replicat processes.
$command = "CMD /c echo STOP REPLICAT $replicat_name | $ogg_tgt_home\ggsci.exe"
Invoke-Command -ComputerName $tgt_server -ScriptBlock {Invoke-Expression $Using:command}

