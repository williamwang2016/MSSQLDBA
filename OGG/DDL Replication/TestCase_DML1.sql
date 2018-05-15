:connect sqlserver-0
insert into Demo.dbo.BOAMMTx (BOATxId, BOATxOther) values (1, 'a')
insert into Demo.dbo.BOAMMTx (BOATxId, BOATxOther) values (2, 'b')
insert into Demo.dbo.companytx (companyid, txtypeid, paymethodid, amount, createdate, BOATxId) values (1, 1, 1, 1, getdate(), 1)
insert into Demo.dbo.companytx (companyid, txtypeid, paymethodid, amount, createdate, BOATxId) values (1, 1, 1, 2, getdate(), 1)
insert into Demo.dbo.companytx (companyid, txtypeid, paymethodid, amount, createdate, BOATxId) values (2, 2, 2, 3, getdate(), 2)
insert into Demo.dbo.companytx (companyid, txtypeid, paymethodid, amount, createdate, BOATxId) values (2, 2, 2, 3, getdate(), 2)
GO

:connect sqlserver-0
select * from Demo.dbo.BOAMMTx
select * from Demo.dbo.companytx
GO

:connect sqlserver-1
select * from Demo.dbo.BOAMMTx
select * from Demo.dbo.companytx
GO