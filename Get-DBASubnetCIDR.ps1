$computer_name = "."
$subnet = 0
$nic = Get-WmiObject -computer $computer_name -class "win32_networkadapterconfiguration" | Where-Object {$_.defaultIPGateway -ne $null}
$IP = $nic.ipaddress | select-object -first 1
$ClientMask = $nic.ipsubnet | select-object -first 1
(($ClientMask -split '\.' | ForEach-Object { [convert]::ToString($_,2) } ) -join '').tochararray() | ForEach-Object { $subnet += ([convert]::ToInt32($_)-48)}
$IP + '/' + $subnet
