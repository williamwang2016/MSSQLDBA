.\Stop-OggProcess.ps1
Invoke-Sqlcmd -ServerInstance $src_server -InputFile '.\DDL Replication\TestCase.sql'
.\Apply-DDL.ps1
.\Start-OggProcess.ps1