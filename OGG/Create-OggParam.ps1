############################
##Create/Edit Param file
##Example:
##Invoke-Command -Session $s -FilePath Edit-OggPram.ps1 -ArgumentList $src_ogg_home, $pump_name, $statementInvoke-Command -Session $s -FilePath Edit-OggPram.ps1 -ArgumentList $ogg_home, $proc_name, $statement
##(TBD) Add -append switch
############################


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
