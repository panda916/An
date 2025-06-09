USE [DIVA_GPW_SOX]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[B01_ITGC_LC_1021DT]
AS
BEGIN

/*Change history comments*/
 
/*
       Title                : [B01_ITGC_LC_1021DT]
       Description   : 
    
       --------------------------------------------------------------
       Update history
       --------------------------------------------------------------
       Date               |		Who    |      Description
       21-04-2022				Thuan    
      
*/
-- Declare limit records base on AM_GLOBALS table.
	DECLARE  
        @LIMIT_RECORDS INT = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
					
SET ROWCOUNT @LIMIT_RECORDS

-- Drop all table B01 in database first.


-- Step 1 / Add field description for E070 table.
SELECT E070_STRKORR FROM A_E070

EXEC SP_REMOVE_TABLES 'B01_01_IT_EO7O_ADD_FIELD_DESC'
SELECT 
	A.E070_TRKORR, -- 	Request/Task
	A.E070_TRFUNCTION, -- Type of request/ task
	B.Name AS  'ZF_E070_TRFUNCTION_DESC', -- Type of request/ task description
	A.E070_TRSTATUS, -- Status of request/task
	C.Name AS 'ZF_E070_TRSTATUS_DESC', -- Status of request/task description
	A.E070_TARSYSTEM, -- Transport Target of Request
	A.E070_KORRDEV, -- 	Request or task category
	D.Name as 'ZF_E070_KORRDEV_DESC', -- 	Request or task category description
	A.E070_AS4USER, -- Owner of a Request or Task
	A.E070_AS4DATE -- Date of last change	 
	,E070_STRKORR -- Higher-Level Request	
INTO B01_01_IT_EO7O_ADD_FIELD_DESC
FROM A_E070 AS A
LEFT JOIN AM_E07O_DESC_MAPPING AS B ON A.E070_TRFUNCTION = B.[Field name] AND B.Type = 'TRFUNCTION'
LEFT JOIN AM_E07O_DESC_MAPPING AS C ON A.E070_TRSTATUS = C.[Field name] AND C.Type = 'TRSTATUS'
LEFT JOIN AM_E07O_DESC_MAPPING AS D ON A.E070_KORRDEV = D.[Field name] AND D.Type = 'KORRDEV'


-- Step 2 : ITGC LC 302.3.1.DT
-- Test relate to PAT03 table.
-- Add status description field.


EXEC SP_REMOVE_TABLES 'B01_02_IT_PAT03'

SELECT 
	*,
	CASE
		WHEN PAT03_STATUS = 'N' THEN 'Package has not yet been applied'
		WHEN PAT03_STATUS = 'I' THEN 'Package has been successfully applied'
		WHEN PAT03_STATUS = 'I' THEN 'Package is obsolete'
	ELSE 'Package is being processed'
	END	AS ZF_PAT03_STATUS_DESC

INTO B01_02_IT_PAT03
FROM A_PAT03











END

GO
