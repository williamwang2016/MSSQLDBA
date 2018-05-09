$src_server = 'SQL1'
$tgt_server = 'SQL2'
$ogg_src_home = 'C:\OGG'
$ogg_src_dsn = 'ogg_src_dsn'
$ogg_tgt_home = 'C:\OGG'
$ogg_tgt_dsn = 'ogg_tgt_dsn'
$mgr_port =7809

#CREATE SUBDIRS
$command = "CMD /c echo CREATE SUBDIRS | $ogg_tgt_home\ggsci.exe"
Invoke-Expression $command

#Install OGG as a service
$command = "$ogg_src_home\Install ADDSERVICE"
Invoke-Expression $command

#Create mgr.prm
"PORT $mgr_port" | Out-File -FilePath $ogg_tgt_home\dirprm\mgr.prm -Encoding ascii

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

"@

Invoke-Sqlcmd -ServerInstance $tgt_server -Query $query

#Create DSN
Get-OdbcDsn -Name $ogg_tgt_dsn | Remove-OdbcDsn
Add-OdbcDsn -Name $ogg_tgt_dsn -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=$tgt_server", "Trusted_Connection=Yes", "Database=Demo")

#Create GLOBALS on src
'GGSCHEMA ogg' | Out-File -FilePath $ogg_tgt_home\GLOBALS -Encoding ascii


#Create Replicat prm files
$replicat_name = 'cdcrep'
$remote_trail_name = 'cp'
$replicat_prm = @"
REPLICAT $replicat_name
TARGETDB $ogg_tgt_dsn

MAP dbo.*, TARGET dbo.*;
"@

$replicat_prm | Out-File -FilePath $ogg_tgt_home\dirprm\$replicat_name.prm -Encoding ascii

#Add Replicat
$ggsci_command = @"
DBLOGIN SOURCEDB $ogg_tgt_dsn
ADD CHECKPOINTTABLE ogg.ggcheck
ADD REPLICAT $replicat_name, EXTTRAIL ./dirdat/$remote_trail_name,CHECKPOINTTABLE ogg.ggcheck
"@

$ggsci_command | Out-File -FilePath $ogg_tgt_home\dirsql\add_replicat.txt -Encoding ascii

$command = "CMD /c echo OBEY $ogg_tgt_home\dirsql\add_replicat.txt | $ogg_src_home\ggsci.exe"
Invoke-Expression $command


