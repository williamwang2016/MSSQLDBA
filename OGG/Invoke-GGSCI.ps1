############################
##Execute GGSCI commands
##Example: 
##Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command
############################

Param
(
    [string] $ogg_home,
    [string] $ggsci_command
)

$filename = 'ggsci_command_' + (Get-Date).ToString('yyyyMMddHHmmssfff')
$obey_filename = $filename + '.oby'
$output_filename = $filename + '.out'
$output_path = "$ogg_home\dirout"
New-Item -Force -Path $output_path -ItemType Directory > $null
$ggsci_command | Out-File -FilePath $output_path\$obey_filename -Encoding ascii -Force

$command = "CMD /c echo OBEY $output_path\$obey_filename | $ogg_home\ggsci.exe > $output_path\$output_filename"
Invoke-Expression $command
Get-Content $output_path\$output_filename

#(TBD) Analyze $output_filename and return any error
