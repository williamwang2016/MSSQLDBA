$src_server = 'SQL1'
$tgt_server = 'SQL2'
$ogg_tgt_home = 'C:\OGG'
$ogg_tgt_dsn = 'ogg_tgt_dsn'
$mgr_port = 7809

#DELETE TRANDATA
$ggsci_command = @"
STOP ER *
STOP mgr!
DBLOGIN SOURCEDB $ogg_tgt_dsn
DELETE CHECKPOINTTABLE ogg.ggcheck
DELETE REPLICAT *!
"@

$ggsci_command | Out-File -FilePath $ogg_tgt_home\dirsql\deleterep.txt -Encoding ascii

$command = "CMD /c echo OBEY $ogg_tgt_home\dirsql\deleterep.txt | $ogg_tgt_home\ggsci.exe"
Invoke-Expression $command

Set-Location $ogg_tgt_home
$command = "CMD /c install deleteevents deleteservice"
Invoke-Expression $command

Remove-Item $ogg_tgt_home/dirdat/*
