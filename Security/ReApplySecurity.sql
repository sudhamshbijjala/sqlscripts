USE [DatabaseServices]
GO

/****** Object:  Table [dbo].[ReApplySecurity]    Script Date: 07/26/2013 14:33:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ReApplySecurity](
	[PKId] [int] IDENTITY(1,1) NOT NULL,
	[DBName] [nvarchar](128) NOT NULL,
	[SQLStatement] [nvarchar](2000) NOT NULL
) ON [PRIMARY]

GO

