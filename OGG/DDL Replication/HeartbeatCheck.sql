:connect sqlserver-0
EXEC Demo.[ogg].GG_UPDATE_HB_TAB
GO

:connect sqlserver-1
SELECT TOP (1000) [local_database]
      ,[current_local_ts]
      ,[remote_database]
      ,[incoming_heartbeat_age]
      ,[incoming_path]
      ,[incoming_lag]
      ,[outgoing_heartbeat_age]
      ,[outgoing_path]
      ,[outgoing_lag]
  FROM [Demo].[ogg].[GG_LAG]

GO