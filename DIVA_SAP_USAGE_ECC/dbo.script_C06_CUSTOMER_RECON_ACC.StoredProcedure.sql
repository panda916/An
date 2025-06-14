USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE        PROCEDURE [dbo].[script_C06_CUSTOMER_RECON_ACC]
WITH EXECUTE AS CALLER
AS
--DYNAMIC_SCRIPT_START
BEGIN


/*Change history comments*/

/*
	Title			:	C06: Customer master have all been mapped to a reconciliation account
	  
	--------------------------------------------------------------
	Update history
	--------------------------------------------------------------
	Date		    | Who |	Description
	23/09/2022        DAT   First version for Sony ECC
*/
--Step 1/Create table for customer master where record dont delete and dont have reconciliation account
EXEC SP_REMOVE_TABLES 'C06_%'

EXEC SP_DROPTABLE 'C06_01_XT_CUS_NO_RECON_ACC'

SELECT *
INTO C06_01_XT_CUS_NO_RECON_ACC
FROM BO01_01_IT_CUSTOMER 	 
-- Filter Reconciliation Account is empty and Deletion Flag for Master Record is empty.
WHERE BO01_01_KNB1_AKONT = '' AND BO01_01_KNB1_LOEVM = '' AND  BO01_01_KNA1_LOEVM = ''

--Khoi update
--Step 2/ Get the transactions relate to customer dont have reconciliation accoun
EXEC SP_DROPTABLE 'C06_02_XT_TOTAL_TRANSACTION_CUS_NO_RECON_ACC'
--
SELECT DISTINCT 
	BO01_01_KNB1_KUNNR,
	BO01_01_KNA1_NAME1,
	BO01_01_KNB1_BUKRS,
	BO01_01_T001_BUTXT,
--Sale order value
	ZF_SUM_VBAP_NETWR_S,
	ZF_SUM_ZF_VBAP_NETWR_S_CUC,
--Good issue value
	ZF_SUM_MSEG_DMBTR_S,
	ZF_SUM_MSEG_DMBTR_S_CUC,
--SD invoice value
	ZF_SUM_VBRP_NETWR_S,
	ZF_SUM_VBRP_NETWR_S_CUC,
--JE value
	ZF_SUM_BSEG_DMBTR_S,
	ZF_SUM_BSEG_DMBTR_DB,
	ZF_SUM_BSEG_DMBTR_CR,    
    ZF_SUM_BSEG_DMBTR_S_CUC,
	ZF_SUM_BSEG_DMBTR_DB_CUC,
	ZF_SUM_BSEG_DMBTR_CR_CUC
INTO C06_02_XT_TOTAL_TRANSACTION_CUS_NO_RECON_ACC
FROM C06_01_XT_CUS_NO_RECON_ACC
--Get the relate sale oreder
LEFT JOIN 
	(
		SELECT 
			B33_VBAK_BUKRS_VF,
			B33_VBAK_KUNNR,
			SUM(B33_ZF_VBAP_NETWR_S) AS ZF_SUM_VBAP_NETWR_S,
			SUM(B33_ZF_VBAP_NETWR_S_CUC) AS ZF_SUM_ZF_VBAP_NETWR_S_CUC
		FROM B33_01_IT_SALE_DOCUMENTS
		GROUP BY B33_VBAK_BUKRS_VF, B33_VBAK_KUNNR
	) AS A ON
	BO01_01_KNB1_KUNNR=B33_VBAK_KUNNR AND
	BO01_01_KNB1_BUKRS=B33_VBAK_BUKRS_VF
 --Get the relate good issue   
LEFT JOIN
	(
		SELECT 
			BO03_01_MSEG_BUKRS,
			BO03_01_MSEG_KUNNR,
			SUM(BO03_01_ZF_MSEG_DMBTR_SIGNED) AS ZF_SUM_MSEG_DMBTR_S,
			SUM(BO03_01_ZF_MSEG_DMBTR_SIGNED_CUC) AS ZF_SUM_MSEG_DMBTR_S_CUC
		FROM BO03_01_IT_GDS_ISS
		GROUP BY BO03_01_MSEG_BUKRS,BO03_01_MSEG_KUNNR
	) AS B ON
	BO03_01_MSEG_KUNNR=B33_VBAK_KUNNR AND
	BO03_01_MSEG_BUKRS=B33_VBAK_BUKRS_VF
--Get the relate SD invoice
LEFT JOIN
	(
		SELECT 
			B36_VBRK_BUKRS,
			B36_VBRK_KUNAG,
			SUM(B36_ZF_VBRP_NETWR_S) AS ZF_SUM_VBRP_NETWR_S,
			SUM(B36_ZF_VBRP_NETWR_S_CUC) AS ZF_SUM_VBRP_NETWR_S_CUC
		FROM B36_01_IT_INVOICE_DOCS
		GROUP BY B36_VBRK_BUKRS,B36_VBRK_KUNAG
	) AS C ON 
	B36_VBRK_KUNAG=B33_VBAK_KUNNR AND
	B36_VBRK_BUKRS=B33_VBAK_BUKRS_VF
--Get relate JE
LEFT JOIN
	(
		SELECT 
			B04_BSEG_BUKRS,
			B04_BSEG_KUNNR,
			SUM(B04_ZF_BSEG_DMBTR_S) AS ZF_SUM_BSEG_DMBTR_S,
		    SUM(B04_ZF_BSEG_DMBTR_DB) AS ZF_SUM_BSEG_DMBTR_DB,
		    SUM(B04_ZF_BSEG_DMBTR_CR) AS ZF_SUM_BSEG_DMBTR_CR,    
    
			SUM(B04_ZF_BSEG_DMBTR_S_CUC) AS ZF_SUM_BSEG_DMBTR_S_CUC,
		    SUM(IIF(B04_BSEG_SHKZG='S',B04_ZF_BSEG_DMBTR_S_CUC,0)) AS ZF_SUM_BSEG_DMBTR_DB_CUC,
		    SUM(IIF(B04_BSEG_SHKZG='H',B04_ZF_BSEG_DMBTR_S_CUC,0)) AS ZF_SUM_BSEG_DMBTR_CR_CUC
		FROM B04_11_IT_FIN_GL
		WHERE LEN(B04_BSEG_KUNNR) >0
		GROUP BY B04_BSEG_BUKRS, B04_BSEG_KUNNR
	) AS D ON 
	B04_BSEG_KUNNR=B33_VBAK_KUNNR AND
	B04_BSEG_BUKRS=B33_VBAK_BUKRS_VF

--/*Drop temporary tables*/
EXEC SP_UNNAME_FIELD 'BO01_01_', 'C06_01_XT_CUS_NO_RECON_ACC'
EXEC SP_UNNAME_FIELD 'BO01_01_', 'C06_02_XT_TOTAL_TRANSACTION_CUS_NO_RECON_ACC'

END

GO
