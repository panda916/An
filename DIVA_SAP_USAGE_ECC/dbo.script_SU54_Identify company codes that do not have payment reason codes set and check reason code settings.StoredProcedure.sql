USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU54_Identify company codes that do not have payment reason codes set and check reason code settings]
AS
--DYNAMIC_SCRIPT_START

--Script objective: SU54_Identify company codes that do not have payment reason codes set and check reason code settings
--Create information cube relate to the test
--Step 1 Get the information about reason code
EXEC SP_DROPTABLE SU54_01_RT_T053E_T053R

SELECT *
INTO SU54_01_RT_T053E_T053R
FROM BC35_01_IT_T053E_T053R

--Step 2 Get the information about Standard account determination

EXEC SP_DROPTABLE SU54_02_RT_T030

SELECT 
*
INTO SU54_02_RT_T030
FROM BC21_02_IT_T030_ADD_DESC

--STep 3  Get the in G/L account master (company code) 
--Add the information about tolerance limit

EXEC SP_DROPTABLE SU54_03_RT_SKB1_T043S

SELECT * 
INTO SU54_03_RT_SKB1_T043S
FROM BC34_01_IT_SKB1_SKAT_T001
LEFT JOIN BC17_01_IT_T043S_T001 
	ON SKB1_TOGRU=BC17_01_T043S_TOGRU AND BC17_01_T043S_BUKRS=SKB1_BUKRS

--Rename the fields
EXEC SP_UNNAME_FIELD 'BC17_01_',SU54_03_RT_SKB1_T043S
EXEC SP_RENAME_FIELD 'SU54_01_','SU54_01_RT_T053E_T053R'
EXEC SP_RENAME_FIELD 'SU54_02_','SU54_02_RT_T030'
EXEC SP_RENAME_FIELD 'SU54_03_','SU54_03_RT_SKB1_T043S'

GO
