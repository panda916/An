USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC37_ANLB_ANLA_T095_T001_ANLATXT]
AS
--DYNAMIC_SCRIPT_START

--Script objective : Create Asset master cube

--Step 1 Create the asset master cube
-- Get the main information from ANLA and ANLB
--Add the text description from ANLATXT
--Addt the company code name and chart of account from T001
--Add the Balance sheet accounts for depreciation from T095
EXEC SP_DROPTABLE BC37_04_RT_ANLA_ANLB

SELECT DISTINCT
		ANLB_BUKRS,
		ANLB_ANLN1,
		ANLB_ANLN2,
		ANLB_AFABE,
		ANLB_BDATU,
		ANLA_BUKRS,
		ANLA_ANLN1,
		ANLA_ANLN2,
		ANLA_ANLKL,
		ANLA_KTOGR,
		ANLB_XSPEB,
		T001_BUTXT,T001_KTOPL,
		A_T095.*
INTO BC37_04_RT_ANLA_ANLB
FROM A_ANLB
LEFT JOIN A_ANLA 
	ON ANLB_BUKRS=ANLA_BUKRS AND ANLB_ANLN1=ANLA_ANLN1 AND  ANLB_ANLN2=ANLA_ANLN2 
LEFT JOIN A_T001
	ON ANLB_BUKRS=T001_BUKRS
LEFT JOIN A_T095 ON ANLA_KTOGR=T095_KTOGR AND ANLB_AFABE=T095_AFABE AND T001_KTOPL=T095_KTOPL

GO
