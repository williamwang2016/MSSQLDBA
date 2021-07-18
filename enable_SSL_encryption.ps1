$cert_serialnumber = ''
$sqlinstance = ''

$service_account = (Invoke-Sqlcmd -ServerInstance $sqlinstance -Query "select service_account from sys.dm_server_services where filename like '%sqlservr.exe%'").service_account
$cert = (Get-ChildItem -path cert:/LocalMachine/My | Where-Object {$_.SerialNumber -eq $cert_serialnumber} | Sort-Object -property NotAfter -descending | Select-Object -First 1)

# --------------------------------------------------------
# Grant Read permission to the SQL Service startup account
# --------------------------------------------------------

# Specify the user, the permissions and the permission type
$permission = "$($service_account)","Read","Allow" 
$accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission

# Location of the machine related keys
$keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"
$keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$keyFullPath = $keyPath + $keyName

try {  
  # Get the current acl of the private key
  $acl = Get-Acl -Path $keyFullPath

  # Add the new ace to the acl of the private key 
  $acl.AddAccessRule($accessRule)

  # Write back the new acl
  Set-Acl -Path $keyFullPath -AclObject $acl
}
catch  
{
  throw $_
}

# --------------------------------------------------------
# Enable Encryption on SQL Server
# --------------------------------------------------------

# Change the thrumbprint of the certificate in registry
$thumbprint = $cert.Thumbprint.ToLower()
$query_assign_thumbprint = "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib', N'Certificate', REG_SZ, N'$thumbprint'"
Invoke-Sqlcmd -ServerInstance $sqlinstance -Query $query_assign_thumbprint

# Enable Force Encryption
$query_enable_forceencryption = "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib', N'ForceEncryption', REG_DWORD, 1"
Invoke-Sqlcmd -ServerInstance $sqlinstance -Query $query_enable_forceencryption