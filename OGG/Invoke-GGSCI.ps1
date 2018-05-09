Param
(
    [string] $ogg_home,
    [string] $ggsci_command
)

$filename = 'ggsci_command_' + (Get-Date).ToString('yyyyMMddHHmmssfff')
$obey_filename = $filename + '.oby'
$output_filename = $filename + '.out'
$ggsci_command | Out-File -FilePath $ogg_home\dirsql\$obey_filename -Encoding ascii

$command = "CMD /c echo OBEY $ogg_home\dirsql\$obey_filename | $ogg_home\ggsci.exe > $ogg_home\dirsql\$output_filename"
Invoke-Expression $command

#(TBD) Analyze $output_filename and return any error
