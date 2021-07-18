param($action, $VirtualServerName, $IP, $version, $AS, $IS, $RS)

#The params below are not likely to change
$features="SQL,Tools"
$domain = $env:userdomain
$VirtualServerName = $VirtualServerName.ToUpper()

#Get gMSA name
$i = $VirtualServerName.IndexOf("WC")
$serviceaccountname = $domain+"\_g_"+$VirtualServerName.Substring(0,$i)+"WC"+$VirtualServerName.Substring($i+2,2)+'$'

$adminDL = $domain+"\xxxxxx"
$sqlcollation="SQL_Latin1_General_CP1_CI_AS"
$ascollation="Latin1_General_CI_AS"
$InstanceName='SQL'+$VirtualServerName[-1] #require customization
if ($version -eq "2008" -or $version -eq "2008R2")
{
	$header = "[SQLSERVER2008]"
}
else
{
	$header = "[OPTIONS]"
}

New-Item "C:\install" -Force -type directory | Out-Null

#Generate ini for the 1st node
if ($action -eq "InstallFailoverCluster")
{
	Import-Module FailoverClusters
	$disks = Get-ClusterResource | Where-Object {$_.ResourceType.Name -eq "Physical Disk" -and $_.OwnerGroup.Name -eq $InstanceName}
	$clusterdisks = '"'+[string]::join('" "',$disks)+'"'
	$clusternetwork = Get-ClusterNetwork | Where-Object {$_.role -eq 3}
	$public = $clusternetwork.Name
	$subnet = $clusternetwork.Addressmask

	#specify the full path of each volume and create a subfolder named dba under each volume
	if ($VirtualServerName[-1] -eq "1")#require customization for the whole if {} block
	{
		if ((Test-Path "D:\") `
		-and (Test-Path "E:\")`
		-and (Test-Path "F:\"))
		{
			$data_dir=(New-Item "D:\MSSQL" -Force -type directory).Fullname
			$log_dir=(New-Item "E:\MSSQL" -Force -type directory).Fullname
			$tempdb_dir=(New-Item "F:\MSSQL" -Force -type directory).FullName
			$backup_dir=$data_dir
			if ($AS)
			{
				$as_data_dir=(New-Item "D:\MSSQL\OLAP\data" -Force -type directory).Fullname
				$as_log_dir=(New-Item "E:\MSSQL\OLAP\log" -Force -type directory).Fullname
				$as_temp_dir=(New-Item "F:\MSSQL\OLAP\temp" -Force -type directory).FullName
				$as_backup_dir=(New-Item "D:\MSSQL\OLAP\backup" -Force -type directory).FullName
				$as_config_dir=(New-Item "D:\MSSQL\OLAP\config" -Force -type directory).FullName
			}
		}
		else
		{
			Write-Host "Data, Log, Tempdb or Backup path doesn't meet standard"
			break
		}
	}
	elseif ($VirtualServerName[-1] -eq "2")#require customization for the whole elseif {} block
	{
		if ((Test-Path "J:\") `
		-and (Test-Path "K:\")`
		-and (Test-Path "L:\"))
		{
			$data_dir=(New-Item "J:\MSSQL" -Force -type directory).Fullname
			$log_dir=(New-Item "K:\MSSQL" -Force -type directory).Fullname
			$tempdb_dir=(New-Item "L:\MSSQL" -Force -type directory).FullName
			$backup_dir=$data_dir
			if ($AS)
			{
				$as_data_dir=(New-Item "J:\MSSQL\OLAP\data" -Force -type directory).Fullname
				$as_log_dir=(New-Item "K:\MSSQL\OLAP\log" -Force -type directory).Fullname
				$as_temp_dir=(New-Item "L:\MSSQL\OLAP\temp" -Force -type directory).FullName
				$as_backup_dir=(New-Item "J:\MSSQL\OLAP\backup" -Force -type directory).FullName
				$as_config_dir=(New-Item "J:\MSSQL\OLAP\config" -Force -type directory).FullName
			}
		}
		else
		{
			Write-Host "Data, Log, Tempdb or Backup path doesn't meet standard"
			break
		}
	}
	elseif ($VirtualServerName[-1] -eq "3")#require customization for the whole elseif {} block
	{
		if ((Test-Path "R:\") `
		-and (Test-Path "S:\")`
		-and (Test-Path "T:\"))
		{
			$data_dir=(New-Item "R:\MSSQL" -Force -type directory).Fullname
			$log_dir=(New-Item "S:\MSSQL" -Force -type directory).Fullname
			$tempdb_dir=(New-Item "T:\MSSQL" -Force -type directory).FullName
			$backup_dir=$data_dir
			if ($AS)
			{
				$as_data_dir=(New-Item "R:\MSSQL\OLAP\data" -Force -type directory).Fullname
				$as_log_dir=(New-Item "S:\MSSQL\OLAP\log" -Force -type directory).Fullname
				$as_temp_dir=(New-Item "T:\MSSQL\OLAP\temp" -Force -type directory).FullName
				$as_backup_dir=(New-Item "R:\MSSQL\OLAP\backup" -Force -type directory).FullName
				$as_config_dir=(New-Item "R:\MSSQL\OLAP\config" -Force -type directory).FullName
			}
		}
		else
		{
			Write-Host "Data, Log, Tempdb or Backup path doesn't meet standard"
			break
		}	
	}

	$conf = @"
$header
ACTION="$action"
ENU="True"
UpdateEnabled="True"
UpdateSource="\\xxxxxx\install\Patch"
FAILOVERCLUSTERGROUP="$InstanceName"
INSTANCENAME="$InstanceName"
FAILOVERCLUSTERDISKS=$clusterdisks
FAILOVERCLUSTERIPADDRESSES="IPv4;$IP;$public;$subnet"
FAILOVERCLUSTERNETWORKNAME="$VirtualServerName"
AGTSVCACCOUNT="$serviceaccountname"
INSTALLSQLDATADIR="$data_dir"
SQLBACKUPDIR="$backup_dir"
SQLCOLLATION="$sqlcollation"
SQLSVCACCOUNT="$serviceaccountname"
SQLSYSADMINACCOUNTS="$adminDL"
SQLTEMPDBDIR="$tempdb_dir"
SQLTEMPDBLOGDIR="$tempdb_dir"
SQLUSERDBDIR="$data_dir"
SQLUSERDBLOGDIR="$log_dir"
QUIET="True"
INDICATEPROGRESS="False"
HIDECONSOLE="True"

"@

	$SSAS = @"
ASSVCACCOUNT="$serviceaccountname"
ASSYSADMINACCOUNTS="$adminDL"
ASBACKUPDIR="$as_backup_dir"
ASCOLLATION="$ascollation"
ASCONFIGDIR="$as_config_dir"
ASDATADIR="$as_data_dir"
ASLOGDIR="$as_log_dir"
ASTEMPDIR="$as_temp_dir"

"@

	$SSIS = @"
ISSVCACCOUNT="$serviceaccountname"

"@

	$SSRS = @"
RSSVCACCOUNT="$serviceaccountname"

"@

	if ($AS)
	{
		$features = $features + ",AS"
		$conf = $conf + $SSAS
	}
	if ($IS)
	{
		$features = $features + ",IS"
		$conf = $conf + $SSIS
	}
	if ($RS)
	{
		$features = $features + ",RS"
		$conf = $conf + $SSRS
	}
	
	$conf = $conf + "FEATURES=$features`r`n"
	
	if ($version -ne "2008")
	{
		$conf = $conf + 'IACCEPTSQLSERVERLICENSETERMS="True"'
	}	
	$conf | out-file -FilePath "C:\install\ConfigurationFile.ini"
}

elseif ($action -eq "AddNode")
{
	$conf = @"
$header
ACTION="$action"
ENU="True"
UpdateEnabled="True"
UpdateSource="\\xxxxx\Patch"
INSTANCENAME="$InstanceName"
AGTSVCACCOUNT="$serviceaccountname"
SQLSVCACCOUNT="$serviceaccountname"
QUIET="True"
INDICATEPROGRESS="False"
HIDECONSOLE="True"

"@


	$SSAS = @"
ASSVCACCOUNT="$serviceaccountname"

"@

	$SSIS = @"

"@

	$SSRS = @"

"@


	if ($version -ne "2008" -and $version -ne "2008R2")
	{
		import-module failoverclusters
		$clusternetwork = Get-ClusterNetwork | Where-Object {$_.role -eq 3}
		$public = $clusternetwork.Name
		$subnet = $clusternetwork.Addressmask
		$clusterIP = @"
FAILOVERCLUSTERIPADDRESSES="IPv4;$IP;$public;$subnet"

"@
		$conf = $conf + $clusterIP
	}
	if ($AS)
	{
		$conf = $conf + $SSAS
	}
	if ($IS)
	{
		$conf = $conf + $SSIS
	}
	if ($RS)
	{
		$conf = $conf + $SSRS
	}
	if ($version -ne "2008")
	{
		$conf = $conf + 'IACCEPTSQLSERVERLICENSETERMS="True"'
	}	
	$conf | out-file -FilePath "C:\install\ConfigurationFile.ini"
}

#Install Stand-alone
elseif ($action -eq "Install")
{

}
