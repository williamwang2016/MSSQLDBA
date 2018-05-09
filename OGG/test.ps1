$remote_computer = 'S1'
$ogg_home = 'C:\OGG'
$dsn = 'ogg_dsn'

$ggsci_command = @"
DBLOGIN SOURCEDB $dsn
ADD TRANDATA dbo.*
"@

Set-Location $PSScriptRoot
$s = New-PSSession -ComputerName $remote_computer
Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $ogg_home, $ggsci_command
