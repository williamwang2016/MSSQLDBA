$server = "."

Get-WmiObject win32_volume -ComputerName $server | Select-Object Caption, @{ Name="Free(GB)";Expression={"{0:N2}" -f ($_.FreeSpace/1Gb)} }, @{ Name="Capacity(GB)";Expression={"{0:N2}" -f ($_.Capacity/1Gb)} }, @{ Name="Free%";Expression={"{0:P2}" -f ($_.FreeSpace/$_.Capacity)} } | Format-Table
