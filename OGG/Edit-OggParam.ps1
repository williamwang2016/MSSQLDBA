############################
##Edit param for a process
##Example: 
##Invoke-Command -Session $s -FilePath Edit-Param.ps1 -ArgumentList $src_ogg_home, $proc_name, $operator, $schema_name, $table_name
############################
Param
(
    [string] $ogg_home,
    [string] $proc_name,
    [string] $operator,
    [string] $schema_name,
    [string] $table_name
)

$filename = $proc_name + '.prm'
$filepath = "$ogg_home\dirprm\$filename"
$prm = Get-Content $filepath

#Psedu code
if (-not ($prm -contains "$schema_name.*"))
{
    if ($operator -eq 'ADD')
        "TABLE $schema_name.$tablename;" | Out-File $filepath -Encoding ascii -Append
    elseif ($operator -eq 'DEL')
        $prm.Replace("TABLE $schema_name.$tablename;")
}
