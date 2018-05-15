USE Demo
GO
CREATE TABLE dbo.t2 (c1 INT)
GO
CREATE TABLE dbo.t3 (c1 INT, c2 VARCHAR(10))
GO
ALTER TABLE dbo.t3 ALTER COLUMN c2 VARCHAR(30)
GO

ALTER TABLE dbo.t3 ADD c5 VARCHAR(10)
GO
DROP TABLE dbo.t1
DROP TABLE dbo.t2
GO


SELECT OBJECT_ID('[testch].[t1]')
CREATE SCHEMA testch
GO
CREATE TABLE testch.t2 (c1 INT)
GO
CREATE TABLE testch.t3 (c1 INT, c2 VARCHAR(10))
GO
ALTER TABLE testch.t3 ALTER COLUMN c2 VARCHAR(20)
GO
DROP TABLE testch.t2
GO

--insert into companytx ([companyid], [txtypeid], [paymethodid], [amount], [createdate]) values (1, 1, 1, 1, getdate())



drop table [companytx]

CREATE TABLE [dbo].[companytx] 
  ( 
     [companytxid]         [BIGINT] NOT NULL, 
     [companyid]           [INT] NOT NULL, 
     [txtypeid]            [SMALLINT] NOT NULL, 
     [paymethodid]         [SMALLINT] NOT NULL, 
     [amount]              [MONEY] NOT NULL, 
     [createdate]          [DATETIME] NOT NULL, 
     [journalid]           [INT] NULL, 
     [paycheckid]          [INT] NULL, 
     [achtxid]             [INT] NULL, 
     [ccardtxid]           [INT] NULL, 
     [refid]               [INT] NULL, 
     [notes]               [VARCHAR](1500) NULL, 
     [referralid]          [INT] NULL, 
     [billingid]           [INT] NULL, 
     [servicedate]         [DATETIME] NULL, 
     [taxpaymentid]        [INT] NULL, 
     [contractorpaymentid] [INT] NULL, 
     [boatxid]             [INT] NULL, 
     [settlementdate]      [DATETIME] NULL, 
     [txsubtypeid]         [SMALLINT] NULL, 
     [lastupdateddatetime] [DATETIME] NULL, 
     [hk_modified]         [DATETIME] NOT NULL, 
     CONSTRAINT [CompanyTx_new_pk] PRIMARY KEY CLUSTERED ( [companytxid] ASC ) 
     WITH (pad_index = OFF, statistics_norecompute = on, ignore_dup_key = OFF, 
     allow_row_locks = on, allow_page_locks = on, FILLFACTOR = 75) ON [PRIMARY] 
  ) 
ON [PRIMARY]

go 

CREATE SEQUENCE seq_companytxid
    START WITH 1  
    INCREMENT BY 2 ; 
GO
ALTER TABLE [dbo].[companytx] 
  ADD DEFAULT (next value FOR [seq_companytxid]) FOR [CompanyTxID]
GO 

ALTER TABLE [dbo].[companytx] 
  ADD DEFAULT (Getdate()) FOR [LastUpdatedDateTime]
GO 

ALTER TABLE [dbo].[companytx] 
  ADD DEFAULT (Getdate()) FOR [hk_modified] 
GO 

CREATE NONCLUSTERED INDEX [NCI_companyid] ON [dbo].[companytx]
(
	[companyid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
go