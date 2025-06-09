USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU39_Check if logistics postings are active]
AS
--DYNAMIC_SCRIPT_START

--Script objectvie :Check if logistics postings are active

--Step1 Get the inforamtion from TCULIV (Customizing: Direct Posting in Log. Invoice Verification)

EXEC SP_DROPTABLE SU39_01_RT_TCULIV_ACTIVE_POSTING
SELECT *
INTO SU39_01_RT_TCULIV_ACTIVE_POSTING
FROM A_TCULIV

--Rename the fields

EXEC SP_RENAME_FIELD 'SU39_01_','SU39_01_RT_TCULIV_ACTIVE_POSTING'

GO
