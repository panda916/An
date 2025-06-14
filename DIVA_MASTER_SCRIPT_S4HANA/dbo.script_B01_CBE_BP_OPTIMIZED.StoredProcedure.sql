USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE       PROCEDURE [dbo].[script_B01_CBE_BP_OPTIMIZED]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
BEGIN

	/*
		Step 1: Collect BP information from BUT000, BUT100, BUT020, TB002, ADRC and etc
		Note: Be careful when calucate value with this cube because BP nr will be duplicated on BP address and BP role. 
	*/
EXEC SP_REMOVE_TABLES 'B01_01_TT_CBE_BP'
SELECT
	A_BUT000.BUT000_PARTNER AS BUT000_PARTNER --Business Partner
			,CASE A_BUT000.BUT000_TYPE
				WHEN '1' THEN CONCAT(A_BUT000.BUT000_NAME_FIRST, ' ', A_BUT000.BUT000_NAME_LAST)
				WHEN '2' THEN CONCAT(
										IIF(A_BUT000.BUT000_NAME_ORG1 = '', '', A_BUT000.BUT000_NAME_ORG1),
										IIF(A_BUT000.BUT000_NAME_ORG2 = '', '', ' '+A_BUT000.BUT000_NAME_ORG2),
										IIF(A_BUT000.BUT000_NAME_ORG3 = '', '', ' '+A_BUT000.BUT000_NAME_ORG3),
										IIF(A_BUT000.BUT000_NAME_ORG4 = '', '', ' '+A_BUT000.BUT000_NAME_ORG4)
									)
				ELSE
							  CONCAT(
										IIF(A_BUT000.BUT000_NAME_GRP1 = '', '', A_BUT000.BUT000_NAME_GRP1),
										IIF(A_BUT000.BUT000_NAME_GRP2 = '', '', ' '+A_BUT000.BUT000_NAME_GRP2)
									)
		  END AS ZF_BUT000_BP_NAME --Z_Business Partner Name
	,A_BUT000.BUT000_BU_GROUP	AS BUT000_BU_GROUP --Grouping
	,A_TB002.TB002_TXT40	AS TB002_TXT40 --Description
	,CASE WHEN A_BUT000.BUT000_BU_GROUP IN ('Z500','ZI00') THEN '02_Intercompany'
	   WHEN A_BUT000.BUT000_BU_GROUP IN ('Z800','ZE00') THEN '03_Employee'
	   ELSE                                                      '01_3rd Party'
	END AS ZF_BUT000_BU_GROUP_BP_CATEGORY--Z_Business Partner Category
	,A_BUT000.BUT000_AUGRP AS BUT000_AUGRP --Authorization Group
--	,A_BUT100.BUT100_RLTYP AS BUT100_RLTYP -- BP Role
	,A_BUT100.ZF_VENDOR_CUS_FLAG -- Z_Vendor Cusotmer Flag
	,A_BUT000.BUT000_BU_SORT1 AS BUT000_BU_SORT1 --Search Term 1
	,A_BUT000.BUT000_BU_SORT2 AS BUT000_BU_SORT2 -- Search Term 2
	,A_BUT000.BUT000_TITLE AS BUT000_TITLE -- Title
	,A_BUT000.BUT000_VALID_FROM AS BUT000_VALID_FROM --Valid From
	,A_BUT000.BUT000_VALID_TO AS BUT000_VALID_TO --Valid To
	,A_BUT000.BUT000_XBLCK AS BUT000_XBLCK --Central Block
	,A_BUT000.BUT000_XDELE AS BUT000_XDELE --Archiving Flag
	,A_BUT000.BUT000_CRUSR AS BUT000_CRUSR --Created by
	,A_BUT000.BUT000_CRDAT AS BUT000_CRDAT --Created on
	,A_BUT000.BUT000_CRTIM AS BUT000_CRTIM --Created at
	,A_BUT000.BUT000_CHUSR AS BUT000_CHUSR --Changed by
	,A_BUT000.BUT000_CHDAT AS BUT000_CHDAT --Changed on
	,A_BUT000.BUT000_CHTIM AS BUT000_CHTIM --Changed at
	,A_BUT020.BUT020_ADDRNUMBER AS BUT020_ADDRNUMBER --Address Number
	,A_ADRC.ADRC_CITY1 AS ADRC_CITY1 --City
	,A_ADRC.ADRC_STREET AS ADRC_STREET --Street
	,A_ADRC.ADRC_CITY2 AS ADRC_CITY2 --District
	,A_ADRC.ADRC_REGION AS ADRC_REGION --Region
	,A_ADRC.ADRC_COUNTRY AS ADRC_COUNTRY --Country
	,A_ADRC.ADRC_POST_CODE1 AS ADRC_POST_CODE1 --Postal Code
	,A_ADRC.ADRC_PO_BOX AS ADRC_PO_BOX --PO Box
	,A_ADRC.ADRC_POST_CODE2 AS ADRC_POST_CODE2 --PO Box Post Cde
	,A_ADRC.ADRC_TEL_NUMBER AS ADRC_TEL_NUMBER --Telephone
	,A_ADRC.ADRC_FAX_NUMBER AS ADRC_FAX_NUMBER --Fax
	,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
	CASE A_BUT000.BUT000_TYPE
		WHEN '1' THEN CONCAT([A_BUT000].BUT000_NAME_FIRST, ' ', A_BUT000.BUT000_NAME_LAST)
		WHEN '2' THEN CONCAT(
								IIF(A_BUT000.BUT000_NAME_ORG1 = '', '', A_BUT000.BUT000_NAME_ORG1),
								IIF(A_BUT000.BUT000_NAME_ORG2 = '', '', ' '+A_BUT000.BUT000_NAME_ORG2),
								IIF(A_BUT000.BUT000_NAME_ORG3 = '', '', ' '+A_BUT000.BUT000_NAME_ORG3),
								IIF(A_BUT000.BUT000_NAME_ORG4 = '', '', ' '+A_BUT000.BUT000_NAME_ORG4)
							)
		ELSE
						CONCAT(
								IIF(A_BUT000.BUT000_NAME_GRP1 = '', '', A_BUT000.BUT000_NAME_GRP1),
								IIF(A_BUT000.BUT000_NAME_GRP2 = '', '', ' '+A_BUT000.BUT000_NAME_GRP2)
							)
	END
	,'''',''),'!',''),'"',''),'#',''),'$',''),'%',''),'&',''),'(',''),')',''),'*',''),'+',''),'-',''),'.',''),'/',''),':',''),';',''),'<',''),'=',''),'>',''),'?',''),'@',''),'[',''),'\',''),']',''),'^',''),'_',''),'`',''),'{',''),'|',''),'}',''),'~',''),' ',''),' ','') AS ZF_BUT000_BP_NAME_CLEANSED --[Z_Business Partner Name - Cleansed]
	,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
	[A_ADRC].[ADRC_STREET]
	,'''',''),'!',''),'"',''),'#',''),'$',''),'%',''),'&',''),'(',''),')',''),'*',''),'+',''),'-',''),'.',''),'/',''),':',''),';',''),'<',''),'=',''),'>',''),'?',''),'@',''),'[',''),'\',''),']',''),'^',''),'_',''),'`',''),'{',''),'|',''),'}',''),'~',''),' ',''),' ','') AS ZF_ADRC_STR_CLEANSED --[Z_Street - Cleansed]
	,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
	[A_ADRC].[ADRC_TEL_NUMBER]
	,'''',''),'!',''),'"',''),'#',''),'$',''),'%',''),'&',''),'(',''),')',''),'*',''),'+',''),'-',''),'.',''),'/',''),':',''),';',''),'<',''),'=',''),'>',''),'?',''),'@',''),'[',''),'\',''),']',''),'^',''),'_',''),'`',''),'{',''),'|',''),'}',''),'~',''),' ',''),' ','') AS ZF_ADRC_TEL_CLEANSED --[Z_Telephone - Cleansed]
INTO B01_01_TT_CBE_BP
FROM A_BUT000
--Get BP group description from TB002
LEFT JOIN dbo.A_TB002 ON 
		A_BUT000.BUT000_CLIENT  = A_TB002.TB002_MANDT
	AND A_BUT000.BUT000_BU_GROUP = A_TB002.TB002_BU_GROUP
	AND A_TB002.TB002_SPRAS IN ('E', 'EN')
LEFT JOIN (SELECT A_BUT100.BUT100_PARTNER,
						  CASE WHEN MAX(A_BUT100.BUT100_RLTYP) LIKE '%FLVN%' AND
									MIN(A_BUT100.BUT100_RLTYP) LIKE '%FLCU%' THEN 'Both'
							   WHEN MIN(A_BUT100.BUT100_RLTYP) LIKE '%FLVN%' THEN 'Vendor'
							   WHEN MIN(A_BUT100.BUT100_RLTYP) LIKE '%FLCU%' THEN 'Customer'
							   ELSE                                                               '90_Others'
						  END ZF_VENDOR_CUS_FLAG
				  FROM dbo.A_BUT100
				  WHERE A_BUT100.BUT100_RLTYP IN ('FLCU00','FLCU01','FLVN00','FLVN01')
				  GROUP BY A_BUT100.BUT100_PARTNER
				  ) AS A_BUT100
		ON	A_BUT000.BUT000_PARTNER = A_BUT100.BUT100_PARTNER

--Get BP address number from BUT020
--		LEFT JOIN dbo.A_BUT020
LEFT JOIN (SELECT A_BUT020.BUT020_PARTNER,
		            A_BUT020.BUT020_CLIENT,
					A_BUT020.BUT020_ADDRNUMBER,
					ROW_NUMBER() OVER (PARTITION BY A_BUT020.BUT020_PARTNER ORDER BY A_BUT020.BUT020_ADDR_VALID_TO DESC) AS ROW_NR
			FROM dbo.A_BUT020
			) AS A_BUT020
ON	A_BUT000.BUT000_CLIENT =A_BUT020.BUT020_CLIENT
	AND A_BUT000.BUT000_PARTNER=A_BUT020.BUT020_PARTNER
	AND A_BUT020.ROW_NR = 1

--Get BP address detail from ADRC
LEFT JOIN A_ADRC
ON	A_BUT020.BUT020_ADDRNUMBER = A_ADRC.ADRC_ADDRNUMBER
	AND (A_ADRC.ADRC_NATION = '' OR A_ADRC.ADRC_NATION IS NULL)

/*
	Step 2: Find all BP names which have more than one BP nr
*/

EXEC SP_REMOVE_TABLES 'B01_02_TT_CBE_BP_NAME_DUP_FLAG'--'CBE_Business Partner Name Duplicate Flag';
SELECT ZF_BUT000_BP_NAME_CLEANSED
INTO B01_02_TT_CBE_BP_NAME_DUP_FLAG
FROM B01_01_TT_CBE_BP
WHERE ZF_BUT000_BP_NAME_CLEANSED <> '' AND ZF_BUT000_BP_NAME_CLEANSED IS NOT NULL
GROUP BY ZF_BUT000_BP_NAME_CLEANSED
HAVING COUNT(DISTINCT BUT000_PARTNER) > 1

/*
	Step 3: Find all BP street name which have more than one BP nr
*/
	EXEC SP_REMOVE_TABLES 'B01_03_TT_CBE_BP_STREET_DUP_FLAG'--'CBE_Business Partner Street Duplicate Flag';
	SELECT ZF_ADRC_STR_CLEANSED
	INTO B01_03_TT_CBE_BP_STREET_DUP_FLAG
	FROM B01_01_TT_CBE_BP
	WHERE ZF_ADRC_STR_CLEANSED <> '' AND ZF_ADRC_STR_CLEANSED IS NOT NULL
	GROUP BY ZF_ADRC_STR_CLEANSED
	HAVING COUNT(DISTINCT BUT000_PARTNER) > 1

/*
	Step 4: Find all BP telephone which have more than one BP nr
*/
	EXEC SP_REMOVE_TABLES 'B01_04_TT_CBE_BP_TELE_DUP_FLAG'--'CBE_Business Partner Telephone Duplicate Flag';
	SELECT ZF_ADRC_TEL_CLEANSED
	INTO B01_04_TT_CBE_BP_TELE_DUP_FLAG
	FROM B01_01_TT_CBE_BP
	WHERE ZF_ADRC_TEL_CLEANSED <> '' AND [ZF_ADRC_TEL_CLEANSED] IS NOT NULL
	GROUP BY ZF_ADRC_TEL_CLEANSED
	HAVING COUNT(DISTINCT BUT000_PARTNER) > 1

/*
Step 5: Put all dupplicate flag to main BP cube 
*/
EXEC SP_REMOVE_TABLES 'B01_05_IT_CBE_BP'--'CBE_Business Partner'
SELECT 
		B01_01_TT_CBE_BP.*
		,IIF(B01_02_TT_CBE_BP_NAME_DUP_FLAG.ZF_BUT000_BP_NAME_CLEANSED IS NOT NULL, 'X', '') AS ZF_BUT000_BP_NAME_DUP_FLAG --[Z_Name Duplicate Flag]
		,IIF(B01_03_TT_CBE_BP_STREET_DUP_FLAG.ZF_ADRC_STR_CLEANSED IS NOT NULL, 'X', '') AS ZF_ADRC_STR_DUP_FLAG --[Z_Street Duplicate Flag]
		,IIF(B01_04_TT_CBE_BP_TELE_DUP_FLAG.ZF_ADRC_TEL_CLEANSED IS NOT NULL, 'X', '') AS ZF_ADRC_TEL_DUP_FLAG --[Z_Telephone Duplicate Flag]
INTO B01_05_IT_CBE_BP
FROM B01_01_TT_CBE_BP
		
--Get BP name duplicate flag
LEFT JOIN B01_02_TT_CBE_BP_NAME_DUP_FLAG
ON B01_01_TT_CBE_BP.ZF_BUT000_BP_NAME_CLEANSED = B01_02_TT_CBE_BP_NAME_DUP_FLAG.ZF_BUT000_BP_NAME_CLEANSED

--Get BP street name duplicate flag
LEFT JOIN B01_03_TT_CBE_BP_STREET_DUP_FLAG
ON B01_01_TT_CBE_BP.ZF_ADRC_STR_CLEANSED = B01_03_TT_CBE_BP_STREET_DUP_FLAG.ZF_ADRC_STR_CLEANSED

--Get BP telephone duplicate flag
LEFT JOIN [B01_04_TT_CBE_BP_TELE_DUP_FLAG]
ON B01_01_TT_CBE_BP.ZF_ADRC_TEL_CLEANSED = B01_04_TT_CBE_BP_TELE_DUP_FLAG.ZF_ADRC_TEL_CLEANSED

-- Drop temporary table

EXEC SP_REMOVE_TABLES '%_TT_%'

-- Rename field in table 

EXEC SP_RENAME_FIELD 'B01_', 'B01_05_IT_CBE_BP'

END



GO
