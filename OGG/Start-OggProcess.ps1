
#Start Replicat
$ggsci_command = @"
START REPLICAT $replicat_name
"@
Invoke-Command -ComputerName $tgt_server -FilePath Invoke-GGSCI.ps1 -ArgumentList $tgt_ogg_home, $ggsci_command

#Start Extract
$ggsci_command = @"
START EXTRACT $extract_name
START EXTRACT $pump_name
"@
Invoke-Command -ComputerName $src_server -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command
