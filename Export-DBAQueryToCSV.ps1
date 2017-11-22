$instancename = ""

$query = @"

"@
Invoke-Sqlcmd -ServerInstance $instanceName -Query $query -QueryTimeout 65535|Export-Csv -NoType "QueryResult_$instancename.csv"
