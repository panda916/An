USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU29C_Identify billing document types that do not copy data from reference]
AS


--Objective: Identify if there are any billing types are not configured for copy control from delivery type and sales order types. Plus identify the reason behind these cases

--Step 1: Create copy control indicator ZF_COPY_CONTROL_INDICATOR by checking if billing types (VBRK_FKART) in table VBRK also 
--exist in table TVCPF (FKARN) (Billing: Copying Control)

EXEC SP_DROPTABLE SU29C_01_RT_VBRK_TVCPF_CHECK_FKART_EQ_FKARN;
SELECT DISTINCT A_VBRK.*,
                TVFKT_VTEXT,
            --Add flag to check if billing types in VBRK also in TVCPF
			IIF(VBRK_FKART IN (SELECT DISTINCT TVCPF_FKARN FROM BC31_01_IT_TVCPF_TVFK_TVFKT_TVAP_TVAPT_TVLK_TVLKT_TVAKT_TVAK), 'Yes','No') AS ZF_VBRK_FKART_IN_TVCPF_OR_NOT
INTO SU29C_01_RT_VBRK_TVCPF_CHECK_FKART_EQ_FKARN
FROM A_VBRK
LEFT JOIN 
           (SELECT DISTINCT TVFKT_FKART, 
		                    TVFKT_VTEXT
			FROM A_TVFKT) A
ON TVFKT_FKART = VBRK_FKART;

--Step 2: Load table of billing types that are set for copy control
EXEC SP_DROPTABLE SU29C_02_TVCPF_ADD_DESC
SELECT * 
INTO SU29C_02_TVCPF_ADD_DESC
FROM BC31_01_IT_TVCPF_TVFK_TVFKT_TVAP_TVAPT_TVLK_TVLKT_TVAKT_TVAK


EXEC SP_RENAME_FIELD 'SU29C_01_','SU29C_01_RT_VBRK_TVCPF_CHECK_FKART_EQ_FKARN';
EXEC SP_RENAME_FIELD 'SU29C_02_','SU29C_02_TVCPF_ADD_DESC';



GO
