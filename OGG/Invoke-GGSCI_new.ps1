function Invoke-GGSCI ($ComputerName, $OggHome, $Command) {
    $filename = 'ggsci_command_' + (Get-Date).ToString('yyyyMMddHHmmssfff')
    $output_path = "$OggHome\dirout"
    $obey_filename = $filename + '.oby'   #e.g. ggsci_command_20180512062332780.oby
    $output_filename = $filename + '.out' #e.g. ggsci_command_20180512062332780.out
    
    $exp = @"
            New-Item -Force -Path $output_path -ItemType Directory |  Out-Null
            '$Command' | Out-File -FilePath $output_path\$obey_filename -Encoding ascii -Force
            CMD /c echo OBEY $output_path\$obey_filename | $OggHome\ggsci.exe > $output_path\$output_filename
            Get-Content $output_path\$output_filename
"@
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {Invoke-Expression $Using:exp}
}

$ggsci_command = @"
INFO ALL
"@

$ggsci_command = @"
DBLOGIN SOURCEDB ogg_dsn
DELETE TRANDATA dbo.t3
"@

Invoke-GGSCI -ComputerName 'sqlserver-0' -OggHome 'c:\ogg' -Command $ggsci_command
Invoke-GGSCI -ComputerName 'sqlserver-1' -OggHome 'c:\ogg' -Command $ggsci_command