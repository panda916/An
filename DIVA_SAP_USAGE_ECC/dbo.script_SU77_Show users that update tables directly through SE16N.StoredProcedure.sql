USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[script_SU77_Show users that update tables directly through SE16N]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START

-- Script objective: Show users that update tables directly through SE16N
-- Step 1: select data from display table cube (BC19_01_IT_TABLE_DISPLAY)

EXEC SP_REMOVE_TABLES 'SU77_01_RT_SE16N_USER_ACCESS_MODIFICATION_TABLE'

SELECT * 
INTO SU77_01_RT_SE16N_USER_ACCESS_MODIFICATION_TABLE
FROM BC19_01_IT_SE16N_TAB_UPDATES

-- Rename the fields
EXEC SP_RENAME_FIELD 'SU77_01_', 'SU77_01_RT_SE16N_USER_ACCESS_MODIFICATION_TABLE'
GO
