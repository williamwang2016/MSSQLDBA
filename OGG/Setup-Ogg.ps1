$src_server = 'sqlserver-0'
$tgt_server = 'sqlserver-1'
$src_mgr_port = 7809
$tgt_mgr_port = 7809
$src_ogg_home = 'C:\OGG'
$tgt_ogg_home = 'C:\OGG'
$src_dsn = 'ogg_dsn'
$tgt_dsn = 'ogg_dsn'
$db_name = 'Demo'
$extract_name = 'cdcext'
$pump_name = 'cdcpmp'
$local_trail_name = 'ce'
$remote_trail_name = 'cp'
$replicat_name = 'cdcrep'


Import-Module SqlServer
#Set-Location $PSScriptRoot
cd 'C:\Users\ogguser\Documents\GitHub\MSSQLDBA\OGG'


function Install-OGG ($SourceComputerName, $SourceDsnName, $SourceOggHome, $SourceMgrPort, $TargetComputerName, $TargetDsnName, $TargetOggHome, $TargetMgrPort, $DatabaseName, $ExtractName, $PumpName, $ReplicatName, $LocalTrailName, $RemoteTrailName) {
    ############################
    ##Setup GG src
    ############################

    $s = New-PSSession -ComputerName $SourceComputerName

    #CREATE SUBDIRS
    $ggsci_command = @"
    CREATE SUBDIRS
"@

    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $SourceOggHome, $ggsci_command


    #Install OGG as a service
    $expr = @"
    $SourceOggHome\Install ADDSERVICE ADDEVENTS
"@
    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


    #Create mgr.prm
    $expr = @"
    "PORT $SourceMgrPort" | Out-File -FilePath $SourceOggHome\dirprm\mgr.prm -Encoding ascii
"@
    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


    #Create Database
    $query = @"
    USE [master]
    GO

    IF EXISTS (SELECT 1 from sys.databases WHERE name = '$DatabaseName')
    BEGIN
        ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
        DROP DATABASE [$DatabaseName]
    END
    GO

    CREATE DATABASE [$DatabaseName]
     CONTAINMENT = NONE
     ON  PRIMARY 
    ( NAME = N'Active', FILENAME = N'C:\SQLData\$($DatabaseName)_Active.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ), 
     FILEGROUP [Archive] 
    ( NAME = N'Archive', FILENAME = N'C:\SQLData\$($DatabaseName)_Archive.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
     LOG ON 
    ( NAME = N'$($DatabaseName)_log', FILENAME = N'C:\SQLData\$($DatabaseName)_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    GO

    USE [$DatabaseName]
    GO
    CREATE TABLE t1 (col1 INT)
    GO
    CREATE SCHEMA ogg
    GO
    BACKUP DATABASE [$DatabaseName] TO DISK = 'NUL:'
    GO
"@

    Invoke-Sqlcmd -ServerInstance $SourceComputerName -Query $query


    #Create DSN
    $expr = @"
    Get-OdbcDsn -Name $SourceDsnName -ErrorAction SilentlyContinue | Remove-OdbcDsn 
    Add-OdbcDsn -Name $SourceDsnName -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=$SourceComputerName", "Trusted_Connection=Yes", "Database=$DatabaseName")
"@

    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


    #Create GLOBALS on src
    $expr = @"
    'GGSCHEMA ogg' | Out-File -FilePath $SourceOggHome\GLOBALS -Encoding ascii
"@

    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


    #ADD TRANDATA
    $ggsci_command = @"
    DBLOGIN SOURCEDB $SourceDsnName
    ADD TRANDATA dbo.*
    --ADD HEARTBEATTABLE
"@

    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $SourceOggHome, $ggsci_command

    #Change CDC job polling interval
    $query = @"
    USE $DatabaseName
    GO
    --changes polling interveral from 5 seconds to 1 second
    EXEC [sys].[sp_cdc_change_job] @job_type = N'capture', @pollinginterval = 1
    GO
    WAITFOR DELAY '00:00:01'
    --stops cdc job
    EXEC [sys].[sp_cdc_stop_job] @job_type = N'capture'
    GO
    WAITFOR DELAY '00:00:01'
    --restarts cdc job for new polling interval to take affect
    EXEC [sys].[sp_cdc_start_job] @job_type = N'capture'
    GO
"@

    Invoke-Sqlcmd -ServerInstance $SourceComputerName -Query $query

    #Remove the SQL Server CDC cleanup job
    $query = @"
    USE [$DatabaseName]
    GO
    EXECUTE sys.sp_cdc_drop_job N'cleanup'
    GO
"@

    Invoke-Sqlcmd -ServerInstance $SourceComputerName -Query $query


    #Create the Oracle GoldenGate CDC cleanup job and associated objects
    $expr = @"
    Set-Location $SourceOggHome
    cmd /c ogg_cdc_cleanup_setup.bat createJob gg_user Pass@word01! $DatabaseName $SourceComputerName ogg
"@
    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


    #Edit Param Extract

    $statement = @"
    EXTRACT $ExtractName
    SOURCEDB $SourceDsnName
    EXTTRAIL ./dirdat/$LocalTrailName
    --To support TLS 1.2, add the following param
    --DBOPTIONS DRIVER SQLNCLI11

    TABLE dbo.*;
"@

    Invoke-Command -Session $s -FilePath Create-OggParam.ps1 -ArgumentList $SourceOggHome, $ExtractName, $statement


    #Add Extract
    $ggsci_command = @"
    ADD EXTRACT $ExtractName, TRANLOG, BEGIN NOW
    ADD EXTTRAIL ./dirdat/$LocalTrailName, EXTRACT $ExtractName
"@

    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $SourceOggHome, $ggsci_command

    #Edit Param Pump
    $statement = @"
    EXTRACT $PumpName
    RMTHOST $TargetComputerName MGRPORT $TargetMgrPort
    RMTTRAIL ./dirdat/$RemoteTrailName

    TABLE dbo.*;
"@

    Invoke-Command -Session $s -FilePath Create-OggParam.ps1 -ArgumentList $SourceOggHome, $PumpName, $statement

    #Add Pump
    $ggsci_command = @"
    ADD EXTRACT $PumpName, EXTTRAILSOURCE ./dirdat/$LocalTrailName
    ADD RMTTRAIL ./dirdat/$RemoteTrailName, EXTRACT $PumpName
"@

    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $SourceOggHome, $ggsci_command

    #Add HeartBeatTable
    $ggsci_command = @"
    DBLOGIN SOURCEDB $SourceDsnName
    ADD HEARTBEATTABLE
"@

    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $SourceOggHome, $ggsci_command


    Remove-PSSession $s



    ############################
    ##Setup GG tgt
    ############################

    $s = New-PSSession -ComputerName $TargetComputerName

    #CREATE SUBDIRS
    $ggsci_command = @"
    CREATE SUBDIRS
"@

    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $TargetOggHome, $ggsci_command


    #Install OGG as a service
    $expr = @"
    $TargetOggHome\Install ADDSERVICE ADDEVENTS
"@
    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


    #Create mgr.prm
    $expr = @"
    "PORT $TargetMgrPort" | Out-File -FilePath $TargetOggHome\dirprm\mgr.prm -Encoding ascii
"@
    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


    #Create Database
    $query = @"
    USE [master]
    GO

    IF EXISTS (SELECT 1 from sys.databases WHERE name = '$DatabaseName')
    BEGIN
        ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
        DROP DATABASE [$DatabaseName]
    END
    GO

    CREATE DATABASE [$DatabaseName]
     CONTAINMENT = NONE
     ON  PRIMARY 
    ( NAME = N'Active', FILENAME = N'C:\SQLData\Active.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ), 
     FILEGROUP [Archive] 
    ( NAME = N'Archive', FILENAME = N'C:\SQLData\Archive.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
     LOG ON 
    ( NAME = N'$($DatabaseName)_log', FILENAME = N'C:\SQLData\$($DatabaseName)_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    GO

    USE [$DatabaseName]
    GO
    CREATE TABLE t1 (col1 INT)
    GO
    CREATE SCHEMA ogg
    GO
    BACKUP DATABASE [$DatabaseName] TO DISK = 'NUL:'
    GO
"@

    Invoke-Sqlcmd -ServerInstance $TargetComputerName -Query $query


    #Create DSN
    $expr = @"
    Get-OdbcDsn -Name $TargetDsnName -ErrorAction SilentlyContinue | Remove-OdbcDsn 
    Add-OdbcDsn -Name $TargetDsnName -DriverName "SQL Server Native Client 11.0" -DsnType "System" -SetPropertyValue @("Server=$TargetComputerName", "Trusted_Connection=Yes", "Database=$DatabaseName")
"@

    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}


    #Create GLOBALS on tgt
    $expr = @"
    'GGSCHEMA ogg' | Out-File -FilePath $TargetOggHome\GLOBALS -Encoding ascii
"@

    Invoke-Command -Session $s -ScriptBlock {Invoke-Expression $Using:expr}

    #Edit Param Replicat
    $statement = @"
    REPLICAT $ReplicatName
    TARGETDB $TargetDsnName

    MAP dbo.*, TARGET dbo.*;
"@

    Invoke-Command -Session $s -FilePath Create-OggParam.ps1 -ArgumentList $TargetOggHome, $ReplicatName, $statement


    #Add Replicat
    $ggsci_command = @"
    DBLOGIN SOURCEDB $TargetDsnName
    ADD CHECKPOINTTABLE ogg.ggcheck
    ADD REPLICAT $ReplicatName, EXTTRAIL ./dirdat/$RemoteTrailName, CHECKPOINTTABLE ogg.ggcheck
"@

    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $TargetOggHome, $ggsci_command

    #Add HeartBeatTable
    $ggsci_command = @"
    DBLOGIN SOURCEDB $TargetDsnName
    ADD HEARTBEATTABLE
"@

    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $TargetOggHome, $ggsci_command


    #Disable jobs resulted from ADD HEARTBEATTABLE on target
    $query = @"
    EXEC msdb.dbo.sp_update_job @job_name = N'cdc.$($DatabaseName)_capture', @enabled = 0
    EXEC msdb.dbo.sp_update_job @job_name = N'cdc.$($DatabaseName)_cleanup', @enabled = 0
    EXEC msdb.dbo.sp_update_job @job_name = N'$($DatabaseName).GG_PURGE_HEARTBEATS', @enabled = 0
    EXEC msdb.dbo.sp_update_job @job_name = N'$($DatabaseName).GG_UPDATE_HEARTBEATS', @enabled = 0
"@
    Invoke-Sqlcmd -ServerInstance $TargetComputerName -Query $query


    #Start Replicat
    $ggsci_command = @"
    START MGR
    START REPLICAT $ReplicatName
"@
    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $TargetOggHome, $ggsci_command

    Remove-PSSession $s

    #Start Extract
    $s = New-PSSession -ComputerName $SourceComputerName
    $ggsci_command = @"
    START MGR
    START EXTRACT $ExtractName
    START EXTRACT $PumpName
"@
    Invoke-Command -Session $s -FilePath Invoke-GGSCI.ps1 -ArgumentList $SourceOggHome, $ggsci_command

    Remove-PSSession $s


    #Check Status
    Start-Sleep 5
    $ggsci_command = @"
    INFO ALL
"@
    Invoke-Command -ComputerName $SourceComputerName -FilePath Invoke-GGSCI.ps1 -ArgumentList $SourceOggHome, $ggsci_command
    Invoke-Command -ComputerName $TargetComputerName -FilePath Invoke-GGSCI.ps1 -ArgumentList $TargetOggHome, $ggsci_command

    }

function Uninstall-OGG ($SourceComputerName, $SourceDsnName, $SourceOggHome, $TargetComputerName, $TargetDsnName, $TargetOggHome, $DatabaseName) {
    ############################
    ##Uninstall GG from source and target
    ############################
    #DELETE EXT
    $ggsci_command = @"
    STOP ER *
    STOP mgr!
    DBLOGIN SOURCEDB $SourceDsnName
    DELETE HEARTBEATTABLE
    DELETE TRANDATA dbo.*
    DELETE *!
"@

    Invoke-Command -ComputerName $SourceComputerName -FilePath Invoke-GGSCI.ps1 -ArgumentList $SourceOggHome, $ggsci_command

    #DELETE REP
    $ggsci_command = @"
    STOP ER *
    STOP mgr!
    DBLOGIN SOURCEDB $TargetDsnName
    DELETE HEARTBEATTABLE
    DELETE REPLICAT *!
    DELETE CHECKPOINTTABLE ogg.ggcheck!
"@

    Invoke-Command -ComputerName $TargetComputerName -FilePath Invoke-GGSCI.ps1 -ArgumentList $TargetOggHome, $ggsci_command


    #Uninstall
    $expr = @"
    Set-Location $SourceOggHome
    CMD /c install deleteevents deleteservice
"@
    Invoke-Command -ComputerName $SourceComputerName -ScriptBlock {Invoke-Expression $Using:expr}

    $expr = @"
    Set-Location $TargetOggHome
    CMD /c install deleteevents deleteservice
"@
    Invoke-Command -ComputerName $TargetComputerName -ScriptBlock {Invoke-Expression $Using:expr}


    #Delete dirdat/*
    Invoke-Command -ComputerName $SourceComputerName -ScriptBlock {Remove-Item $Using:SourceOggHome/dirdat/*}
    Invoke-Command -ComputerName $TargetComputerName -ScriptBlock {Remove-Item $Using:TargetOggHome/dirdat/*}

    #Delete Oracle GoldenGate CDC Cleanup job
    $expr = @"
    Set-Location $SourceOggHome
    cmd /c ogg_cdc_cleanup_setup.bat dropJob gg_user Pass@word01! $DatabaseName $SourceComputerName ogg
"@
    Invoke-Command -ComputerName $SourceComputerName -ScriptBlock {Invoke-Expression $Using:expr}

    #Drop Database from src_server
    $query = @"
    USE [master]
    GO

    IF EXISTS (SELECT 1 from sys.databases WHERE name = '$DatabaseName')
    BEGIN
        ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
        DROP DATABASE [$DatabaseName]
    END
    GO
"@

    Invoke-Sqlcmd -ServerInstance $SourceComputerName -Query $query

    #Drop Database from tgt_server
    $query = @"
    USE [master]
    GO

    IF EXISTS (SELECT 1 from sys.databases WHERE name = '$DatabaseName')
    BEGIN
        ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
        DROP DATABASE [$DatabaseName]
    END
    GO
"@

    Invoke-Sqlcmd -ServerInstance $TargetComputerName -Query $query
    }

Install-OGG -SourceComputerName $src_server -SourceDsnName $src_dsn -SourceMgrPort $src_mgr_port -SourceOggHome $src_ogg_home -TargetComputerName $tgt_server -TargetDsnName $tgt_dsn -TargetOggHome $tgt_ogg_home -TargetMgrPort $tgt_mgr_port -DatabaseName $db_name -ExtractName $extract_name -PumpName $pump_name -ReplicatName $replicat_name -LocalTrailName $local_trail_name -RemoteTrailName $remote_trail_name

Uninstall-OGG -SourceComputerName $src_server -SourceDsnName $src_dsn -SourceOggHome $src_ogg_home -TargetComputerName $tgt_server -TargetDsnName $tgt_dsn -TargetOggHome $tgt_ogg_home -DatabaseName $db_name

###################################
#RESTART PROC
###################################
#Restart Replicat
$ggsci_command = @"
STOP REPLICAT $replicat_name
START REPLICAT $replicat_name
"@
Invoke-Command -ComputerName $tgt_server -FilePath Invoke-GGSCI.ps1 -ArgumentList $tgt_ogg_home, $ggsci_command


#Restart Extract
$ggsci_command = @"
STOP EXTRACT $extract_name
STOP EXTRACT $pump_name
START EXTRACT $extract_name
START EXTRACT $pump_name
"@
Invoke-Command -ComputerName $src_server -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command



#Check Status
Start-Sleep 5
$ggsci_command = @"
INFO ALL
"@
Invoke-Command -ComputerName $src_server -FilePath Invoke-GGSCI.ps1 -ArgumentList $src_ogg_home, $ggsci_command
Invoke-Command -ComputerName $tgt_server -FilePath Invoke-GGSCI.ps1 -ArgumentList $tgt_ogg_home, $ggsci_command
