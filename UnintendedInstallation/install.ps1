param($Action, $installer, $VirtualServerName, $IP, $PrimaryNode, $SecondaryNode, $username, $password, $PSScriptRoot)

$global:successful=$False
$DEBUG = 0

switch -wildcard ($installer)
{
	<#"*SQL2008_*" 
	{
		$version="2008"
		$summary = "C:\Program Files\Microsoft SQL Server\100\Setup Bootstrap\Log\Summary.txt"
	}
	"*SQL2008R2_*"
	{
		$version="2008R2"
		$summary = "C:\Program Files\Microsoft SQL Server\100\Setup Bootstrap\Log\Summary.txt"
	}
	"*SQL2012_*"
	{
		$version="2012"
		$summary = "C:\Program Files\Microsoft SQL Server\110\Setup Bootstrap\Log\Summary.txt"
	}#>
	"*_2014w_SP2*"
	{
		$version="2014"
		$summary = "C:\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log\Summary.txt"
	}	
	"*_2016w_SP1*"
	{
		$version="2016"
		$summary = "C:\Program Files\Microsoft SQL Server\130\Setup Bootstrap\Log\Summary.txt"
	}
}


function installon ($node)
{
	$hostname=hostname
	if ($node -eq $hostname)
	{
		$s = New-PSSession
	}
	else
	{
		$s = New-PSSession -ComputerName $node
	}

	Write-Host "Generating Configuration.ini on $node"

	Invoke-Command -Session $s -FilePath "$PSScriptRoot\sql_conf_gen.ps1" -ArgumentList $Action, $VirtualServerName, $IP, $version
	if (-not $DEBUG)
	{
	Invoke-Command -Session $s -ScriptBlock { set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing' State "0x23e00" }
	Invoke-Command -Session $s -ScriptBlock { param($Action, $username, $password, $installer) schtasks /F /create /tn $Action /ru $username /rp $password /sc once /st "23:00:00" /tr "$installer\setup.exe /SkipRules=Cluster_IsWMIServiceOperational /ConfigurationFile=C:\install\ConfigurationFile.INI" } -ArgumentList $Action, $username, $password, $installer
	Start-Sleep -Seconds 2
	Invoke-Command -Session $s -ScriptBlock { param($Action) schtasks /run /tn $Action } -ArgumentList $Action

	#Keep checking the status until it is not Running
	Start-Sleep -Seconds 2
	while ((Invoke-Command -Session $s -ScriptBlock { param($Action) (schtasks /Query /fo csv /tn $Action) } -ArgumentList $Action|ConvertFrom-Csv).status -eq "Running")
	{
		Write-Host "Installation is in progress"
		Start-Sleep -Seconds 60
	}
	}
	
	$r = Invoke-Command -Session $s -ScriptBlock { param($file) (Select-String $file -Pattern "Final result" | Select-Object -First 1).tostring() } -ArgumentList $summary
	if ($r)
	{$global:successful = $r.contains("Passed")}
	else
	{$global:successful = $False}

	if ($global:successful)
	{
		Write-Host "$VirtualServerName is installed successfully on $node"
		if (-not $DEBUG)
		{
		Invoke-Command -Session $s -ScriptBlock { param($Action) schtasks /delete /tn $Action /f } -ArgumentList $Action
		}
		Invoke-Command -Session $s -ScriptBlock { Remove-item C:\install\ConfigurationFile.INI }
		
	}
	else
	{
		Write-Host "$VirtualServerName installation failed on $node"
	}
	
	Remove-PSSession $s
}

function configOn ($node)
{
	$hostname=hostname
	if ($node -eq $hostname)
	{
	$s = New-PSSession
	}
	else
	{
		$s = New-PSSession -ComputerName $node
	}
	Invoke-Command -Session $s -FilePath "$PSScriptRoot\sql_standardization.ps1" -ArgumentList $VirtualServerName
	Remove-PSSession $s
#	Write-Host "Generating maintainance jobs on $VirtualServerName"
#	sqlcmd -S "tcp:$VirtualServerName,1433" -E -i "$PSScriptRoot\MaintenanceSolution_eBay.sql"
}


#--------Main Program--------------
#----------------------------------
if ($Action -eq "InstallFailoverCluster")
{
	installon($PrimaryNode)
	if($global:successful)
	{
		$Action = "AddNode"
		installon($SecondaryNode)
		if($global:successful)
		{
			Write-Host "$VirtualServerName is installed successfully on $PrimaryNode and $SecondaryNode"
			Write-Host "Configuring $VirtualServerName"
			configOn($PrimaryNode)
		}
	}
}
elseif ($Action -eq "AddNode")
{
	installon($SecondaryNode)
	if($global:successful)
	{	
		Write-Host "Configuring $VirtualServerName"
		configOn($PrimaryNode)
	}
}
