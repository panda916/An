USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE      PROCEDURE [dbo].[script_C05_1TV_ACC_GROUP_CHECK]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
BEGIN

/*Change history comments*/

/*
	Title			:	C05: Vendors configured as one-time vendor are mapped to an appropriate one-time vendor account group
	  
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		    | Who |	Description
	22/09/2022        DAT   First version for Sony ECC
*/
EXEC SP_REMOVE_TABLES 'C05_%'

-- Step 1/ Identify suppliers that are one-time vendors


EXEC SP_DROPTABLE 'C05_01_RT_SUPP_1TV'

SELECT 
	BP01_01_IT_SUPP.*
INTO C05_01_RT_SUPP_1TV
FROM BP01_01_IT_SUPP
WHERE BP01_01_LFA1_XCPDK = 'X'

-- Step 2/ Obtain all of the payment settlement data for suppliers that are 1TV

EXEC SP_DROPTABLE 'C05_02_RT_REGUH_1TV'

SELECT 
	   *
	  INTO C05_02_RT_REGUH_1TV
	  FROM BP05A_IT_01_REGUH 
	  INNER JOIN C05_01_RT_SUPP_1TV
	  ON BP05A_01_REGUH_ZBUKR = BP01_01_LFB1_BUKRS AND 
	  BP05A_01_REGUH_LIFNR = BP01_01_LFA1_LIFNR

	  WHERE BP05A_01_REGUH_LIFNR <> ''


--Step 3: Create REGUH cube where supplier is not found in 1TV list and number of REGUH transactions is = 1
EXEC SP_DROPTABLE 'C05_03_RT_REGUH_SUPP_NOT_IN_1TV'

SELECT DISTINCT * 
INTO C05_03_RT_REGUH_SUPP_NOT_IN_1TV
FROM BP05A_IT_01_REGUH
WHERE BP05A_01_REGUH_ZBUKR <> '' AND BP05A_01_REGUH_LIFNR <> ''  -- Supplier not empty
AND BP05A_01_REGUH_ZBUKR+'-'+BP05A_01_REGUH_LIFNR NOT IN  -- Supplier from REGUH table and is not found in the list of one time vendors
(

	SELECT DISTINCT BP01_01_LFB1_BUKRS+'-'+BP01_01_LFA1_LIFNR FROM C05_01_RT_SUPP_1TV
)
AND BP05A_01_REGUH_ZBUKR+'-'+BP05A_01_REGUH_LIFNR  IN  -- Supplier only has 1 transaction in the REGUH table
(
	SELECT BP05A_01_REGUH_ZBUKR+'-'+BP05A_01_REGUH_LIFNR FROM BP05A_IT_01_REGUH
	GROUP BY BP05A_01_REGUH_ZBUKR, BP05A_01_REGUH_LIFNR 
	HAVING COUNT(*) = 1

)

--/*Drop temporary tables*/
EXEC SP_UNNAME_FIELD 'BP01_01_', 'C05_01_RT_SUPP_1TV'
EXEC SP_UNNAME_FIELD 'BP05A_01_', 'C05_02_RT_REGUH_1TV' 
EXEC SP_UNNAME_FIELD 'BP05A_01_', 'C05_03_RT_REGUH_SUPP_NOT_IN_1TV' 

END



GO
