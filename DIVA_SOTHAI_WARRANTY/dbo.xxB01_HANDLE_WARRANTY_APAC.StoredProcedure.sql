USE [DIVA_SOTHAI_WARRANTY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[xxB01_HANDLE_WARRANTY_APAC]
AS


-- Step 1 : Append the data for all region into 1 table.
DROP TABLE IF EXISTS A_WARRANTY_APAC_TEMP
SELECT * 
INTO A_WARRANTY_APAC_TEMP
FROM
(
	SELECT DISTINCT *  FROM Z_Repairset_SEV
	UNION
	SELECT  DISTINCT *  FROM Z_Repairset_ID
	UNION
	SELECT  DISTINCT *  FROM Z_Repairset_MY
	UNION
	SELECT  DISTINCT *  FROM Z_Repairset_PH
	UNION
	SELECT  DISTINCT *  FROM Z_Repairset_SG
	UNION
	SELECT  DISTINCT *  FROM Z_Repairset_TH
)
AS A


-- Step 2 / 
DROP TABLE IF EXISTS A_WARRANTY_APAC
SELECT 
	[Country] ,
	[Region] ,
	[RegionName] ,
	[ASC Code] ,
	[ASC Name] ,
	[ASC Code]+'-'+[ASC Name] AS ZF_ASC,
	[Job Number] ,
	CAST([Seq] as INT) as [Seq]  ,
	[Product Category] ,
	[Product Sub Category] ,
	[Product Category]+'-'+[Product Sub Category] AS ZF_PRODUCT_CATEGORY_SUB,
	[Model Code] ,
	[Model Name] ,
	[Model Code]+'-'+[Model Name] AS ZF_MODEL,
	[Serial No] ,
	[Service Type] ,
	[Transfer_flag] ,
	[transfer_job_no] ,
	[Guarantee Code] ,
	[Customer Group] ,
	[CUSTOMER_NAME] ,
	[EMAIL] ,
	[LINKMAN] ,
	[PHONE] ,
	[MOBIL] ,
	[ADDRES] ,
	[CITY] ,
	[PROVINCE] ,
	[CITY]+'-'+[PROVINCE] AS ZF_CITY_PROVINCE,
	[POST_CODE] ,
	IIF(LEN([Purchased Date]) = 19,CONVERT(DATETIME, [Purchased Date], 102),CONVERT(DATETIME, [Purchased Date], 3)) as [Purchased Date],	
	[Warranty Type] ,
	[Warranty Category] ,
	[Warranty Card No] ,
	[Warranty Card Type] ,
	[Technician] ,
    IIF(LEN([Reservation Create Date]) = 19,CONVERT(DATETIME, [Reservation Create Date], 102),CONVERT(DATETIME, [Reservation Create Date], 3)) as [Reservation Create Date],
    IIF(LEN([Job Create Date]) = 19,CONVERT(DATETIME, [Job Create Date], 102),CONVERT(DATETIME, [Job Create Date], 3)) as [Job Create Date],
    IIF(LEN([First Allocation Date]) = 19,CONVERT(DATETIME, [First Allocation Date], 102),CONVERT(DATETIME, [First Allocation Date], 3)) as [First Allocation Date],
    IIF(LEN([Begin Repair Date]) = 19,CONVERT(DATETIME, [Begin Repair Date], 102),CONVERT(DATETIME, [Begin Repair Date], 3)) as [Begin Repair Date],
    IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) as [Repair Completed Date],
    IIF(LEN([Repair Returned Date]) = 19,CONVERT(DATETIME, [Repair Returned Date], 102),CONVERT(DATETIME, [Repair Returned Date], 3)) as [Repair Returned Date],	
	[Part Code] ,
	[Part Desc] ,
	[Repair Qty] ,
	CAST([Part Unit Price] as float) as [Part Unit Price] ,
	[PO NO] ,
    IIF(LEN([PO Create Date]) = 19,CONVERT(DATETIME, [PO Create Date], 102),CONVERT(DATETIME, [PO Create Date], 3)) as [PO Create Date],
    IIF(LEN([Shipped Date]) = 19,CONVERT(DATETIME, [Shipped Date], 102),CONVERT(DATETIME, [Shipped Date], 3)) as [Shipped Date],
    IIF(LEN([PARTS RECEIVED Date]) = 19,CONVERT(DATETIME, [PARTS RECEIVED Date], 102),CONVERT(DATETIME, [PARTS RECEIVED Date], 3)) as [PARTS RECEIVED Date],
	[Symptom Code] ,
	[Section Code] ,
	[Defect Code] ,
	[Repair Code] ,
	[Repair Level] ,
	[Repair Fee Type] ,
	CAST([Part Fee] as float) as [Part Fee] ,
	CAST([Inspection Fee] as float) as [Inspection Fee] ,
	CAST([Handling Fee] as float) as [Handling Fee] ,
	CAST([Labor Fee] as float) as [Labor Fee] ,
	CAST([Home Service Fee] as float) as [Home Service Fee] ,
	CAST([Long fee] as float) as [Long fee] ,
	CAST([Install Fee] as float) as [Install Fee] ,
	CAST([Total Amount Of Account Payable] as float) as [Total Amount Of Account Payable] ,
	CAST([Account Payable By Customer] as float) as [Account Payable By Customer] ,
	CAST([Sony Needs To Pay] as float) as [Sony Needs To Pay] ,
	CAST([ASC pay] as float) as [ASC pay] ,
	[CR90] ,
	[RR90] ,
	[Repair TAT] ,
	[4D] ,
	[Model 6D] ,
	[6D Desc] ,
	[Model 6D]+'-'+[6D Desc] AS ZF_MODEL_6D,
	[NPRR] ,
	[Repair Action/Technician Remarks] ,
	[St_type] ,
    IIF(LEN([LAST Allocation Date]) = 19,CONVERT(DATETIME, [LAST Allocation Date], 102),CONVERT(DATETIME, [LAST Allocation Date], 3)) as [LAST Allocation Date],
	CAST([vendor Part Price] as float) as [vendor Part Price] ,
    IIF(LEN([FIRST_ESTIMATION_CREATE_DATE]) = 19,CONVERT(DATETIME, [FIRST_ESTIMATION_CREATE_DATE], 102),CONVERT(DATETIME, [FIRST_ESTIMATION_CREATE_DATE], 3)) as [FIRST_ESTIMATION_CREATE_DATE],
    IIF(LEN([LAST_ESTIMATION_DATE]) = 19,CONVERT(DATETIME, [LAST_ESTIMATION_DATE], 102),CONVERT(DATETIME, [LAST_ESTIMATION_DATE], 3)) as [LAST_ESTIMATION_DATE],
	[ESTIMATION_TAT] ,
	[LATEST_ESTIMATE_STATUS] ,
    IIF(LEN([PARTS_REQUEST_DATE]) = 19,CONVERT(DATETIME, [PARTS_REQUEST_DATE], 102),CONVERT(DATETIME, [PARTS_REQUEST_DATE], 3)) as [PARTS_REQUEST_DATE],
	[PARTS_WAITING_TAT] ,
    IIF(LEN([LAST_STATUS_UPDATE_DATE]) = 19,CONVERT(DATETIME, [LAST_STATUS_UPDATE_DATE], 102),CONVERT(DATETIME, [LAST_STATUS_UPDATE_DATE], 3)) as [LAST_STATUS_UPDATE_DATE],
	[Customer_Complaint] ,
	[Symptom_Confirmed_By_Technician] ,
	[IRIS_Line_Transfer_flag] ,
	[CCC_ID] ,
	[Assigned_by] ,
	[Condition_code] ,
	[Part_6D] ,
	[convertToJob_in_MAPP] ,
	[completed_in_MAPP] ,
	[deliver_in_MAPP ] ,
	[reserve_id] ,
	[Caused by customer] ,
	[internal message] ,
	CAST([Adjustment Fee] as float) as [Adjustment Fee] ,
	CAST([DA Fee] as float) as [DA Fee] ,
	CAST([Fit/Unfit Fee] as float) as [Fit/Unfit Fee] ,
	CAST([MU Fee] as float) as [MU Fee] ,
	CAST([Travel Allowance Fee] as float) as [Travel Allowance Fee] ,
	[Region2] ,
	[Updated by CCC User] ,
	[Dealer Name] ,
    IIF(LEN([ Parts Date Updated]) = 19,CONVERT(DATETIME, [ Parts Date Updated], 102),CONVERT(DATETIME, [ Parts Date Updated], 3)) as [Parts Date Updated],
	IIF(LEN([ Parts Allocated Date]) = 19,CONVERT(DATETIME, [ Parts Allocated Date], 102),CONVERT(DATETIME, [ Parts Allocated Date], 3)) as [Parts Allocated Date],
	[Repair_Type] 
INTO A_WARRANTY_APAC
FROM A_WARRANTY_APAC_TEMP

/*

-- Step 3 / Need to add 3 filters based on LAST_STATUS_UPDATE_DATE

ALTER TABLE A_WARRANTY_APAC ADD [Z_Calendar Year]  NVARCHAR(4);
ALTER TABLE A_WARRANTY_APAC ADD [Z_Fiscal Year]  NVARCHAR(4);
ALTER TABLE A_WARRANTY_APAC ADD [Z_Month]  NVARCHAR(2);


UPDATE A_WARRANTY_APAC
SET [Z_Calendar Year] = YEAR(LAST_STATUS_UPDATE_DATE), [Z_Month] = MONTH(LAST_STATUS_UPDATE_DATE)


UPDATE A_WARRANTY_APAC
SET  [Z_Fiscal Year] = 
	 
	CASE 
		WHEN CAST(LAST_STATUS_UPDATE_DATE AS DATE) >= '2020-04-01' AND CAST(LAST_STATUS_UPDATE_DATE AS DATE) <= '2021-03-31' THEN 2020
		WHEN CAST(LAST_STATUS_UPDATE_DATE AS DATE) >= '2021-04-01' AND CAST(LAST_STATUS_UPDATE_DATE AS DATE) <= '2022-03-31' THEN 2021
		WHEN CAST(LAST_STATUS_UPDATE_DATE AS DATE) >= '2022-04-01' AND CAST(LAST_STATUS_UPDATE_DATE AS DATE) <= '2023-03-31' THEN 2022
		WHEN CAST(LAST_STATUS_UPDATE_DATE AS DATE) >= '2023-04-01' AND CAST(LAST_STATUS_UPDATE_DATE AS DATE) <= '2024-03-31' THEN 2023
	END


-- Step 4 / Need to add local currency for warranty

SELECT 
  'PH' AS ZF_REGION	,'PHP' AS ZF_LOCAL_CURRENCY, CAST(0.0181 AS FLOAT) AS ZF_EXCHANGE INTO AM_CURRENCY_MAPPING
UNION
SELECT 
'TH', 'THB', CAST(0.0292 AS FLOAT) AS ZF_EXCHANGE
UNION
SELECT 
'ID', 'IDR', CAST(0.0001 AS FLOAT) AS ZF_EXCHANGE
UNION
SELECT 
'MY', 'MYR', CAST(0.223  AS FLOAT) AS ZF_EXCHANGE
UNION
SELECT 
'VN', 'VND', CAST(0.00004243  AS FLOAT) AS ZF_EXCHANGE
UNION
SELECT 
'SG', 'SGD', CAST(0.7479  AS FLOAT) AS ZF_EXCHANGE

SELECT DISTINCT RegionName, Region FROM A_WARRANTY_APAC



SELECT 
DISTINCT *
FROM A_WARRANTY_APAC
WHERE [Warranty Type] ='OW' AND [Sony Needs To Pay] <> 0 AND [Repair Fee Type] = 'Chargeable' 
order BY [Sony Needs To Pay] DESC


SELECT [Total Amount Of Account Payable], [Account Payable By Customer] + [Sony Needs To Pay] + [ASC pay],
[Total Amount Of Account Payable] - ([Account Payable By Customer] + [Sony Needs To Pay] + [ASC pay]) as zf, [Repair TAT]
FROM A_WARRANTY_APAC
WHERE [Total Amount Of Account Payable] <> [Account Payable By Customer] + [Sony Needs To Pay] + [ASC pay]
order by zf desc



SELECT 
DISTINCT Country
 
FROM A_WARRANTY_APAC



ALTER TABLE A_WARRANTY_APAC ADD ZF_REPAIR_TAT_BUCKETS NVARCHAR(30);
ALTER TABLE A_WARRANTY_APAC ADD ZF_REP_COM_DATE_VS_RETURN_DATE_BUCKETS NVARCHAR(30);
ALTER TABLE A_WARRANTY_APAC ADD ZF_REP_COM_DATE_VS_LAST_UPDATE_DATE_BUCKETS NVARCHAR(30);
ALTER TABLE A_WARRANTY_APAC ADD ZF_PARTS_REQUEST_DATE_vS_PART_ALL_DATE_BUCKETS NVARCHAR(30);
ALTER TABLE A_WARRANTY_APAC ADD ZF_JOB_CREATED_DATE_VS_BEGIN_REP_DATE_BUCKETS NVARCHAR(30);
ALTER TABLE A_WARRANTY_APAC ADD ZF_JOB_CREATED_DATE_VS_LAST_STATUS_UPDATE_DATE_BUCKETS NVARCHAR(30);
ALTER TABLE A_WARRANTY_APAC ADD ZF_BEGIN_REP_DATE_VS_PARTS_REQUEST_DATE_BUCKETS NVARCHAR(30);
/*
- <1days
- 1-10days
- 11-20days
- 21-30days
- 31-60days
- 61-90days
- 91-180days
- 181-365days
- >365days


*/


UPDATE A_WARRANTY_APAC
SET ZF_REPAIR_TAT_BUCKETS =

CASE
	WHEN [Repair TAT] < 1 THEN '01_<1days'
	WHEN [Repair TAT] BETWEEN 1 AND 10 THEN '02_1-10days'
	WHEN [Repair TAT] BETWEEN 11 AND 20 THEN '03_11-20days'
	WHEN [Repair TAT] BETWEEN 21 AND 30 THEN '04_21-30days'
	WHEN [Repair TAT] BETWEEN 31 AND 60 THEN '05_31-60days'
	WHEN [Repair TAT] BETWEEN 61 AND 90 THEN '06_61-90days'
	WHEN [Repair TAT] BETWEEN 91 AND 180 THEN '07_91-180days'
	WHEN [Repair TAT] BETWEEN 181 AND 365 THEN '08_181-365days'	
	WHEN [Repair TAT] > 365 THEN '09_>365days'
END


UPDATE A_WARRANTY_APAC
SET ZF_REP_COM_DATE_VS_RETURN_DATE_BUCKETS =

	CASE
		WHEN YEAR([Repair Completed Date]) = 1900 OR YEAR([Repair Returned Date]) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], [Repair Returned Date])) > 365 THEN '10_>365days'
	END


UPDATE A_WARRANTY_APAC
SET ZF_REP_COM_DATE_VS_LAST_UPDATE_DATE_BUCKETS =

	CASE
		WHEN YEAR([Repair Completed Date]) = 1900 OR YEAR(LAST_STATUS_UPDATE_DATE) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Repair Completed Date], LAST_STATUS_UPDATE_DATE)) > 365 THEN '10_>365days'
	END


UPDATE A_WARRANTY_APAC
SET ZF_PARTS_REQUEST_DATE_vS_PART_ALL_DATE_BUCKETS =

	CASE
		WHEN YEAR(PARTS_REQUEST_DATE) = 1900 OR YEAR([Parts Allocated Date]) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, PARTS_REQUEST_DATE, [Parts Allocated Date])) > 365 THEN '10_>365days'
	END


UPDATE A_WARRANTY_APAC
SET ZF_JOB_CREATED_DATE_VS_BEGIN_REP_DATE_BUCKETS =

	CASE
		WHEN YEAR([Job Create Date]) = 1900 OR YEAR([Begin Repair Date]) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], [Begin Repair Date])) > 365 THEN '10_>365days'
	END



UPDATE A_WARRANTY_APAC
SET ZF_JOB_CREATED_DATE_VS_LAST_STATUS_UPDATE_DATE_BUCKETS =

	CASE
		WHEN YEAR([Job Create Date]) = 1900 OR YEAR(LAST_STATUS_UPDATE_DATE) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Job Create Date], LAST_STATUS_UPDATE_DATE)) > 365 THEN '10_>365days'
	END


UPDATE A_WARRANTY_APAC
SET ZF_BEGIN_REP_DATE_VS_PARTS_REQUEST_DATE_BUCKETS =

	CASE
		WHEN YEAR([Begin Repair Date]) = 1900 OR YEAR(PARTS_REQUEST_DATE) = 1900 THEN '02_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], PARTS_REQUEST_DATE)) > 365 THEN '10_>365days'
	END


	SELECT DISTINCT [Z_Fiscal Year] FROM A_WARRANTY_APAC
	WHERE [Z_Fiscal Year] IS NULL AND CAST(LAST_STATUS_UPDATE_DATE AS DATE) <= '2022-03-31'







SELECT [Total Amount Of Account Payable] - ([Account Payable By Customer] + [Sony Needs To Pay] + [ASC pay]), PAY
*
FROM A_WARRANTY_APAC
WHERE [Total Amount Of Account Payable] < ([Account Payable By Customer] + [Sony Needs To Pay] + [ASC pay])
ORDER BY  [Total Amount Of Account Payable] - ([Account Payable By Customer] + [Sony Needs To Pay] + [ASC pay])



SELECT DISTINCT LEN([Serial No]), COUNT(*)
FROM A_WARRANTY_APAC
GROUP BY LEN([Serial No])



SELECT DISTINCT [Serial No]
FROM A_WARRANTY_APAC
WHERE [Purchased Date] = '1900-01-01 00:00:00.000'



ALTER TABLE A_WARRANTY_APAC ADD ZF_OW_SONY_NEED_PAY NVARCHAR(3);


UPDATE A_WARRANTY_APAC
SET ZF_OW_SONY_NEED_PAY = 'No'

UPDATE A_WARRANTY_APAC
SET ZF_OW_SONY_NEED_PAY = 'Yes'
WHERE [Repair Fee Type] = 'Chargeable' and [Warranty Type] = 'OW' AND [Sony Needs To Pay] > 0


ALTER TABLE A_WARRANTY_APAC ADD ZF_STRANGE_OF_SER_NO NVARCHAR(3);

UPDATE A_WARRANTY_APAC
SET ZF_STRANGE_OF_SER_NO = 'No'

UPDATE A_WARRANTY_APAC
SET ZF_STRANGE_OF_SER_NO = 'Yes'
WHERE 
([Serial No] NOT LIKE '%[a-zA-Z0-9]%'
OR [Serial No] LIKE 'x%' or LEN(REPLACE([Serial No], '0', '')) = 0 OR [Serial No] = '1234567' or [Serial No] = '1111111'

OR LEN(REPLACE([Serial No], LEFT([Serial No],1),'')) = 0 
) AND [Serial No] <> ''

SELECT 
DISTINCT [Serial No]
FROM A_WARRANTY_APAC
WHERE ZF_STRANGE_OF_SER_NO = 'Yes'



SELECT DISTINCT 
[Serial No] , (REPLACE([Serial No], '0', ''))

FROM A_WARRANTY_APAC
WHERE LEN(REPLACE([Serial No], '0', '')) = 0


SELECT DISTINCT 
[Serial No] 

FROM A_WARRANTY_APAC
WHERE  [Serial No] NOT LIKE '%[a-zA-Z0-9]%'
OR [Serial No] LIKE 'x%' or LEN(REPLACE([Serial No], '0', '')) = 0



select DISTINCT [Serial No], COUNT(DISTINCT [Job Number])
FROM A_WARRANTY_APAC
where ZF_STRANGE_OF_SER_NO = 'No'
GROUP BY [Serial No] 
HAVING COUNT(DISTINCT Country) > 1
ORDER BY  COUNT(DISTINCT [Job Number]) DESC


SELECT DISTINCT [Serial No], *
FROM A_WARRANTY_APAC
WHERE [Serial No] = '4000149'


SELECT  Region FROM A_WARRANTY_APAC


SELECT 
	[Serial No],
	MOBIL,
	COUNT(DISTINCT Country+[Job Number])
FROM A_WARRANTY_APAC
INNER JOIN AM_CURRENCY_MAPPING ON Country = AM_CURRENCY_MAPPING.ZF_REGION
WHERE ZF_MODEL_6D LIKE '%TV%' AND [Warranty Type] = 'OW' AND [Sony Needs To Pay] * ZF_EXCHANGE > 1000
GROUP BY [Serial No], MOBIL
HAVING COUNT(DISTINCT Country+[Job Number]) > 1
ORDER BY COUNT(DISTINCT Country+[Job Number]) DESC 


SELECT DISTINCT 
	[Begin Repair Date] as Begin_Repair_Date, 
	LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]) AS previous_date,
	DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]), [Begin Repair Date]) AS ZF_DIFF_DATE,
	Country, 
	[ASC Code], [ASC Name],
	[Serial No], 
	[Model 6D], [6D Desc], 
	[Model Code], [Model Name],	[Job Number],
	[Account Payable By Customer],
	[ASC pay],

	[Sony Needs To Pay],
	[Total Amount Of Account Payable],
	[Warranty Type],
	[Repair Fee Type],
	*
FROM A_WARRANTY_APAC
WHERE [Serial No] = '3804976' and MOBIL = '0882665828'
ORDER BY [Begin Repair Date] 




SELECT DISTINCT 
	[Begin Repair Date] as Begin_Repair_Date, 
	LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]) AS previous_date,
	DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]), [Begin Repair Date]) AS ZF_DIFF_DATE,
	Country, 
	[ASC Code], [ASC Name],
	[Serial No], 
	[Model 6D], [6D Desc], 
	[Model Code], [Model Name],	[Job Number],
	[Account Payable By Customer],
	[ASC pay],

	[Sony Needs To Pay],
	[Total Amount Of Account Payable],
	[Warranty Type],
	[Repair Fee Type],
	*
FROM A_WARRANTY_APAC
WHERE [Serial No] = '3903365' and MOBIL = '013-3534458'
ORDER BY [Begin Repair Date] 



SELECT DISTINCT 
	[Begin Repair Date] as Begin_Repair_Date, 
	LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]) AS previous_date,
	DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]), [Begin Repair Date]) AS ZF_DIFF_DATE,
	Country, 
	[ASC Code], [ASC Name],
	[Serial No], 
	[Model 6D], [6D Desc], 
	[Model Code], [Model Name],	[Job Number],
	[Account Payable By Customer],
	[ASC pay],

	[Sony Needs To Pay],
	[Total Amount Of Account Payable],
	[Warranty Type],
	[Repair Fee Type],
	*
FROM A_WARRANTY_APAC
WHERE [Serial No] = '6006243' and MOBIL = '017-5708825'
ORDER BY [Begin Repair Date] 


SELECT DISTINCT 
	[Begin Repair Date] as Begin_Repair_Date, 
	LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]) AS previous_date,
	DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]), [Begin Repair Date]) AS ZF_DIFF_DATE,
	Country, 
	[ASC Code], [ASC Name],
	[Serial No], 
	[Model 6D], [6D Desc], 
	[Model Code], [Model Name],	[Job Number],
	[Account Payable By Customer],
	[ASC pay],

	[Sony Needs To Pay],
	[Total Amount Of Account Payable],
	[Warranty Type],
	[Repair Fee Type],
	*
FROM A_WARRANTY_APAC
WHERE [Serial No] = '6200040' and MOBIL = '0125880178'
ORDER BY [Begin Repair Date] 
SELECT 
((

	[Adjustment Fee]+
	[DA Fee]+
	[Fit/Unfit Fee] +
	[Handling Fee] +
	[Home Service Fee] +
	[Inspection Fee]+
	[Install Fee]+
	[Labor Fee]+
	[Long fee]+
	[MU Fee]+
	[Part Fee]

)) - [Total Amount Of Account Payable],
[Adjustment Fee],
[DA Fee],
[Fit/Unfit Fee],
[Handling Fee],
[Home Service Fee],
[Inspection Fee],
[Install Fee],
[Labor Fee],
[Long fee],
[MU Fee],
[Part Fee],
[Repair Fee Type],
[Travel Allowance Fee],
[vendor Part Price],
[Total Amount Of Account Payable],
[Sony Needs To Pay],
[ASC pay],
[Account Payable By Customer],
[Part Unit Price],
[vendor Part Price],
[Labor Fee] + [Part Fee],
*
FROM A_WARRANTY_APAC
WHERE
(

	[Adjustment Fee]+
	[DA Fee]+
	[Fit/Unfit Fee] +
	[Handling Fee] +
	[Home Service Fee] +
	[Inspection Fee]+
	[Install Fee]+
	[Labor Fee]+
	[Long fee]+
	[MU Fee]+
	[Part Fee]

) > [Total Amount Of Account Payable]

ORDER BY ((

	[Adjustment Fee]+
	[DA Fee]+
	[Fit/Unfit Fee] +
	[Handling Fee] +
	[Home Service Fee] +
	[Inspection Fee]+
	[Install Fee]+
	[Labor Fee]+
	[Long fee]+
	[MU Fee]+
	[Part Fee]

)) - [Total Amount Of Account Payable] DESC


SELECT [Job Number], Country
FROM A_WARRANTY_APAC
GROUP BY [Job Number], Country
HAVING COUNT(*) > 1


SELECT 'B' as A INTO TEMP
UNION 
SELECT 'C'
UNION
SELECT 'D'
UNION
SELECT 'E'





SELECT 
	[Serial No],
	MOBIL,
	COUNT(DISTINCT Country+[Job Number])
FROM A_WARRANTY_APAC
INNER JOIN AM_CURRENCY_MAPPING ON Country = AM_CURRENCY_MAPPING.ZF_REGION
WHERE ZF_MODEL_6D LIKE '%TV%' AND [Warranty Type] = 'OW' AND [Sony Needs To Pay] * ZF_EXCHANGE > 1000
GROUP BY [Serial No], MOBIL
HAVING COUNT(DISTINCT Country+[Job Number]) > 1
ORDER BY COUNT(DISTINCT Country+[Job Number]) DESC 


SELECT DISTINCT 
	[Begin Repair Date] as Begin_Repair_Date, 
	LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]) AS previous_date,
	DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]), [Begin Repair Date]) AS ZF_DIFF_DATE,
	Country, 
	[ASC Code], [ASC Name],
	[Serial No], 
	[Model 6D], [6D Desc], 
	[Model Code], [Model Name],	[Job Number],
	[Account Payable By Customer],
	[ASC pay],

	[Sony Needs To Pay],
	[Total Amount Of Account Payable],
	[Warranty Type],
	[Repair Fee Type],
		[Defect Code],
	[Repair Code],
	[Section Code],
	[Symptom Code],
	*
FROM A_WARRANTY_APAC
WHERE [Serial No] = '3804976' and MOBIL = '0882665828'
ORDER BY [Begin Repair Date] 


-- serial no : 
-- customer : Mobile

SELECT DISTINCT LEN([Serial No]), COUNT(*)
FROM A_WARRANTY_APAC
GROUP BY LEN([Serial No])
ORDER BY COUNT(*) DESC

-- Len of Serial No not in 7 or 15





SELECT DISTINCT 
	[Begin Repair Date] as Begin_Repair_Date, 
	LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]) AS previous_date,
	DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]), [Begin Repair Date]) AS ZF_DIFF_DATE,
	Country, 
	[ASC Code], [ASC Name],
	[Serial No], 
	[Model 6D], [6D Desc], 
	[Model Code], [Model Name],	[Job Number],
	[Account Payable By Customer],
	[ASC pay],

	[Sony Needs To Pay],
	[Total Amount Of Account Payable],
	[Warranty Type],
	[Repair Fee Type],
	*
FROM A_WARRANTY_APAC
WHERE [Serial No] = '3903365' and MOBIL = '013-3534458'
ORDER BY [Begin Repair Date] 



SELECT DISTINCT 
	[Begin Repair Date] as Begin_Repair_Date, 
	LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]) AS previous_date,
	DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (ORDER BY [Begin Repair Date]), [Begin Repair Date]) AS ZF_DIFF_DATE,
	Country, 
	[ASC Code], [ASC Name],
	[Serial No], 
	[Model 6D], [6D Desc], 
	[Model Code], [Model Name],	[Job Number],
	[Account Payable By Customer],
	[ASC pay],

	[Sony Needs To Pay],
	[Total Amount Of Account Payable],
	[Warranty Type],
	[Repair Fee Type],
	[Defect Code],
	[Repair Code],
	[Section Code],
	[Symptom Code],
	*
FROM A_WARRANTY_APAC
WHERE [Serial No] = '6006243' and MOBIL = '017-5708825'
ORDER BY [Begin Repair Date] 

should not

some error code 90 SONY should not pay again



Same defect  code => date repair < 90 : SONY should not need to pay
-- IW : Warranty type :




ALTER TABLE A_WARRANTY_APAC ADD ZF_SERIAL_NUMBER_7_15_FLAG NVARCHAR(3);


UPDATE A_WARRANTY_APAC
SET ZF_SERIAL_NUMBER_7_15_FLAG = 'No'


UPDATE A_WARRANTY_APAC
SET ZF_SERIAL_NUMBER_7_15_FLAG = 'Yes'
WHERE LEN([Serial No]) NOT IN (7,15)


DROP TABLE IF EXISTS WARRANTY_APAC_TEMP

SELECT 

ROW_NUMBER() OVER(PARTITION BY  CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL)) ORDER BY  [Begin Repair Date])  AS STT,
[Begin Repair Date] AS Begin_Repair_Date,
LAG([Begin Repair Date]) OVER (PARTITION BY  CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL)) ORDER BY  [Begin Repair Date]) AS Previous_Begin_Repair_Date,
DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (PARTITION BY  CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL)) ORDER BY  [Begin Repair Date]) , [Begin Repair Date]) as ZF_DAY_MINUS_PREVI_DAY,

*
INTO WARRANTY_APAC_TEMP
FROM A_WARRANTY_APAC
WHERE [Warranty Type] = 'IW' AND [Sony Needs To Pay] > 0 AND ZF_STRANGE_OF_SER_NO = 'No'  AND [Serial No] <> '' AND ISNULL(PHONE, MOBIL) <> ''
AND CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL)) IN 
(

	SELECT 
		CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL))
	FROM A_WARRANTY_APAC
	WHERE [Warranty Type] = 'IW' AND [Sony Needs To Pay] > 0 AND ZF_STRANGE_OF_SER_NO = 'No' AND [Serial No] <> '' AND ISNULL(PHONE, MOBIL) <> ''
	GROUP BY [Defect Code], [Serial No], ISNULL(PHONE, MOBIL)
	HAVING COUNT(DISTINCT [Job Number]+Country) > 1


)
AND Seq = 1

DROP TABLE IF EXISTS  WARRANTY_APAC_TEMP_FILTER
SELECT 
*
INTO WARRANTY_APAC_TEMP_FILTER
FROM WARRANTY_APAC_TEMP 
WHERE ZF_DAY_MINUS_PREVI_DAY < 90
UNION 
SELECT 
*
FROM WARRANTY_APAC_TEMP 
WHERE  CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL),(STT)) IN
(
	
	SELECT 
		CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL),(STT-1))
	FROM WARRANTY_APAC_TEMP 
	WHERE ZF_DAY_MINUS_PREVI_DAY < 90

)


SELECT COUNT(*) FROM WARRANTY_APAC_TEMP_FILTER
WHERE 	 ZF_DAY_MINUS_PREVI_DAY < 90


ALTER TABLE A_WARRANTY_APAC ADD ZF_REPAIR_90_SONY_NEED_TO_PAY NVARCHAR(3);
ALTER TABLE A_WARRANTY_APAC ADD ZF_REPAIR_90_SONY_NEED_TO_PAY_PREVIOUS NVARCHAR(3);

UPDATE A_WARRANTY_APAC
SET ZF_REPAIR_90_SONY_NEED_TO_PAY_PREVIOUS = 'No'


UPDATE A_WARRANTY_APAC
SET ZF_REPAIR_90_SONY_NEED_TO_PAY_PREVIOUS = 'Yes'

FROM A_WARRANTY_APAC A 
JOIN  WARRANTY_APAC_TEMP_FILTER B ON 
	 CONCAT (
	A.[Serial No],
	A.[Job Number],
	A.Country,
	A.[Model 6D],
	A.[Model Code],
	A.Seq
) = 	
CONCAT (
	B.[Serial No],
	B.[Job Number],
	B.Country,
	B.[Model 6D],
	B.[Model Code],
	B.Seq)
WHERE B.ZF_DAY_MINUS_PREVI_DAY IS NULL


SELECT *
FROM A_WARRANTY_APAC
WHERE ZF_REPAIR_90_SONY_NEED_TO_PAY_PREVIOUS = 'Yes'



ALTER TABLE A_WARRANTY_APAC ADD ZF_REPAIR_90_PREVIOUS_DAY DATETIME;
ALTER TABLE A_WARRANTY_APAC ADD ZF_REPAIR_90_PREVIOUS_DAY_DIFF NVARCHAR(3);

ALTER TABLE A_WARRANTY_APAC ADD ZF_CASE_ID INT;



UPDATE A_WARRANTY_APAC
SET ZF_REPAIR_90_SONY_NEED_TO_PAY = 'No'


UPDATE A_WARRANTY_APAC
SET ZF_REPAIR_90_SONY_NEED_TO_PAY = 'Yes'
FROM A_WARRANTY_APAC A 
JOIN  WARRANTY_APAC_TEMP_FILTER B ON 
	 CONCAT (
	A.[Serial No],
	A.[Job Number],
	A.Country,
	A.[Model 6D],
	A.[Model Code],
	A.Seq
) = 	
CONCAT (
	B.[Serial No],
	B.[Job Number],
	B.Country,
	B.[Model 6D],
	B.[Model Code],
	B.Seq)
WHERE B.ZF_DAY_MINUS_PREVI_DAY < 90





UPDATE A_WARRANTY_APAC
SET ZF_REPAIR_90_PREVIOUS_DAY = B.Previous_Begin_Repair_Date,
ZF_REPAIR_90_PREVIOUS_DAY_DIFF = B.ZF_DAY_MINUS_PREVI_DAY
FROM A_WARRANTY_APAC A 
JOIN  WARRANTY_APAC_TEMP_FILTER B ON 
	 CONCAT (
	A.[Serial No],
	A.[Job Number],
	A.Country,
	A.[Model 6D],
	A.[Model Code],
	A.Seq
) = 	
CONCAT (
	B.[Serial No],
	B.[Job Number],
	B.Country,
	B.[Model 6D],
	B.[Model Code],
	B.Seq)
WHERE B.ZF_DAY_MINUS_PREVI_DAY < 90








ALTER TABLE A_WARRANTY_APAC ADD ZF_CASE_ID INT;

UPDATE A_WARRANTY_APAC
SET ZF_CASE_ID = CASE_ID
FROM A_WARRANTY_APAC  A 
JOIN (

	SELECT 

	ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS CASE_ID

	,*
	FROM WARRANTY_APAC_TEMP 
	WHERE ZF_DAY_MINUS_PREVI_DAY < 90
) AS B ON  CONCAT(A.[Serial No],A.[Defect Code],ISNULL(A.PHONE, A.MOBIL)) = 
 CONCAT(B.[Serial No],B.[Defect Code],ISNULL(B.PHONE, B.MOBIL))

 e

SELECT ZF_CASE_ID
FROM A_WARRANTY_APAC
GROUP BY ZF_CASE_ID
HAVING COUNT(*) > 5

SELECT * FROM TEMP
WHERE 'A' = 'A'



DROP TABLE AM_CONDITION_MAPPING
DROP TABLE AM_CURRENCY_MAPPING
DROP TABLE AM_DEFECT_CODE_MAPPING
DROP TABLE AM_REPAIR_CODE_MAPPING
DROP TABLE AM_SECTION_CODE_MAPPING
DROP TABLE AM_SYMPTON_CODE_MAPPING


SELECT DISTINCT [Symptom Code]
FROM A_WARRANTY_APAC
where [Symptom Code] LIKE '%502%'

select * from A_WARRANTY_APAC
Condition_Code
1

UPDATE A_WARRANTY_APAC
SET A_WARRANTY_APAC.Condition_code = CONCAT(A_WARRANTY_APAC.Condition_code,' - ', B.[Desc])
FROM A_WARRANTY_APAC 
JOIN AM_CONDITION_MAPPING B ON A_WARRANTY_APAC.Condition_Code = B.Condition_Code


ALTER TABLE A_WARRANTY_APAC ALTER COLUMN [Defect Code] NVARCHAR(1000)

UPDATE A_WARRANTY_APAC
SET A_WARRANTY_APAC.[Defect Code] = CONCAT(A_WARRANTY_APAC.[Defect Code],' - ', B.[Desc])
FROM A_WARRANTY_APAC 
JOIN AM_DEFECT_CODE_MAPPING B ON A_WARRANTY_APAC.[Defect Code] = B.Defect_Code



UPDATE A_WARRANTY_APAC
SET A_WARRANTY_APAC.[Repair Code] = CONCAT(A_WARRANTY_APAC.[Repair Code],' - ', B.[Desc])
FROM A_WARRANTY_APAC 
JOIN AM_REPAIR_CODE_MAPPING B ON A_WARRANTY_APAC.[Repair Code] = B.Repair_Code



UPDATE A_WARRANTY_APAC
SET A_WARRANTY_APAC.[Section Code] = CONCAT(A_WARRANTY_APAC.[Section Code],' - ', B.[Desc])
FROM A_WARRANTY_APAC 
JOIN AM_SECTION_CODE_MAPPING B ON A_WARRANTY_APAC.[Section Code] = B.Section_Code
Symptom_Code
0003

select * FROM AM_SYMPTON_CODE_MAPPING

UPDATE A_WARRANTY_APAC
SET A_WARRANTY_APAC.[Symptom Code] = CONCAT(A_WARRANTY_APAC.[Symptom Code],' - ', B.[Desc])
FROM A_WARRANTY_APAC 
JOIN AM_SYMPTON_CODE_MAPPING B ON A_WARRANTY_APAC.[Symptom Code] = B.Symptom_Code

*/
GO
