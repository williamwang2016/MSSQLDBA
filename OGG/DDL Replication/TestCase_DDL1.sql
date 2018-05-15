--CREATE_TABLE
--CREATE SEQUENCE
--ALTER_TABLE
--CREATE_SCHEMA
--CREATE_TABLE IN NEW SCHEMA

CREATE TABLE dbo.companytx 
  ( 
     companytxid         BIGINT NOT NULL, 
     companyid           INT NOT NULL, 
     txtypeid            SMALLINT NOT NULL, 
     paymethodid         SMALLINT NOT NULL, 
     amount              MONEY NOT NULL, 
     createdate          DATETIME NOT NULL, 
     journalid           INT NULL, 
     paycheckid          INT NULL, 
     achtxid             INT NULL, 
     ccardtxid           INT NULL, 
     refid               INT NULL, 
     notes               VARCHAR(1500) NULL, 
     referralid          INT NULL, 
     billingid           INT NULL, 
     servicedate         DATETIME NULL, 
     taxpaymentid        INT NULL, 
     contractorpaymentid INT NULL, 
     boatxid             INT NULL, 
     settlementdate      DATETIME NULL, 
     txsubtypeid         SMALLINT NULL, 
     lastupdateddatetime DATETIME NULL, 
     hk_modified         DATETIME NOT NULL, 
     CONSTRAINT CompanyTx_pk PRIMARY KEY CLUSTERED ( companytxid ASC ) 
     WITH (pad_index = OFF, statistics_norecompute = on, ignore_dup_key = OFF, 
     allow_row_locks = on, allow_page_locks = on, FILLFACTOR = 75) ON [PRIMARY]
  ) 
ON [PRIMARY]
GO

CREATE SEQUENCE seq_companytxid
    START WITH 1
    INCREMENT BY 2
GO

ALTER TABLE dbo.companytx 
  ADD DEFAULT (next value FOR seq_companytxid) FOR CompanyTxID
GO 

ALTER TABLE dbo.companytx 
  ADD DEFAULT (Getdate()) FOR LastUpdatedDateTime
GO 

ALTER TABLE dbo.companytx 
  ADD DEFAULT (Getdate()) FOR hk_modified 
GO

CREATE TABLE dbo.BOAMMTx
(
	BOATxId INT NOT NULL,
	BOATxOther VARCHAR(8) NULL,
	CONSTRAINT BOATxId_pk PRIMARY KEY CLUSTERED ( BOATxId ASC ) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE dbo.CompanyTx  WITH NOCHECK ADD  CONSTRAINT FK_ClientTx_BOATx FOREIGN KEY(BOATxId)
REFERENCES dbo.BOAMMTx (BOATxId)
NOT FOR REPLICATION
GO

CREATE SCHEMA Archive
GO
CREATE TABLE Archive.BOAMMTx
(
	BOATxId INT NOT NULL,
	BOATxOther VARCHAR(8) NULL,
	CONSTRAINT BOATxId_pk PRIMARY KEY CLUSTERED ( BOATxId ASC ) ON [Archive]
) ON [Archive]
GO

CREATE SCHEMA Archive_TBD
GO