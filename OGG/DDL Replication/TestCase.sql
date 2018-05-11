CREATE TABLE dbo.t1 (c1 INT)
GO
CREATE TABLE dbo.t2 (c1 INT)
GO
CREATE TABLE dbo.t3 (c1 INT, c2 VARCHAR(10))
GO
ALTER TABLE dbo.t3 ALTER COLUMN c2 VARCHAR(20)
GO
DROP TABLE dbo.t1
DROP TABLE dbo.t2
GO

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

go 

ALTER TABLE [dbo].[companytx] 
  ADD DEFAULT (Getdate()) FOR [LastUpdatedDateTime] 

go 

ALTER TABLE [dbo].[companytx] 
  ADD DEFAULT (Getdate()) FOR [hk_modified] 

go 
