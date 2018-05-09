Param
(
    [string] $ogg_home,
    [string] $proc_name,
    [string] $statement
    #[switch] $append
)

$param_filename = $proc_name + '.prm'
$statement| Out-File -FilePath $ogg_home\dirprm\$param_filename -Encoding ascii


#(TBD) Error handling
