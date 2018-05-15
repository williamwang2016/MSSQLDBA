﻿#Import Parameters and Utilies
. .\Param.ps1
. .\Util.ps1

#Stop OGG Processes
.\Stop-Ogg.ps1

#Start Application Code Release
Invoke-Sqlcmd -ServerInstance $src_server -InputFile '.\DDL Replication\TestCase.sql'

#Start DDL Replication
.\Apply-DDL.ps1


