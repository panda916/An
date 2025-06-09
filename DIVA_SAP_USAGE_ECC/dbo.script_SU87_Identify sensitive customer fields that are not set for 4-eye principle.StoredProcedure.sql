USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU87_Identify sensitive customer fields that are not set for 4-eye principle]
AS
--DYNAMIC_SCRIPT_START

---Objective: identify if we have any sensitive customer fields are set for dual validation. 

EXEC SP_DROPTABLE SU87_01_RT_T055F_KOART_D;
SELECT *,
     CASE 'T055F_KOART'
	    WHEN 'D' THEN 'D-Customer'
		WHEN 'K' THEN 'K-Vendor'
		END AS ZF_T055F_KOART_DESC
INTO SU87_01_RT_T055F_KOART_D
FROM A_T055F
WHERE T055F_KOART='D';

EXEC SP_RENAME_FIELD 'SU87_01_','SU87_01_RT_T055F_KOART_D';
GO
