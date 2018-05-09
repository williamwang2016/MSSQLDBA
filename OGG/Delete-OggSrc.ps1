$src_server = 'SQL1'
$tgt_server = 'SQL2'
$ogg_src_home = 'C:\OGG'
$ogg_src_dsn = 'ogg_src_dsn'
$mgr_port = 7809

#DELETE TRANDATA
$ggsci_command = @"
STOP ER *
STOP mgr!
DBLOGIN SOURCEDB $ogg_src_dsn
DELETE TRANDATA dbo.*
DELETE *!
"@

$ggsci_command | Out-File -FilePath $ogg_src_home\dirsql\deletetran.txt -Encoding ascii

$command = "CMD /c echo OBEY $ogg_src_home\dirsql\deletetran.txt | $ogg_src_home\ggsci.exe"
Invoke-Expression $command

Set-Location $ogg_src_home
$command = "CMD /c install deleteevents deleteservice"
Invoke-Expression $command

Remove-Item $ogg_src_home/dirdat/*
