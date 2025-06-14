USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_SU04_Identify materials and purchase orders that allow for unlimited overdelivery]
AS
--DYNAMIC_SCRIPT_START

---Objective: Identify materials that have the unlimited delivery indicator checked,
---as well as purchase information records for those materials

EXEC SP_REMOVE_TABLES 'SU04_%'
---Step 1/ Get the full list of purchasing keys and tolerance limits


EXEC SP_DROPTABLE  SU04_01_RT_T405;
SELECT *,
 (CASE WHEN T405_UEBTK LIKE 'X' THEN 'Yes'
	   ELSE 'No' END) AS ZF_T405_UEBTK_DESC
INTO SU04_01_RT_T405
FROM A_T405; 

---//Step 2/ Obtain the list of material numbers for which unlimited over delivery is allowed

EXEC SP_DROPTABLE SU04_02_XT_MARA_MATNR_WITH_UEBTK_EQ_X
SELECT DISTINCT
	  BC12_01_IT_MARA_VS_MAKT_ADD_MAKT_MAKTX. *, 
	  BC25_01_IT_MARC_T001W_MAKT_DESC.*,
	  IIF(MARC_UEETK LIKE 'X','Yes','No') AS ZF_MARC_UEETK_DESC
INTO SU04_02_XT_MARA_MATNR_WITH_UEBTK_EQ_X
FROM BC25_01_IT_MARC_T001W_MAKT_DESC 
LEFT JOIN BC12_01_IT_MARA_VS_MAKT_ADD_MAKT_MAKTX 
ON MARC_MATNR = MARA_MATNR 
WHERE MARA_EKWSL IN (
			SELECT DISTINCT
				 T405_EKWSL 
			FROM A_T405
			WHERE  T405_UEBTK LIKE 'X');--Checking purchasing value keys which have unlimited overdelivery indicators

---// Step 3/ Obtain from EINA, the purchasing information record numbers for those materials that have unlimited delivery tolerances set; 
---and then obtain the purchasing information records from EINE, 
---that shows the indicator as to whether there are unlimited deliveries for the purchase order.

EXEC SP_DROPTABLE SU04_03_RT_EINE_INFNR_EINA_INFNR;
SELECT DISTINCT A_EINE.*, A_EINA.*,A_MAKT.*,
	ZF_AVG_UNDER_OVER_DELIVERY_FLAG,
    IIF(EINE_UEBTK LIKE 'X','Yes','No') AS ZF_EINE_UEBTK_DESC,
	IIF(EINA_MATNR IN (SELECT DISTINCT MARA_MATNR FROM  SU04_02_XT_MARA_MATNR_WITH_UEBTK_EQ_X),'Yes','No') AS ZF_EINA_MATNR_IN_MARA_UNLIMITED_OR_NOT
INTO SU04_03_RT_EINE_INFNR_EINA_INFNR
FROM A_EINE
LEFT JOIN A_EINA
ON EINA_INFNR = EINE_INFNR
LEFT JOIN A_MAKT
ON EINA_MATNR = MAKT_MATNR
INNER JOIN 
(
-- Thuan add script below to custom scatter chart in Inventory 01-01
	SELECT DISTINCT 
		EINE_INFNR,
		ZF_AVG_UNDER_OVER_DELIVERY_FLAG
	FROM (
		SELECT 
			EINE_INFNR,
			CONCAT('Over : ',cast(AVG(EINE_UEBTO) as float) ,
			' Under : ', cast(AVG(EINE_UNTTO) as float)) ZF_AVG_UNDER_OVER_DELIVERY_FLAG 
		FROM A_EINE
		GROUP BY EINE_INFNR
	)AS A
)AS A ON A_EINE.EINE_INFNR = A.EINE_INFNR;

---Step 4/ Create good receipt table 
--Get from PO history (EKBE)
--Only get GR with PO

--Get the currency from AM table
EXEC SP_DROPTABLE 'SU04_04_RT_EKBE_RELATE_PO'

 DECLARE 	 
		@CURRENCY NVARCHAR(MAX)			= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
--

SELECT DISTINCT A_EKBE.*,
			 EKBE_EBELN+'-'+EKBE_EBELP AS ZF_EKBE_EBELN_EBELP,
			--CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) *
			--COALESCE(TCURX_CC.TCURX_FACTOR,1) * COALESCE(AM_EXCHNG_CUC.EXCHNG_RATIO,1)) AS ZF_EKBE_DMBTR_S_CUC,
			CONVERT(money,EKBE_DMBTR * (CASE WHEN (EKBE_SHKZG = 'S') THEN 1 ELSE -1 END) *
			COALESCE(TCURX_CC.TCURX_FACTOR,1)*COALESCE(CAST(B00_IT_TCURR.TCURR_UKURS AS FLOAT),1) * 
			COALESCE(B00_IT_TCURF.TCURF_TFACT,1) / COALESCE(B00_IT_TCURF.TCURF_FFACT,1)) AS ZF_EKBE_DMBTR_S_CUC
			,ZF_MSEG_MEINS_LIST,
			B09_EKPO_BUKRS,B09_T001_BUTXT,
			MAKT_MAKTX
		INTO SU04_04_RT_EKBE_RELATE_PO
		FROM A_EKBE
			-- get the lines relate to PO only
		INNER JOIN B09_13_IT_PTP_POS
		ON B09_EKKO_EBELN=EKBE_EBELN AND	B09_EKPO_EBELP=EKBE_EBELP
			--Add the company code (so that we can add the house currency)
			LEFT JOIN A_EKKO 
			ON A_EKBE.EKBE_EBELN = A_EKKO.EKKO_EBELN
				--Add house currency
			LEFT JOIN A_T001
			on A_EKKO.EKKO_BUKRS=A_T001.T001_BUKRS

			-- Add currency conversion factors for company code currency
			LEFT JOIN B00_TCURX TCURX_CC 
			on
			   A_T001.T001_WAERS = TCURX_CC.TCURX_CURRKEY   

			-- Add currency conversion factors for document currency
			LEFT JOIN B00_TCURX TCURX_DOC 
			on
			   A_EKBE.EKBE_WAERS = TCURX_DOC.TCURX_CURRKEY   

			-- Exchange rates for currency conversion: from house currency to house currency
			--LEFT JOIN AM_EXCHNG AS AM_EXCHNG_CUC  
			--	ON AM_EXCHNG_CUC.EXCHNG_FROM = A_T001.T001_WAERS 
			--	AND AM_EXCHNG_CUC.EXCHNG_TO = @currency

      	-- Add currency factor from company currency to USD

			LEFT JOIN B00_IT_TCURF
			ON A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR
			AND B00_IT_TCURF.TCURF_TCURR  = @currency  
			AND B00_IT_TCURF.TCURF_GDATU = (
				SELECT TOP 1 B00_IT_TCURF.TCURF_GDATU
				FROM B00_IT_TCURF
				WHERE A_T001.T001_WAERS = B00_IT_TCURF.TCURF_FCURR AND 
						B00_IT_TCURF.TCURF_TCURR  = @currency  AND
						B00_IT_TCURF.TCURF_GDATU <= A_EKBE.EKBE_BUDAT
				ORDER BY B00_IT_TCURF.TCURF_GDATU DESC
				)
		-- Add exchange rate from company currency to USD
		LEFT JOIN B00_IT_TCURR
			ON A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR
			AND B00_IT_TCURR.TCURR_TCURR  = @currency  
			AND B00_IT_TCURR.TCURR_GDATU = (
				SELECT TOP 1 B00_IT_TCURR.TCURR_GDATU
				FROM B00_IT_TCURR
				WHERE A_T001.T001_WAERS = B00_IT_TCURR.TCURR_FCURR AND 
						B00_IT_TCURR.TCURR_TCURR  = @currency  AND
						B00_IT_TCURR.TCURR_GDATU <= A_EKBE.EKBE_BUDAT
				ORDER BY B00_IT_TCURR.TCURR_GDATU DESC
				) 


			--Add material description
			LEFT JOIN A_MAKT
				ON MAKT_MATNR=EKBE_MATNR
			-- Add GR base unit of measure
			LEFT JOIN 
				(
				SELECT 
						BP03_01_MSEG_EBELN,
						BP03_01_MSEG_EBELP,
						REPLACE( dbo.GROUP_CONCAT(BP03_01_MSEG_MEINS), ',','|') AS ZF_MSEG_MEINS_LIST
				FROM 
						(
							SELECT DISTINCT  
									BP03_01_MSEG_EBELN,
									BP03_01_MSEG_EBELP,
									BP03_01_MSEG_MEINS
							FROM BP03_01_IT_GR
						) AS B
				GROUP BY 
						BP03_01_MSEG_EBELN,
						BP03_01_MSEG_EBELP
				) AS A
				ON 		BP03_01_MSEG_EBELN=EKBE_EBELN AND 
						BP03_01_MSEG_EBELP=EKBE_EBELP
		WHERE EKBE_VGABE = '1'

--Get the PO list
--Get the summary of GR , add the flag to compare between the value in PO and GR
--
EXEC SP_DROPTABLE SU04_05_RT_EKPO_EKBE_MSEG_COMPARE_DMBTR_MEINS;
SELECT *,
      IIF(B09_ZF_EKPO_NETWR_CUC IS NOT NULL AND ZF_EKBE_DMBTR_S_CUC IS NOT NULL AND ROUND(ZF_EKBE_DMBTR_S_CUC,0) > ROUND(B09_ZF_EKPO_NETWR_CUC,0), 'Yes','No') AS ZF_EKBE_DMBTR_HIGHER_EKBE_NETWR_S_CUC,
	  IIF(B09_EKPO_MEINS = ZF_MSEG_MEINS_LIST, 'Yes','No') AS ZF_EKPO_MEINS_EQ_MSEG_MEINS
INTO SU04_05_RT_EKPO_EKBE_MSEG_COMPARE_DMBTR_MEINS
FROM
	B09_13_IT_PTP_POS AS A
LEFT JOIN
--Caculate the currency for EKBE
	(
		SELECT 
			 EKBE_EBELN, EKBE_EBELP,ZF_MSEG_MEINS_LIST,
			 ABS(SUM(ZF_EKBE_DMBTR_S_CUC)) AS ZF_EKBE_DMBTR_S_CUC
		FROM
		SU04_04_RT_EKBE_RELATE_PO
		GROUP BY EKBE_EBELN, EKBE_EBELP,ZF_MSEG_MEINS_LIST
) AS B	
	ON B.EKBE_EBELN = A.B09_EKKO_EBELN AND B.EKBE_EBELP = A.B09_EKPO_EBELP  



--// Step 5/ Using for summary table 
---Objective: Combine purchasing infor records and material numbers that are related to unlimited
--overdelivery allowed information

EXEC SP_DROPTABLE SU00_04_IT_PURCHASING_INFO_RECORDS;
SELECT  A_EINE.*,
        EINA_INFNR,
		EINA_MATNR,
		EINA_MATKL
INTO SU00_04_IT_PURCHASING_INFO_RECORDS
FROM A_EINA
INNER JOIN A_EINE
ON EINE_INFNR = EINA_INFNR

EXEC SP_RENAME_FIELD 'SU04_01_', SU04_01_RT_T405;
EXEC SP_RENAME_FIELD 'SU04_02_', SU04_02_XT_MARA_MATNR_WITH_UEBTK_EQ_X;
EXEC SP_RENAME_FIELD 'SU04_03_', SU04_03_RT_EINE_INFNR_EINA_INFNR;
EXEC SP_RENAME_FIELD 'SU04_04_', SU04_04_RT_EKBE_RELATE_PO;
EXEC SP_RENAME_FIELD 'SU04_05_', SU04_05_RT_EKPO_EKBE_MSEG_COMPARE_DMBTR_MEINS;
EXEC SP_UNNAME_FIELD 'B09_','SU04_05_RT_EKPO_EKBE_MSEG_COMPARE_DMBTR_MEINS'
EXEC SP_UNNAME_FIELD 'B09_','SU04_04_RT_EKBE_RELATE_PO'

	
GO
