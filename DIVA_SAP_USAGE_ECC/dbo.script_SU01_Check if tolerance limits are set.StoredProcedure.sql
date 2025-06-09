USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU01_Check if tolerance limits are set]
AS
--DYNAMIC_SCRIPT_START

BEGIN
--Script objective : Create the exception table for test 1 
-- Get the list of supplier where GR Based Invoice Verification or Service Based Invoice Verification is empty
--Get the list of company code that are  have quantity tolerance are inconsistent 

--Step 1 Get the list of supplier details

EXEC SP_DROPTABLE SU01_01_RT_SUPP_DETAILS

SELECT * 
INTO SU01_01_RT_SUPP_DETAILS
FROM BP01_01_IT_SUPP

--Step 2 get the tolerance limit details for company codes

EXEC SP_DROPTABLE SU01_02_RT_T69G_DETAILS

SELECT *
INTO SU01_02_RT_T69G_DETAILS
FROM BC05_01_IT_T169G_ADD_FLAG 

--STep 3 Rename the fields

EXEC SP_UNNAME_FIELD 'BP01_01_', 'SU01_01_RT_SUPP_DETAILS'
EXEC SP_RENAME_FIELD 'SU01_01_', 'SU01_01_RT_SUPP_DETAILS'


EXEC SP_UNNAME_FIELD 'BC05_01_', 'SU01_02_RT_T69G_DETAILS'
EXEC SP_RENAME_FIELD 'SU01_02_', 'SU01_02_RT_T69G_DETAILS'

END



GO
