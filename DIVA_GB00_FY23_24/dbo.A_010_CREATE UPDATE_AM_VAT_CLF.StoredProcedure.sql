USE [DIVA_GB00_FY23_24]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[A_010_CREATE/UPDATE_AM_VAT_CLF]
AS
BEGIN
	/*
		Step 1: Create AM_VAT_CLF if it do not exists
	*/
	PRINT 'Creating AM_VAT_CLF table.'
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'AM_VAT_CLF')
		BEGIN
			CREATE TABLE [dbo].[AM_VAT_CLF](
				[ACCOUNT] [nvarchar](100) NULL,
				[GL TEXT] [nvarchar](1000) NULL,
				[CLASSIFICATION] [nvarchar](100) NULL
			)
		END

	/*
		Step 2: Collect all active g/l from ACDOCA table : 
		Get list of GL account can found in ACDOCA and T030K tables
	*/
	EXEC SP_REMOVE_TABLES 'A010_01_TT_GL_ACCT_T030K_BSEG'

	SELECT DISTINCT BSEG_HKONT, A_SKAT.SKAT_TXT20	
	INTO A010_01_TT_GL_ACCT_T030K_BSEG
	FROM A_BSEG
	--Add chart of accounts code per company code
       LEFT JOIN A_T001                                             
       ON   A_T001.T001_BUKRS = BSEG_BUKRS   
    -- Add chart fo accounts description
       LEFT JOIN A_SKAT                                             
       ON     A_SKAT.SKAT_KTOPL = A_T001.T001_KTOPL AND               
              A_SKAT.SKAT_SAKNR = A_BSEG.BSEG_HKONT                                          

	WHERE BSEG_HKONT IN (SELECT DISTINCT T030K_KONTS FROM A_T030K WHERE T030K_KONTS <> '') -- Gl account in BSEG and T030K tables
	AND BSEG_HKONT <> ''


	/*
		Step 2: Insert new value for AM table.
	*/
	INSERT INTO [dbo].[AM_VAT_CLF] ([ACCOUNT], [GL TEXT] ,[CLASSIFICATION])
	SELECT DISTINCT BSEG_HKONT, SKAT_TXT20, ''
	FROM A010_01_TT_GL_ACCT_T030K_BSEG
	WHERE NOT EXISTS (
		SELECT TOP 1 1 
		FROM AM_VAT_CLF
		WHERE AM_VAT_CLF.ACCOUNT = BSEG_HKONT 
			
	)
	
	EXEC SP_REMOVE_TABLES 'A010_%'
END

GO
