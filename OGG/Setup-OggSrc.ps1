$src_server = 'SQL1'
$tgt_server = 'SQL2'
$ogg_src_home = 'C:\OGG'
$ogg_src_dsn = 'ogg_src_dsn'
$mgr_port = 7809

#CREATE SUBDIRS
$command = "CMD /c echo CREATE SUBDIRS | $ogg_src_home\ggsci.exe"
Invoke-Expression $command

#Install OGG as a service
$command = "$ogg_src_home\Install ADDSERVICE"
Invoke-Expression $command

#Create mgr.prm
"PORT $mgr_port" | Out-File -FilePath $ogg_src_home\dirprm\mgr.prm -Encoding ascii

#Create Database

$query = @"
USE [master]
GO

IF EXISTS (SELECT 1 from sys.databases WHERE name = 'Demo')
    DROP DATABASE [Demo]
GO

CREATE DATABASE [Demo]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Active', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Active.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ), 
 FILEGROUP [Archive] 
( NAME = N'Archive', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Archive.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Demo_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Demo_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE [Demo]
GO
CREATE TABLE t1 (col1 INT)
GO
CREATE SCHEMA ogg
GO
BACKUP DATABASE Demo TO DISK = 'NUL:'
GO
"@

Invoke-Sqlcmd -ServerInstance $src_server -Query $query

#Create DSN
Get-OdbcDsn -Name $ogg_src_dsn | Remove-OdbcDsn
Add-OdbcDsn -Name $ogg_src_dsn -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=$src_server", "Trusted_Connection=Yes", "Database=Demo")

#Create GLOBALS on src
'GGSCHEMA ogg' | Out-File -FilePath $ogg_src_home\GLOBALS -Encoding ascii

#ADD TRANDATA
$ggsci_command = @"
DBLOGIN SOURCEDB $ogg_src_dsn
ADD TRANDATA dbo.*
"@

$ggsci_command | Out-File -FilePath $ogg_src_home\dirsql\addtran.txt -Encoding ascii

$command = "CMD /c echo OBEY $ogg_src_home\dirsql\addtran.txt | $ogg_src_home\ggsci.exe"
Invoke-Expression $command

#Remove the SQL Server CDC cleanup job
$query = @"
USE [Demo]
GO
EXECUTE sys.sp_cdc_drop_job N'cleanup'
GO
"@

Invoke-Sqlcmd -ServerInstance $src_server -Query $query

#Create the Oracle GoldenGate CDC cleanup job and associated objects
Set-Location $ogg_src_home
$command = "CMD /c ogg_cdc_cleanup_setup.bat createJob gg_user Cefjkj@7 Demo SQL1 ogg"
Invoke-Expression $command

#Create Extract and Pump prm files
$extract_name = 'cdcext'
$local_trail_name = 'ce'
$extract_prm = @"
EXTRACT $extract_name
SOURCEDB $ogg_src_dsn
EXTTRAIL ./dirdat/$local_trail_name

TABLE dbo.*;
"@

$extract_prm | Out-File -FilePath $ogg_src_home\dirprm\$extract_name.prm -Encoding ascii

$pump_name = 'cdcpmp'
$remote_trail_name = 'cp'
$pump_prm = @"
EXTRACT $pump_name
RMTHOST $tgt_server MGRPORT $mgr_port
RMTTRAIL ./dirdat/$remote_trail_name

TABLE dbo.*;
"@

$pump_prm | Out-File -FilePath $ogg_src_home\dirprm\$pump_name.prm -Encoding ascii

#Add Extract and Pump
$ggsci_command = @"
ADD EXTRACT $extract_name, TRANLOG, BEGIN NOW
ADD EXTTRAIL ./dirdat/$local_trail_name, EXTRACT $extract_name
ADD EXTRACT $pump_name, EXTTRAILSOURCE ./dirdat/$local_trail_name
ADD RMTTRAIL ./dirdat/$remote_trail_name, EXTRACT $pump_name
"@

$ggsci_command | Out-File -FilePath $ogg_src_home\dirsql\add_extract_and_pump.txt -Encoding ascii

$command = "CMD /c echo OBEY $ogg_src_home\dirsql\add_extract_and_pump.txt | $ogg_src_home\ggsci.exe"
Invoke-Expression $command

