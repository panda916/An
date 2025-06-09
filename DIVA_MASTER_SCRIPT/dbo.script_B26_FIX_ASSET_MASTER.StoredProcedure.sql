USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Khoi
-- Create date: <Create Date,,>
-- Description:	Create fix asset master cube
-- =============================================
CREATE     PROCEDURE [dbo].[script_B26_FIX_ASSET_MASTER]

AS
BEGIN


--Step 1 Create fix asset master cube

EXEC SP_DROPTABLE B26_01_IT_FIX_ASSET_MASTER
SELECT DISTINCT 
	A_ANLA.*,
	ANKT_TXA50,--	Asset description
	ANKT_TXK20,--Short Text for Asset Class Name
	ANKT_TXK50,--Asset class description
	ANKT_TXT50,--	Asset description
	ANLC_GJAHR,--Fiscal Year
	ANLC_KAAFA,--	Cumulative unplanned depreciation
	ANLC_KANSW,--Cumulative acquisition and production costs	
	ANLC_KANZA,--	Cumulative down payments
	ANLC_KAUFN,--	Cumulative revaluation of ordinary depreciation
	ANLC_KAUFW,--	Cumulative revaluation on the replacement value
	ANLC_KINVZ,--	Cumulative investment grants
	ANLC_KMAFA,--	Cumulative reserves transfer
	ANLC_KNAFA,--	Accumulated ordinary depreciation
	ANLC_KSANS,--	Cumulative statistical acquisition value
	ANLC_KVOST,--Cumulative input tax
	ANLC_KZINW,--Cumulative interest
	ANLC_MAFAG,--	Acquisition value reducing depreciation posted for the year
	ANLC_NDABJ,--	Expired useful life in years at start of the fiscal year
	ANLC_NDABP,--	Expired useful life in periods at start of fiscal year
	ANLC_SANSL,--	Statistical aquisition value of current year
	ANLB_ADATU,--	Date for beginning of validity
	ANLB_AENAM ,--	Name of Person Who Changed Object
	ANLB_AFABE,--Real depreciation area
	ANLB_ANLN1,--Main Asset Number
	ANLB_ANLN2,--Asset Subnumber
	ANLB_BDATU,--	Date validity ends
	ANLB_BUKRS,--	Company Code
	ANLB_ERDAT,--	Date on Which Record Was Created
	ANLB_ERNAM,--	Name of Person who Created the Object
	ANLB_NDJAR,--	Planned useful life in years	
	ANLB_NDPER,--Planned useful life in periods
	ANLB_NDURJ,--Original useful life in yearS
	ANLB_NDURP, --	Original useful life in periods
	ANLT_TXA50,---Asset description
	ANLT_TXT50,--Asset description
	LFA1_ERDAT ,--supplier create date
	LFA1_NAME1,--supplier name
	V_USERNAME_NAME_TEXT--Name of the user who create the assset
INTO B26_01_IT_FIX_ASSET_MASTER
FROM  A_ANLA

--2.2 Add the Depreciation terms
LEFT JOIN A_ANLB
	ON 
		ANLB_BUKRS=ANLA_BUKRS AND 
		ANLB_ANLN1=ANLA_ANLN1 AND 
		ANLB_ANLN2=ANLA_ANLN2
--2.3 Add the Asset Value Fields
LEFT JOIN A_ANLC 
	ON
		ANLC_BUKRS=ANLA_BUKRS AND 
		ANLC_ANLN1=ANLA_ANLN1 AND 
		ANLC_ANLN2=ANLA_ANLN2 AND 
		ANLB_AFABE=ANLC_AFABE
--2.4 Add the Asset Texts 
LEFT JOIN A_ANLT 
	ON
		ANLT_ANLN1=ANLA_ANLN1 AND 
		ANLT_ANLN2=ANLA_ANLN2 AND 
		ANLT_BUKRS=ANLA_BUKRS AND 
		(ANLT_SPRAS='E' OR ANLT_SPRAS='EN')
--2.5 Add supplier data
LEFT JOIN A_LFA1 
	ON 
		ANLA_LIFNR=LFA1_LIFNR
--2.6 Add the Asset classes: Description 
LEFT JOIN A_ANKT
	ON 
		ANLA_ANLKL=ANKT_ANLKL AND (
		ANKT_SPRAS='E' OR ANKT_SPRAS='EN')
--2.7 Add the name of the user
LEFT JOIN A_V_USERNAME 
	ON 
		A_V_USERNAME.V_USERNAME_BNAME=ANLA_ERNAM

--Rename the field of the tables
EXEC SP_RENAME_FIELD 'B26_',B26_01_IT_FIX_ASSET_MASTER

END

GO
