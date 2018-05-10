$src_server = 'lvs1-ieodn-001'
$tgt_server = 'lvs1-ieodn-002'
$src_mgr_port = 7809
$tgt_mgr_port = 7809
$src_ogg_home = 'F:\OGG'
$tgt_ogg_home = 'G:\OGG'
$src_dsn = 'ogg_dsn'
$tgt_dsn = 'ogg_dsn'
$db_name = 'Demo'

Set-Location $PSScriptRoot
#cd 'C:\install\OGG'

############################
##Setup GG src
############################

$s = New-PSSession -ComputerName $src_server

#CREATE SUBDIRS
$ggsci_command = @"
CREATE SUBDIRS
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command


#Install OGG as a service
$expr = @"
$src_ogg_home\Install ADDSERVICE ADDEVENTS
"@
Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


#Create mgr.prm
$expr = @"
"PORT $src_mgr_port" | Out-File -FilePath $src_ogg_home\dirprm\mgr.prm -Encoding ascii
"@
Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


#Create Database
$query = @"
USE [master]
GO

IF EXISTS (SELECT 1 from sys.databases WHERE name = '$db_name')
    DROP DATABASE [$db_name]
GO

CREATE DATABASE [$db_name]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Active', FILENAME = N'C:\SQLData\Active.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ), 
 FILEGROUP [Archive] 
( NAME = N'Archive', FILENAME = N'C:\SQLData\Archive.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Demo_log', FILENAME = N'C:\SQLData\Demo_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE [$db_name]
GO
CREATE TABLE t1 (col1 INT)
GO
CREATE SCHEMA ogg
GO
BACKUP DATABASE [$db_name] TO DISK = 'NUL:'
GO
"@

Invoke-Sqlcmd -ServerInstance $src_server -Query $query


#Create DSN
$expr = @"
Get-OdbcDsn -Name $src_dsn -ErrorAction SilentlyContinue | Remove-OdbcDsn
Add-OdbcDsn -Name $src_dsn -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=$src_server", "Trusted_Connection=Yes", "Database=$db_name")
"@

Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


#Create GLOBALS on src
$expr = @"
'GGSCHEMA ogg' | Out-File -FilePath $src_ogg_home\GLOBALS -Encoding ascii
"@

Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


#ADD TRANDATA
$ggsci_command = @"
DBLOGIN SOURCEDB $src_dsn
ADD TRANDATA dbo.*
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command

#Edit Param Extract
$extract_name = 'cdcext'
$local_trail_name = 'ce'

$statement = @"
EXTRACT $extract_name
SOURCEDB $src_dsn
EXTTRAIL ./dirdat/$local_trail_name

TABLE dbo.*;
"@

Invoke-Command -Session $s -FilePath Edit-OggParam.ps1 -ArgumentList $src_ogg_home, $extract_name, $statement


#Add Extract
$ggsci_command = @"
ADD EXTRACT $extract_name, TRANLOG, BEGIN NOW
ADD EXTTRAIL ./dirdat/$local_trail_name, EXTRACT $extract_name
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command

#Edit Param Pump
$pump_name = 'cdcpmp'
$remote_trail_name = 'cp'

$statement = @"
EXTRACT $pump_name
RMTHOST $tgt_server MGRPORT $tgt_mgr_port
RMTTRAIL ./dirdat/$remote_trail_name

TABLE dbo.*;
"@

Invoke-Command -Session $s -FilePath Edit-OggParam.ps1 -ArgumentList $src_ogg_home, $pump_name, $statement

#Add Pump
$ggsci_command = @"
ADD EXTRACT $pump_name, EXTTRAILSOURCE ./dirdat/$local_trail_name
ADD RMTTRAIL ./dirdat/$remote_trail_name, EXTRACT $pump_name
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command


Remove-PSSession $s



############################
##Setup GG tgt
############################

$s = New-PSSession -ComputerName $tgt_server

#CREATE SUBDIRS
$ggsci_command = @"
CREATE SUBDIRS
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $tgt_ogg_home, $ggsci_command


#Install OGG as a service
$expr = @"
$tgt_ogg_home\Install ADDSERVICE ADDEVENTS
"@
Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


#Create mgr.prm
$expr = @"
"PORT $tgt_mgr_port" | Out-File -FilePath $tgt_ogg_home\dirprm\mgr.prm -Encoding ascii
"@
Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


#Create Database
$query = @"
USE [master]
GO

IF EXISTS (SELECT 1 from sys.databases WHERE name = '$db_name')
    DROP DATABASE [$db_name]
GO

CREATE DATABASE [$db_name]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Active', FILENAME = N'C:\SQLData\Active.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ), 
 FILEGROUP [Archive] 
( NAME = N'Archive', FILENAME = N'C:\SQLData\Archive.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Demo_log', FILENAME = N'C:\SQLData\Demo_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE [$db_name]
GO
CREATE TABLE t1 (col1 INT)
GO
CREATE SCHEMA ogg
GO
BACKUP DATABASE [$db_name] TO DISK = 'NUL:'
GO
"@

Invoke-Sqlcmd -ServerInstance $tgt_server -Query $query


#Create DSN
$expr = @"
Get-OdbcDsn -Name $tgt_dsn -ErrorAction SilentlyContinue | Remove-OdbcDsn 
Add-OdbcDsn -Name $tgt_dsn -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=$tgt_server", "Trusted_Connection=Yes", "Database=$db_name")
"@

Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


#Create GLOBALS on src
$expr = @"
'GGSCHEMA ogg' | Out-File -FilePath $tgt_ogg_home\GLOBALS -Encoding ascii
"@

Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}

#Edit Param Replicat
$replicat_name = 'cdcrep'

$statement = @"
REPLICAT $replicat_name
TARGETDB $tgt_dsn

MAP dbo.*, TARGET dbo.*;
"@

Invoke-Command -Session $s -FilePath Edit-OggParam.ps1 -ArgumentList $tgt_ogg_home, $replicat_name, $statement


#Add Replicat
$ggsci_command = @"
DBLOGIN SOURCEDB $tgt_dsn
ADD CHECKPOINTTABLE ogg.ggcheck
ADD REPLICAT $replicat_name, EXTTRAIL ./dirdat/$remote_trail_name, CHECKPOINTTABLE ogg.ggcheck
"@

Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $tgt_ogg_home, $ggsci_command


#Start Replicat
$ggsci_command = @"
START MGR
START REPLICAT $replicat_name
"@
Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $tgt_ogg_home, $ggsci_command

Remove-PSSession $s

#Start Extract
$s = New-PSSession -ComputerName $src_server
$ggsci_command = @"
START MGR
START EXTRACT $extract_name
START EXTRACT $pump_name
"@
Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command

Remove-PSSession $s
