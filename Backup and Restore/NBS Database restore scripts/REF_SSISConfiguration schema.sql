use mcdb
go

CREATE TABLE [dbo].[REF_SSISConfiguration](
	[SSISConfiguration_id] [smallint] NOT NULL,
	[ConfigurationFilter] [nvarchar](255) NOT NULL,
	[ConfiguredValue] [nvarchar](255) NOT NULL,
	[PackagePath] [nvarchar](255) NOT NULL,
	[ConfiguredValueType] [nvarchar](20) NOT NULL,
	[IsActive] [char](1) NOT NULL,
	[CreatedBy] [varchar](32) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[ModifiedBy] [varchar](32) NULL,
	[ModifiedDate] [datetime] NULL
) ON [PRIMARY]
GO


CREATE UNIQUE CLUSTERED INDEX [XPKREF_SSISConfiguration] ON [dbo].[REF_SSISConfiguration] 
(
	[SSISConfiguration_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[REF_SSISConfiguration] ADD  CONSTRAINT [CURRENT_USER_1833192936]  DEFAULT (user_name()) FOR [CreatedBy]
GO

ALTER TABLE [dbo].[REF_SSISConfiguration] ADD  CONSTRAINT [CURRENT_TIMESTAMP_1046376008]  DEFAULT (getdate()) FOR [CreatedDate]
GO


CREATE UNIQUE CLUSTERED INDEX [XPKREF_SSISConfiguration] ON [dbo].[REF_SSISConfiguration]
(
	[SSISConfiguration_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO


CREATE UNIQUE CLUSTERED INDEX [XPKREF_SSISConfiguration] ON [dbo].[REF_SSISConfiguration]
(
	[SSISConfiguration_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO