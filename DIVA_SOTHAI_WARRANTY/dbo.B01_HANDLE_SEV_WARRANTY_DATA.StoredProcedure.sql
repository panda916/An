USE [DIVA_SOTHAI_WARRANTY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[B01_HANDLE_SEV_WARRANTY_DATA]
AS

/*
       Title                : [B01_HANDLE_SEV_WARRANTY_DATA]
       Description   : 
    
       --------------------------------------------------------------
       Update history
       --------------------------------------------------------------
       Date                     |      Who                  |      Description
       DD-MM-YYYY                    Initials                      Initial version
       04-07-2024                      Thuan					   Create a cube to store SEV warranty data

*/


-- Step 1 / Create a cube to store SEV warranty data.
---- Combine the number and name columns together for easy analysis on Qliksense.
/*


use DIVA_SEV_WARRANTY_JULY_21_JUNE_23

SELECT distinct  [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] LIKE '%[a-zA-Z]%'
   and [Serial No] NOT LIKE  '%[0-9]%'

-- Case 1 : Serial number consists of letters only, no numbers.

SELECT [Sony Needs To Pay], [Total Amount Of Account Payable], [Account Payable By Customer],[ASC pay], [Warranty Type], [Serial No],*
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] in
(

	SELECT distinct  [Serial No]
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE [Serial No] LIKE '%[a-zA-Z]%'
	   and [Serial No] NOT LIKE  '%[0-9]%'
)
and seq = 1


-- Case 2 : Serial No is empty

SELECT [Sony Needs To Pay], [Total Amount Of Account Payable], [Account Payable By Customer],[ASC pay], [Warranty Type], [Serial No],*
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] in
(

	SELECT distinct  [Serial No]
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE [Serial No] = '' 
)
and seq = 1

-- Case 3 : The characters are all the same

SELECT distinct  [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE LEN(REPLACE([Serial No], LEFT([Serial No],1),'')) = 0 
and [Serial No] <> ''

-- Case 3 : len

SELECT distinct  LEN([Serial No]), COUNT(*)
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE SEQ = 1
GROUP BY LEN([Serial No])
ORDER BY COUNT(*) DESC


-- Case 4 : Serial No same Model code / Model name

SELECT DISTINCT [Serial No], [Job Number], [Model Code], [Model Name], ZF_FLAG
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE (TRIM([Model Code]) = TRIM([Serial No])
OR
TRIM(REPLACE( REPLACE([Model Name],'VN3','') ,'KD-','')) = TRIM(REPLACE( REPLACE([Serial No],'VN3','') ,'KD-','')))

-- Case 5 : Serial no same phone/mobie

SELECT DISTINCT [Serial No], MOBIL, PHONE
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE 
(
	[Serial No] = MOBIL OR 
	[Serial No] = PHONE
)

AND [Serial No] <> ''

-- Case 6 : [Serial No] Like VN

SELECT DISTINCT [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] LIKE 'VN%'
OR 
[Serial No] LIKE 'SVN%'


-- Serial No = Warranty card no ? 


-- CASE 2 : Same serial No different model code and product category

select *
from B01_04_IT_WARRANTY_FINAL_DATA
where [Serial No] IN (
SELECT [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] <> ''
GROUP BY [Serial No]
HAVING COUNT(DISTINCT [Model Code]) > 1
AND COUNT(DISTINCT [Product Category]) > 1
)
ORDER BY [Sony Needs To Pay] DESC

-- Same serial no diff  model code : 67,187
-- Same serial no diff model code and diff Product category 2629

SELECT 		
      [Job Number], 
	  Seq,
      [Serial No], 
	  [Warranty Type],
      [Model 6D] ,
      [6D Desc] ,
      [Model Code] ,
      [Model Name] ,
      [Job Number], 
      [ASC Code],
	  [ASC Name],
      [Product Category] ,
      [Product Sub Category] ,
      [Account Payable By Customer],
      [ASC pay],
      [Sony Needs To Pay],
	  [Total Amount Of Account Payable],
	  CUSTOMER_NAME,
	  MOBIL,
	  PHONE,
	  [Begin Repair Date],
	  [Repair Completed Date],
	  Customer_Complaint,
	  [Repair Action/Technician Remarks]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] = '4000008'
AND SEQ = 1
ORDER BY [Sony Needs To Pay] DESC


------------------------ SAME WAR CARD NO DIFF SER 

SELECT [Warranty Card No], COUNT(DISTINCT [Serial No])
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Warranty Card No] <> '' AND [Serial No] <> ''
GROUP BY [Warranty Card No]
HAVING COUNT(DISTINCT [Serial No]) > 1
ORDER BY COUNT(DISTINCT [Serial No]) DESC

-- 35,567 WAR
-- CADBCGFBJC

SELECT 		
      [Job Number], 
	  Seq,
      [Serial No], 
	  [Warranty Card No],
	  [Warranty Type],
      [Model 6D] ,
      [6D Desc] ,
      [Model Code] ,
      [Model Name] ,
      [Job Number], 
      [ASC Code],
	  [ASC Name],
      [Product Category] ,
      [Product Sub Category] ,
      [Account Payable By Customer],
      [ASC pay],
      [Sony Needs To Pay],
	  [Total Amount Of Account Payable],
	  CUSTOMER_NAME,
	  MOBIL,
	  PHONE,
	  [Begin Repair Date],
	  [Repair Completed Date],
	  Customer_Complaint,
	  [Repair Action/Technician Remarks]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Warranty Card No] = 'CADBCGFBJC'
AND SEQ = 1
ORDER BY [Sony Needs To Pay] DESC

----- 4

SELECT DISTINCT MOBIL, PHONE, COALESCE(NULLIF(MOBIL, ''), PHONE), ZF_FLAG, [Job Number]
FROM B01_04_IT_WARRANTY_FINAL_DATA
where MOBIL = ''


select CUSTOMER_NAME, COALESCE(NULLIF(MOBIL, ''), PHONE), [Serial No], COUNT(*)
from B01_04_IT_WARRANTY_FINAL_DATA_BK 
WHERE CUSTOMER_NAME <> ''
AND COALESCE(NULLIF(MOBIL, ''), PHONE) <> ''
AND SEQ = 1
GROUP BY CUSTOMER_NAME, COALESCE(NULLIF(MOBIL, ''), PHONE), [Serial No]
ORDER BY COUNT(*) DESC



SELECT 		
      [Job Number], 
	  Seq,
      [Serial No], 
	  [Warranty Card No],
	  [Warranty Type],
      [Model 6D] ,
      [6D Desc] ,
      [Model Code] ,
      [Model Name] ,
      [Job Number], 
      [ASC Code],
	  [ASC Name],
      [Product Category] ,
      [Product Sub Category] ,
      [Account Payable By Customer],
      [ASC pay],
      [Sony Needs To Pay],
	  [Total Amount Of Account Payable],
	  CUSTOMER_NAME,
	  MOBIL,
	  PHONE,
	  [Begin Repair Date],
	  [Repair Completed Date],
	  Customer_Complaint,
	  [Repair Action/Technician Remarks]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE MOBIL = '0945525494'
AND SEQ = 1
ORDER BY [Sony Needs To Pay] DESC








SELECT DISTINCT 
	LEN([Serial No]),
	COUNT(*)
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE SEQ = 1
GROUP BY LEN([Serial No])
ORDER BY  LEN([Serial No])


SELECT 
	DISTINCT [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] LIKE '456789'
order by [Serial No]

-- Len(Serial no) = 1

-- unknow
-- containt VN


SELECT distinct  [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] LIKE '%?%'
   or [Serial No] NOT LIKE  '%[a-zA-Z0-9]%'



SELECT 
	DISTINCT [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE LEN([Serial No] ) = 7

-- Len(Serial no) = 2
SELECT 
	DISTINCT [Serial No],*
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE LEN([Serial No] ) = 2

--
SELECT 
	DISTINCT [Serial No], ZF_FLAG,*
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE LEN([Serial No] ) = 16

SELECT 
	DISTINCT [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE LEN([Serial No] ) = 



SELECT DISTINCT [Serial No], [Job Number]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_STRANGE_OF_SER_NO = 'YES' 



	[Serial No] NOT LIKE  '%[a-zA-Z0-9]%' -- The Serial numbers  does not contain the numbers a to z or 0 to 9
	OR 	[Serial No] LIKE 'x%'   -- The Serial numbers start with x
	OR LEN(REPLACE([Serial No], LEFT([Serial No],1),'')) = 0 



UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_OF_SER_NO = 'YES'
WHERE [Serial No] = ''

-- 109


select *
from B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] LIKE 'x%'



SELECT *
FR

-- Question 1 / Country : N/A 
-- Update to SEV

-- Question 2 / Missing value
-- TOTAL rows in csv file first time received file :  361, 463
SELECT COUNT(*)
FROM DIVA_SEV_FY2023..RepairedSet_SEV_Report_20230701_to_20241021

-- New txt tab file : 360, 771
-- MISSING : 692 ROWS ?
-- SELECT 361463 - 360771

-- JC0115492

SELECT *
FROM MISSING_VALUE


-- Question 3 :
-- 1 Job number samne betwwen Warranty :

-- 2021-07-01 to 2023-06-30 : Repair completed date file 1
-- 2023-07-01 to 2024-10-21 : Repair completed date file 2

SELECT *
FROM [RepairedSet SEV Report]
WHERE Job_Number = 'JB0017479'

SELECT *
FROM Z_Repairset_SEV
WHERE [Job Number] = 'JB0017479'


-- Question 4 :

SELECT 
	DISTINCT [ASC Code], [ASC Name], ZF_FLAG
FROM Z_Repairset_SEV_FULL
WHERE [ASC Code] IN ('ASC10292', 'ASC10400')


SELECT DISTINCT [Model Code]
FROM Z_Repairset_SEV_FULL
GROUP BY [Product Category]

HAVING COUNT(DISTINCT [Model Name]) > 1

SELECT [ASC Code], [ASC Name],[Warranty Type], COUNT(*) A
FROM Z_Repairset_SEV_FULL
where ZF_FLAG = 'NEW'
GROUP BY [ASC Code],[ASC Name], [Warranty Type]
ORDER BY A DESC


SELECT [ASC Code], [ASC Name], COUNT(*) A
FROM Z_Repairset_SEV_FULL
where ZF_FLAG = 'NEW'
GROUP BY [ASC Code],[ASC Name],
ORDER BY A DESC


SELECT 
	DISTINCT [Sony Needs To Pay]
FROM Z_Repairset_SEV_FULL
WHERE ZF_FLAG = 'NEW'
AND [Warranty Type] = 'OW'

------------ CHECK 
-- ASC10399A, ASC12007
-- CASE1
SELECT *
FROM DIVA_SEV_FY2023..RepairedSet_SEV_Report_20230701_to_20241021
WHERE [ASC_CODE] IN ('ASC10399A','ASC12007')

SELECT DISTINCT *
FROM DIVA_SEV_WARRANTY_JULY_21_JUNE_23..[RepairedSet SEV Report]
WHERE [ASC_CODE] IN ('ASC10399A','ASC12007')

-- CASE 2

SELECT DISTINCT *
FROM DIVA_SEV_FY2023..RepairedSet_SEV_Report_20230701_to_20241021
WHERE Sony_Needs_To_Pay IN
(
	'1',
	'AZSAKZ',
	'LCD TV',
	'No',
	'Yes'
)


SELECT *
FROM DIVA_SEV_WARRANTY_JULY_21_JUNE_23..[RepairedSet SEV Report]
WHERE Job_Number IN 
(

	SELECT DISTINCT Job_Number3
	FROM DIVA_SEV_FY2023..RepairedSet_SEV_Report_20230701_to_20241021
	WHERE Sony_Needs_To_Pay IN
	(
		'1',
		'AZSAKZ',
		'LCD TV',
		'No',
		'Yes'
	)
)



-- CASE 3

SELECT *
FROM DIVA_SEV_FY2023..RepairedSet_SEV_Report_20230701_to_20241021
WHERE Warehouse IS NULL
AND ASC_Name LIKE N'%B?C NINH%'


SELECT *
FROM DIVA_SEV_WARRANTY_JULY_21_JUNE_23..[RepairedSet SEV Report]
WHERE Job_Number IN 
(
	SELECT DISTINCT Job_Number
	FROM DIVA_SEV_FY2023..RepairedSet_SEV_Report_20230701_to_20241021
	WHERE Warehouse IS NULL
	AND ASC_Name LIKE N'%B?C NINH%'
)

-- CASE 4
SELECT *
FROM DIVA_SEV_WARRANTY_JULY_21_JUNE_23..[RepairedSet SEV Report]
WHERE Job_Number IN 
(

	SELECT DISTINCT Job_Number
	FROM DIVA_SEV_FY2023..RepairedSet_SEV_Report_20230701_to_20241021
	WHERE Serial_No LIKE '%+%'
)



WITH TABLE1 AS
(

	SELECT [ASC Code], COUNT(DISTINCT [Warranty Type]) A
	FROM Z_Repairset_SEV_FULL
	WHERE ZF_FLAG = 'OLD'
	GROUP BY [ASC Code]

),
 TABLE2 AS
(

	SELECT [ASC Code], COUNT(DISTINCT [Warranty Type]) B
	FROM Z_Repairset_SEV_FULL
	WHERE ZF_FLAG = 'NEW'
	GROUP BY [ASC Code]

)
SELECT *
FROM TABLE1 LEFT JOIN TABLE2 
	ON TABLE1.[ASC Code] = TABLE2.[ASC Code]
WHERE TABLE1.A <> TABLE2.B


SELECT CAST( [Sony Needs To Pay] AS float),ZF_FLAG
FROM Z_Repairset_SEV_FULL
WHERE [Warranty Type] = 'OW'
ORDER BY CAST( [Sony Needs To Pay] AS float) DESC 


SELECT *
FROM Z_Repairset_SEV_FULL
WHERE [Sony Needs To Pay] LIKE '%.%'

---- Change the appropriate data type for each column.


EXEC SP_REMOVE_TABLES 'B01_01_TT_WARRANTY_DATA' -- Remove table before store.

SELECT 
	[Country] ,  -- Country of ASC
	[Region] ,   -- Region of ASC
	[RegionName] , -- Region name
	[ASC Code] ,  -- ASC number (code)
	[ASC Name] ,  -- ASC name
	[ASC Code]+'-'+[ASC Name] AS ZF_ASC_CODE_NAME_COMBINE, -- Combine ASC code and ASC name together.
	[Job Number] , -- Job number
	CAST([Seq] as INT) as [Seq]  , -- Sequences, 1 Job number can have many sequences
	[Product Category] , -- Product category
	[Product Sub Category] , -- Product sub category
	[Product Category]+'-'+[Product Sub Category] AS ZF_PRODUCT_CATEGORY_SUB_COMBINE, -- Combine Product category and Product sub category together.
	[Model Code] , -- Model code of product
	[Model Name] , -- Model name
	[Model Code]+'-'+[Model Name] AS ZF_MODEL, -- Comnine Model code and Model name together.
	[Serial No] , -- Serial number 
	[Service Type] , -- Service Type
	[Transfer_flag] ,  
	[transfer_job_no] ,
	[Guarantee Code] ,
	[Customer Group] , -- Customer group : Dealer, Normal customer and Internal customer
	[CUSTOMER_NAME] , -- Customer name
	[EMAIL] , -- Email of customer
	[LINKMAN] , -- LINKMAN
	[PHONE] , -- Phone 
	[MOBIL] , -- Mobile phone
	[ADDRES] , -- Address
	[CITY] , -- City of customer
	[PROVINCE] , -- Province
	[CITY]+'-'+[PROVINCE] AS ZF_CITY_PROVINCE ,-- Comnine Model code and Model name together,
	[POST_CODE] ,-- Post code
	IIF(LEN([Purchased Date]) = 19,CONVERT(DATETIME, [Purchased Date], 102),CONVERT(DATETIME, [Purchased Date], 3)) as [Purchased Date],-- Convert datetime to Purchased Date column.
	[Warranty Type] , -- Warranty Type: There are 2 values: IW and OW: In Warranty and Out of Warranty
	[Warranty Category] , -- Warranty Category
	[Warranty Card No] , -- Warranty Card No
	[Warranty Card Type] ,-- Warranty Card Type
	[Technician] , -- Technician
    IIF(LEN([Reservation Create Date]) = 19,CONVERT(DATETIME, [Reservation Create Date], 102),CONVERT(DATETIME, [Reservation Create Date], 3)) as [Reservation Create Date],
    IIF(LEN([Job Create Date]) = 19,CONVERT(DATETIME, [Job Create Date], 102),CONVERT(DATETIME, [Job Create Date], 3)) as [Job Create Date],
    IIF(LEN([First Allocation Date]) = 19,CONVERT(DATETIME, [First Allocation Date], 102),CONVERT(DATETIME, [First Allocation Date], 3)) as [First Allocation Date],
    IIF(LEN([Begin Repair Date]) = 19,CONVERT(DATETIME, [Begin Repair Date], 102),CONVERT(DATETIME, [Begin Repair Date], 3)) as [Begin Repair Date],
    IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) as [Repair Completed Date],
    IIF(LEN([Repair Returned Date]) = 19,CONVERT(DATETIME, [Repair Returned Date], 102),CONVERT(DATETIME, [Repair Returned Date], 3)) as [Repair Returned Date],	
	[Part Code] , -- Part Code
	[Part Desc] , -- Part Description
	[Repair Qty] , -- Repair quantity.
	CAST([Part Unit Price] as float) as [Part Unit Price] ,  --Part Unit Price
	[PO NO] ,
    IIF(LEN([PO Create Date]) = 19,CONVERT(DATETIME, [PO Create Date], 102),CONVERT(DATETIME, [PO Create Date], 3)) as [PO Create Date],
    IIF(LEN([Shipped Date]) = 19,CONVERT(DATETIME, [Shipped Date], 102),CONVERT(DATETIME, [Shipped Date], 3)) as [Shipped Date],
    IIF(LEN([PARTS RECEIVED Date]) = 19,CONVERT(DATETIME, [PARTS RECEIVED Date], 102),CONVERT(DATETIME, [PARTS RECEIVED Date], 3)) as [PARTS RECEIVED Date],
	IIF( F.[Desc] IS NOT NULL,  CONCAT(A.[Symptom Code],' - ', F.[Desc]), A.[Symptom Code]) AS  [Symptom Code] , -- Get section description., 
	IIF( E.[Desc] IS NOT NULL,  CONCAT(A.[Section Code],' - ', E.[Desc]), A.[Section Code]) AS  [Section Code] , -- Get section description.
	IIF( C.[Desc] IS NOT NULL,  CONCAT(A.[Defect Code],' - ', C.[Desc]), A.[Defect Code]) AS  [Defect Code] , -- Get defect code description.
	IIF( D.[Desc] IS NOT NULL,  CONCAT(A.[Repair Code],' - ', D.[Desc]), A.[Repair Code]) AS  [Repair Code], -- Get repair code description.
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
	-- Create Calendar Year, Fiscal Year, Calendar month based on request from Jesper.
	YEAR(IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) ) AS ZF_CALENDAR_YEAR,
	MONTH(IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) ) AS ZF_CALENDAR_MONTH,
	CASE 
		WHEN IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) >= '2021-04-01' 
			AND IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) <= '2022-03-31' THEN 2021
		WHEN IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) >= '2022-04-01' 
			AND IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) <= '2023-03-31' THEN 2022
		WHEN IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) >= '2023-04-01' 
			AND IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) <= '2024-03-31' THEN 2023
		WHEN IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) >= '2024-04-01' 
			AND IIF(LEN([Repair Completed Date]) = 19,CONVERT(DATETIME, [Repair Completed Date], 102),CONVERT(DATETIME, [Repair Completed Date], 3)) <= '2025-03-31' THEN 2024


	END AS ZF_FISCAL_YEAR,		
	[Customer_Complaint] ,
	[Symptom_Confirmed_By_Technician] ,
	[IRIS_Line_Transfer_flag] ,
	[CCC_ID] ,
	[Assigned_by] ,
	IIF( B.[Desc] IS NOT NULL,  CONCAT(A.Condition_code,' - ', B.[Desc]), A.Condition_code) AS [Condition_code] , -- Get condition desc
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
	[Repair_Type],
	-- Get exchange rate value convert from vnd to usd
	G.ZF_LOCAL_CURRENCY,
	G.ZF_EXCHANGE,
	A.ZF_FLAG
INTO B01_01_TT_WARRANTY_DATA
FROM Z_Repairset_SEV_FULL A  -- Excel file name received from Jesper. It contains warranty data
-- Get mapping code desc base on AM_MAPPING
	LEFT JOIN AM_CONDITION_MAPPING B -- Get condition description.
		ON A.Condition_code = B.Condition_Code
	LEFT JOIN AM_DEFECT_CODE_MAPPING C -- Get defect description.
		ON A.[Defect Code] = C.Defect_Code
	LEFT JOIN AM_REPAIR_CODE_MAPPING D
		ON A.[Repair Code] = D.Repair_Code -- Get repair description
	LEFT JOIN AM_SECTION_CODE_MAPPING E -- Get section description.
		ON A.[Section Code] = E.Section_Code
	LEFT JOIN AM_SYMPTOM_CODE_MAPPING F -- Get symotom description
		ON A.[Symptom Code] = F.Symptom_Code
	LEFT JOIN AM_CURRENCY_MAPPING G -- Get exchange rate value convert from vnd to usd
		ON A.Country = G.ZF_COUNTRY
		 AND YEAR(IIF(LEN([LAST_STATUS_UPDATE_DATE]) = 19,CONVERT(DATETIME, [LAST_STATUS_UPDATE_DATE], 102),CONVERT(DATETIME, [LAST_STATUS_UPDATE_DATE], 3)) ) = G.ZF_YEAR

-- Step 2 /  Related to date bucket.
-- Based on request from Jesper Add columns to calculate date bucket.

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_TAT_BUCKETS NVARCHAR(30); -- TAT buckets with TAT mean Turnaround Time of warranty.
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_COMPLETED_REPAIR_RETURNED_DATE_BUCKETS NVARCHAR(30); -- Repair Completed Date and Repair Returned Date Buckets.
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_COMPLETED_LAST_UPDATE_DATE_BUCKETS NVARCHAR(30); -- Repair Completed Date and LAST_STATUS_UPDATE_DATE buckets.
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_PARTS_REQUEST_DATE_PART_ALL_DATE_BUCKETS NVARCHAR(30); -- PARTS_REQUEST_DATE and Parts Allocated Date Buckets.
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_JOB_CREATED_DATE_BEGIN_REP_DATE_BUCKETS NVARCHAR(30); -- Update value for Job Create Date and Begin Repair Date Buckets.
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_JOB_CREATED_DATE_LAST_STATUS_UPDATE_DATE_BUCKETS NVARCHAR(30); -- Update value for Job Create Date and LAST_STATUS_UPDATE_DATE Buckets.
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_BEGIN_REP_DATE_PARTS_REQUEST_DATE_BUCKETS NVARCHAR(30); -- Begin Repair Date and PARTS_REQUEST_DATE Buckets.
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_RESERVATION_DATE_BEGIN_REPAIR_DATE NVARCHAR(30); -- Reservation Create Date and Begin date repair Buckets.
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_BEGIN_REP_DATE_REPAIR_COMPLETED_DATE NVARCHAR(30); -- Begin date repair and Completed repair date Buckets.

-- Step 2.1 Update value for TAT bucket . TAT mean Turnaround Time of warranty.

UPDATE B01_01_TT_WARRANTY_DATA
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

-- Step 2.2  Update value for repair Completed Date and Repair Returned Date Buckets.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_REPAIR_COMPLETED_REPAIR_RETURNED_DATE_BUCKETS =

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

-- Step 2.3  Update value for repair Completed Date and LAST_STATUS_UPDATE_DATE Buckets.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_REPAIR_COMPLETED_LAST_UPDATE_DATE_BUCKETS =

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

-- Step 2.4  Update value for PARTS_REQUEST_DATE and Parts Allocated Date Buckets.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_PARTS_REQUEST_DATE_PART_ALL_DATE_BUCKETS =

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

-- Step 2.5  Update value for Job Create Date and Begin Repair Date Buckets.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_JOB_CREATED_DATE_BEGIN_REP_DATE_BUCKETS =

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

-- Step 2.6  Update value for Job Create Date and LAST_STATUS_UPDATE_DATE Buckets.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_JOB_CREATED_DATE_LAST_STATUS_UPDATE_DATE_BUCKETS =

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

-- Step 2.7  Update value for Begin Repair Date and PARTS_REQUEST_DATE Buckets.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_BEGIN_REP_DATE_PARTS_REQUEST_DATE_BUCKETS =

	CASE
		WHEN YEAR([Begin Repair Date]) = 1900 OR YEAR(PARTS_REQUEST_DATE) = 1900 THEN '01_The day is empty'
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


-- Step 2.8  Update value for Reservation Create Date and Begin date repair Buckets.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_RESERVATION_DATE_BEGIN_REPAIR_DATE =

	CASE
		WHEN YEAR([Reservation Create Date]) = 1900 OR YEAR([Begin Repair Date]) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Reservation Create Date], [Begin Repair Date])) > 365 THEN '10_>365days'
	END


-- Step 2.9  Update value for Begin date repair and Completed repair date Buckets.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_BEGIN_REP_DATE_REPAIR_COMPLETED_DATE =

	CASE
		WHEN YEAR([Begin Repair Date]) = 1900 OR YEAR([Repair Completed Date]) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Begin Repair Date], [Repair Completed Date])) > 365 THEN '10_>365days'
	END



-- Step 3 / The purpose of adding a new flag column is to detect strange Serial numbers of product in the warranty data.
-- MoreOver add serial number flag if lenght of serial number is 7 or 15. ( Normal lenght of serial number)
-- Step 3.1 Define strange Serial numbers
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_STRANGE_OF_SER_NO NVARCHAR(3); -- Strange Serial numbers 

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_STRANGE_OF_SER_NO = 'No'

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_STRANGE_OF_SER_NO = 'Yes'
WHERE 
(
	[Serial No] NOT LIKE  '%[a-zA-Z0-9]%' -- The Serial numbers  does not contain the numbers a to z or 0 to 9
	OR 	[Serial No] LIKE 'x%'   -- The Serial numbers start with x
	OR LEN(REPLACE([Serial No], LEFT([Serial No],1),'')) = 0  -- Serial numbers are identical series of numbers example : 1111111,222222 etc.
) 
AND [Serial No] <> '' -- Serial numbers not empty.

-- Step 3.2 The lenght of serial number not in 7 or 15

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_LEN_SERIAL_NUMBER_NOT_7_15_FLAG NVARCHAR(3); -- Lenght of serial number 7 or 15

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_LEN_SERIAL_NUMBER_NOT_7_15_FLAG = 'No'


UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_LEN_SERIAL_NUMBER_NOT_7_15_FLAG = 'Yes'
WHERE LEN([Serial No]) NOT IN (7,15)

-- Step 4 /  Request from Jesper need to add Filter "OW but SONY need to pay" = 'Y' means:Warranty type: OW and Repair fee type : Chargeable and Sony need to pay > 0

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_OW_SONY_NEED_PAY NVARCHAR(3);

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_OW_SONY_NEED_PAY = 'No'

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_OW_SONY_NEED_PAY = 'Yes'
WHERE  [Warranty Type] = 'OW' AND [Sony Needs To Pay] > 0


-- Step 5 / Objective: Analyze the total amount SONY needs to pay and the number of Job number following the 2 conditions below.

--1. Warranty Type = 'IW', Sony Needs To Pay > 0, Serial number not strange and not empty, Phone/Mobile not empty.
--2. With the same serial number, defect code, and phone/mobile then the days between the current begin repair date and the previous repair date are less than 90 days.

-- Step 5.1 Create table to store wanrranty data with conditon : Warranty Type = 'IW', Sony Needs To Pay > 0, Serial number not strange and not empty, Phone/Mobile not empty.
-- With the same serial number, the same defect code, the same customer calculates the distance between the current and previous repair dates.


EXEC SP_REMOVE_TABLES 'B01_02_TT_WARRANTY_DATA_RE_REPAIR' -- 

SELECT 

		ROW_NUMBER() OVER(PARTITION BY  CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL)) ORDER BY  [Begin Repair Date])  AS ZF_ROWID,
		LAG([Begin Repair Date]) OVER (PARTITION BY  CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL)) ORDER BY  [Begin Repair Date]) AS ZF_BEGIN_REPAIR_DATE_PREVI,
		DATEDIFF(DAY, LAG([Begin Repair Date]) OVER (PARTITION BY  CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL)) ORDER BY  [Begin Repair Date]) , [Begin Repair Date]) as ZF_BEGIN_REPAIR_DATE_MINUS_PREVI,
		*
INTO B01_02_TT_WARRANTY_DATA_RE_REPAIR
FROM B01_01_TT_WARRANTY_DATA
WHERE [Warranty Type] = 'IW' AND [Sony Needs To Pay] > 0 AND ZF_STRANGE_OF_SER_NO = 'No'  AND [Serial No] <> '' AND ISNULL(PHONE, MOBIL) <> ''
AND CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL)) IN  
	-- Warranty Type = 'IW', Sony Needs To Pay > 0, Serial number not strange and not empty, Phone/Mobile not empty.
	-- and have re-repair with COUNT(DISTINCT [Job Number]) > 1
	(

		SELECT 
			CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL))
		FROM B01_01_TT_WARRANTY_DATA
		WHERE [Warranty Type] = 'IW' AND [Sony Needs To Pay] > 0 AND ZF_STRANGE_OF_SER_NO = 'No' AND [Serial No] <> '' AND ISNULL(PHONE, MOBIL) <> ''
		GROUP BY [Defect Code], [Serial No], ISNULL(PHONE, MOBIL)
		HAVING COUNT(DISTINCT [Job Number]) > 1
	)
AND Seq = 1

-- Step 5.2  From result 5.1 Retrieve re-repair wanrraty data with day gap less than 90 days.
EXEC SP_REMOVE_TABLES 'B01_03_TT_WARRANTY_DATA_RE_REPAIR_DAY_GAP_LESS_90'

SELECT 
*
INTO B01_03_TT_WARRANTY_DATA_RE_REPAIR_DAY_GAP_LESS_90
FROM B01_02_TT_WARRANTY_DATA_RE_REPAIR 
WHERE ZF_BEGIN_REPAIR_DATE_MINUS_PREVI < 90
-- Retrieve warranties where the distance between the begin repair date and the previous begin repair date is 90 days.
UNION 
-- Then add warranty transactions immediately in front of it to display on Qliksense.
SELECT 
*
FROM B01_02_TT_WARRANTY_DATA_RE_REPAIR 
WHERE  CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL),(ZF_ROWID)) IN
(
	
	SELECT 
		CONCAT([Serial No],[Defect Code],ISNULL(PHONE, MOBIL),(ZF_ROWID-1))
	FROM B01_02_TT_WARRANTY_DATA_RE_REPAIR 
	WHERE ZF_BEGIN_REPAIR_DATE_MINUS_PREVI < 90
)


-- Step 5.2 Add the necessary columns to filter on qliksense

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_90_SONY_NEED_TO_PAY NVARCHAR(3);
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_90_PREVIOUS_DAY DATETIME;
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_90_PREVIOUS_DAY_DIFF NVARCHAR(3);


UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_REPAIR_90_SONY_NEED_TO_PAY = 'No'

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_REPAIR_90_SONY_NEED_TO_PAY = 'Yes'
FROM B01_01_TT_WARRANTY_DATA A 
JOIN  B01_03_TT_WARRANTY_DATA_RE_REPAIR_DAY_GAP_LESS_90 B ON 
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
WHERE B.ZF_BEGIN_REPAIR_DATE_MINUS_PREVI < 90


UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_REPAIR_90_PREVIOUS_DAY = B.ZF_BEGIN_REPAIR_DATE_PREVI,
ZF_REPAIR_90_PREVIOUS_DAY_DIFF = B.ZF_BEGIN_REPAIR_DATE_MINUS_PREVI
FROM B01_01_TT_WARRANTY_DATA A 
JOIN  B01_03_TT_WARRANTY_DATA_RE_REPAIR_DAY_GAP_LESS_90 B ON 
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
WHERE B.ZF_BEGIN_REPAIR_DATE_MINUS_PREVI < 90



-- Step 6 / Add customer compalaint analysis in qlilsense.
-- Step 6.1 Add Customer group vietnamese and Customer group English.

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_Customer_Complaint_Group_VN NVARCHAR(MAX); -- Customer group vietnamese
ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_Customer_Complaint_Group_EN NVARCHAR(MAX); -- Customer group english.

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_Customer_Complaint_Group_VN = 
CASE 

			WHEN 
				Customer_Complaint LIKE '%man hinh%' OR
				Customer_Complaint LIKE N'%màn hình%' OR
				Customer_Complaint LIKE N'%V Line %' OR 
				Customer_Complaint LIKE N'%No Display%' OR 
				Customer_Complaint LIKE N'%Không hình%' OR 
				Customer_Complaint LIKE N'%khong hinh%' OR 
				Customer_Complaint LIKE N'%Không lên hình%' OR 
				Customer_Complaint LIKE N'%Không lên hình%' OR 
				Customer_Complaint LIKE N'%H Line%' OR
				Customer_Complaint LIKE N'%Nháy 6 nháy%' OR
				Customer_Complaint LIKE N'%6%' OR
				Customer_Complaint LIKE N'%5%' OR
				Customer_Complaint LIKE N'%6 nháy%' THEN N'Màn hình'
			WHEN 
				Customer_Complaint LIKE N'%Hàng l?i  sai qui cách%' OR 
				Customer_Complaint LIKE N'%HÀNG L?I SAI QUY CÁCH%' OR 
				Customer_Complaint LIKE  N'%Hàng l?i  sai quy cách%' THEN N'Hàng l?i sai quy cách'	
			WHEN 
				Customer_Complaint LIKE '%khong nguon%' OR
				Customer_Complaint LIKE N'%không ngu?n%' OR
				Customer_Complaint LIKE N'%Không ho?t d?ng%' OR
				Customer_Complaint LIKE N'%khong hoat dong%' OR
				Customer_Complaint LIKE N'%KO hoat dong%' OR 
				Customer_Complaint LIKE N'%TIVI KHÔNG LÊN NGU?N%'	OR
				Customer_Complaint LIKE N'%Không vào di?n%'  OR
				Customer_Complaint LIKE N'%dien%'  OR
				Customer_Complaint LIKE N'%không lên ngu?n%'				
				THEN N'Tivi không ho?t d?ng ho?c không có ngu?n'		
			WHEN Customer_Complaint LIKE N'%Hàng mu?n tr? kho %' 				
				THEN N'Hàng mu?n tr? kho'
			WHEN Customer_Complaint LIKE N'%s?c không vào%'				
				THEN N'S?c'
			WHEN Customer_Complaint LIKE N'%Không nh?n khi?n%'			
				OR Customer_Complaint LIKE N'%dieu khien%'	
				OR Customer_Complaint LIKE N'%di?u khi?n%'	
				OR Customer_Complaint LIKE N'%remote%'
			THEN N'Ði?u khi?n'
			ELSE N'L?i khác'
			END ,

ZF_Customer_Complaint_Group_EN = 

CASE 

			WHEN 
				Customer_Complaint LIKE '%man hinh%' OR
				Customer_Complaint LIKE N'%màn hình%' OR
				Customer_Complaint LIKE N'%V Line %' OR 
				Customer_Complaint LIKE N'%No Display%' OR 
				Customer_Complaint LIKE N'%Không hình%' OR 
				Customer_Complaint LIKE N'%khong hinh%' OR 
				Customer_Complaint LIKE N'%Không lên hình%' OR 
				Customer_Complaint LIKE N'%Không lên hình%' OR 
				Customer_Complaint LIKE N'%H Line%' OR
				Customer_Complaint LIKE N'%Nháy 6 nháy%' OR
				Customer_Complaint LIKE N'%6%' OR
				Customer_Complaint LIKE N'%5%' OR
				Customer_Complaint LIKE N'%6 nháy%' THEN N'Screen'
			WHEN 
				Customer_Complaint LIKE N'%Hàng l?i  sai qui cách%' OR 
				Customer_Complaint LIKE N'%HÀNG L?I SAI QUY CÁCH%' OR 
				Customer_Complaint LIKE  N'%Hàng l?i  sai quy cách%' THEN N'Defective product, incorrect specifications'	
			WHEN 
				Customer_Complaint LIKE '%khong nguon%' OR
				Customer_Complaint LIKE N'%không ngu?n%' OR
				Customer_Complaint LIKE N'%Không ho?t d?ng%' OR
				Customer_Complaint LIKE N'%khong hoat dong%' OR
				Customer_Complaint LIKE N'%KO hoat dong%' OR 
				Customer_Complaint LIKE N'%TIVI KHÔNG LÊN NGU?N%'	OR
				Customer_Complaint LIKE N'%Không vào di?n%'  OR
				Customer_Complaint LIKE N'%dien%'  OR
				Customer_Complaint LIKE N'%không lên ngu?n%'				
				THEN N'TV does not work or has no power'		
			WHEN Customer_Complaint LIKE N'%Hàng mu?n tr? kho %' 				
				THEN N'Products borrowed and returned to warehouse'
			WHEN Customer_Complaint LIKE N'%s?c không vào%'				
				THEN N'Charging'
			WHEN Customer_Complaint LIKE N'%Không nh?n khi?n%'			
				OR Customer_Complaint LIKE N'%dieu khien%'	
				OR Customer_Complaint LIKE N'%di?u khi?n%'	
				OR Customer_Complaint LIKE N'%remote%'
			THEN N'Remote'
			ELSE N'Other error'
			END 

-- Step 6.2 Translate customer complaint to english.

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_Customer_Complaint_EN NVARCHAR(MAX);


UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_Customer_Complaint_EN = F3
FROM B01_01_TT_WARRANTY_DATA 
	INNER JOIN Sheet2$ 
	ON B01_01_TT_WARRANTY_DATA.[Job Number] = Sheet2$.[Job Number]
WHERE ZF_Customer_Complaint_EN IS NULL 		



SELECT *
FROM Sheet2$

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_Customer_Complaint_EN = AM_CUSTOMER_COMPLAINT.F3
FROM B01_01_TT_WARRANTY_DATA 
	INNER JOIN Sheet1$ AM_CUSTOMER_COMPLAINT
	ON LTRIM(RTRIM(B01_01_TT_WARRANTY_DATA.Customer_Complaint)) COLLATE SQL_Latin1_General_CP1_CI_AS 
	= LTRIM(RTRIM(AM_CUSTOMER_COMPLAINT.[Customer_Complaint VN])) COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE ZF_Customer_Complaint_EN IS NULL 	




SELECT *

FROM B01_01_TT_WARRANTY_DATA 
    INNER JOIN Sheet1$ AM_CUSTOMER_COMPLAINT
    ON REPLACE(LTRIM(RTRIM(B01_01_TT_WARRANTY_DATA.Customer_Complaint)), CHAR(13), '') COLLATE SQL_Latin1_General_CP1_CI_AS 
       = REPLACE(LTRIM(RTRIM(AM_CUSTOMER_COMPLAINT.[Customer_Complaint VN])), CHAR(13), '') COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE ZF_Customer_Complaint_EN IS NULL;




SELECT *
FROM Sheet1$
WHERE [Customer_Complaint VN]  COLLATE SQL_Latin1_General_CP1_CI_AS =  N'TV t? t?t b?t ngu?n'

SELECT DISTINCT Customer_Complaint
FROM B01_01_TT_WARRANTY_DATA
WHERE ZF_Customer_Complaint_EN IS NULL
AND ZF_FLAG = 'NEW'

SELECT *
FROM Sheet1$
WHERE [Customer_Complaint VN] IN
(
	SELECT DISTINCT Customer_Complaint, [Job Number]
	FROM B01_01_TT_WARRANTY_DATA
	WHERE ZF_Customer_Complaint_EN IS NULL
	AND ZF_FLAG = 'NEW'
	AND Customer_Complaint IS NOT NULL
)


SELECT Customer_Complaint,*
FROM B01_01_TT_WARRANTY_DATA
WHERE Customer_Complaint COLLATE SQL_Latin1_General_CP1_CI_AS =  N'TV t? t?t b?t ngu?n'

SELECT Customer_Complaint,*
FROM B01_01_TT_WARRANTY_DATA
WHERE [Job Number] = 'JC0054156'





DROP TABLE Sheet2$
SELECT *, REPLACE([Customer_Complaint VN],' ','')
FROM AM_CUSTOMER_COMPLAINT
WHERE [Customer_Complaint VN] = N'  TV t? t?t b?t ngu?n'

TVt?t?tb?tngu?n
TVt?t?tb?tngu?n
SELECT Customer_Complaint,REPLACE(Customer_Complaint,' ',''),*
FROM B01_01_TT_WARRANTY_DATA
WHERE Customer_Complaint = N'TV t? t?t b?t ngu?n'


SELECT DISTINCT Customer_Complaint

FROM B01_01_TT_WARRANTY_DATA
WHERE ZF_Customer_Complaint_EN IS NULL

-- Restore table load into Qliksense and delete TT table
EXEC SP_REMOVE_TABLES 'B01_04_IT_WARRANTY_FINAL_DATA'
SELECT 
*
INTO B01_04_IT_WARRANTY_FINAL_DATA
FROM B01_01_TT_WARRANTY_DATA


--/*Drop temporary tables*/
EXEC SP_REMOVE_TABLES '%_TT_%'

------------------------------------------------------------------------AVG COGS FOR PRODUCT--------------------------------------------------------

-- Step 1 /  Get Product amount for COGS

DROP TABLE IF EXISTS B04_05_TT_GL_COGS_PRODUCT
	SELECT 
		DISTINCT 
		B04_GL_ACDOCA_BELNR, 
		B04_GL_ACDOCA_GJAHR,
		B04_GL_ACDOCA_RBUKRS, 
		B04_GL_ACDOCA_MATNR, 
		SUM(B04_GL_ZF_ACDOCA_HSL_S_CUC) AS ZF_ACDOCA_HSL_S_CUC_TOTAL
	INTO B04_05_TT_GL_COGS_PRODUCT	
	FROM DIVA_SEV_FY2023..B04_08_IT_FIN_GL 
	WHERE EXISTS  -- Step 1 / From GL cube get all Material numbers in Warranty data.
	(
		SELECT TOP 1 1 
		FROM DIVA_SEV_WARRANTY_JULY_21_JUNE_23..B01_04_IT_WARRANTY_FINAL_DATA
		WHERE [Model Code] = DBO.REMOVE_LEADING_ZEROES(B04_GL_ACDOCA_MATNR)

	) -- Step 2 / From GL cube : Get all JE number related to AR.
	AND CONCAT(B04_GL_ACDOCA_BELNR, B04_GL_ACDOCA_GJAHR, B04_GL_ACDOCA_RBUKRS) IN 
	(
		  SELECT DISTINCT CONCAT(B04_GL_ACDOCA_BELNR, B04_GL_ACDOCA_GJAHR, B04_GL_ACDOCA_RBUKRS)
			FROM DIVA_SEV_FY2023..B04_08_IT_FIN_GL 
		  WHERE B04_GL_ACDOCA_KOART = 'D'
	)
	AND B04_GL_SKAT_TXT20 LIKE '%COGS%'
	GROUP BY 	B04_GL_ACDOCA_BELNR, 
		B04_GL_ACDOCA_GJAHR,
		B04_GL_ACDOCA_RBUKRS, 
		B04_GL_ACDOCA_MATNR

-- Step 2 / Get Quantity for product.
-- 85861
-- 85861

DROP TABLE IF EXISTS B04_06_TT_GL_QUANTITY_PRODUCT
SELECT 
		DISTINCT 
		B04_GL_ACDOCA_BELNR, 
		B04_GL_ACDOCA_GJAHR,
		B04_GL_ACDOCA_RBUKRS, 
		B04_GL_ACDOCA_MATNR, 
		ABS(SUM(ACDOCA_MSL))  AS ZF_ABS_ACDOCA_WSL_TOTAL
	INTO B04_06_TT_GL_QUANTITY_PRODUCT	
	FROM DIVA_SEV_FY2023..B04_08_IT_FIN_GL 
		INNER JOIN DIVA_SEV_FY2023..B00_ACDOCA
		ON ACDOCA_BELNR = B04_GL_ACDOCA_BELNR 
		AND ACDOCA_GJAHR = B04_GL_ACDOCA_GJAHR
		AND ACDOCA_RBUKRS = B04_GL_ACDOCA_RBUKRS
		AND ACDOCA_DOCLN = B04_GL_ACDOCA_DOCLN
	WHERE EXISTS  -- Step 1 / From GL cube get all Material numbers in Warranty data.
	(
		SELECT TOP 1 1 
		FROM DIVA_SEV_WARRANTY_JULY_21_JUNE_23..B01_04_IT_WARRANTY_FINAL_DATA
		WHERE [Model Code] = DBO.REMOVE_LEADING_ZEROES(B04_GL_ACDOCA_MATNR)

	) -- Step 2 / From GL cube : Get all JE number related to AR.
	AND CONCAT(B04_GL_ACDOCA_BELNR, B04_GL_ACDOCA_GJAHR, B04_GL_ACDOCA_RBUKRS) IN 
	(
		  SELECT DISTINCT CONCAT(B04_GL_ACDOCA_BELNR, B04_GL_ACDOCA_GJAHR, B04_GL_ACDOCA_RBUKRS)
			FROM DIVA_SEV_FY2023..B04_08_IT_FIN_GL 
		  WHERE B04_GL_ACDOCA_KOART = 'D'
	)
	AND CONCAT(B04_GL_ACDOCA_BELNR, B04_GL_ACDOCA_GJAHR, B04_GL_ACDOCA_RBUKRS) IN 
	(
		  SELECT DISTINCT CONCAT(B04_GL_ACDOCA_BELNR, B04_GL_ACDOCA_GJAHR, B04_GL_ACDOCA_RBUKRS)
			FROM DIVA_SEV_FY2023..B04_08_IT_FIN_GL 
		  WHERE B04_GL_SKAT_TXT20 LIKE '%COGS%'
	) 
	AND (B04_GL_SKAT_TXT20 LIKE '%Gross%' OR B04_GL_SKAT_TXT20 LIKE '%M&FG%')
	GROUP BY B04_GL_ACDOCA_BELNR, 
		B04_GL_ACDOCA_GJAHR,
		B04_GL_ACDOCA_RBUKRS, 
		B04_GL_ACDOCA_MATNR

-- Step 3/ Link step 1 and step2 based on JE and MATNR
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_AVG_COGS_PRODUCT FLOAT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_AVG_COGS_PRODUCT = 0

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_AVG_COGS_PRODUCT = A.ZF_AVG_COGS_PRODUCT
FROM B01_04_IT_WARRANTY_FINAL_DATA 
	INNER JOIN 
	(
	SELECT 
		DISTINCT 
			DBO.REMOVE_LEADING_ZEROES(A.B04_GL_ACDOCA_MATNR) AS ZF_ACDOCA_MATNR_REMOVE_LEADING_ZEROS,
			ROUND(AVG(A.ZF_ACDOCA_HSL_S_CUC_TOTAL / B.ZF_ABS_ACDOCA_WSL_TOTAL),2) AS ZF_AVG_COGS_PRODUCT
	FROM B04_05_TT_GL_COGS_PRODUCT A
		INNER JOIN B04_06_TT_GL_QUANTITY_PRODUCT B
			ON A.B04_GL_ACDOCA_BELNR = B.B04_GL_ACDOCA_BELNR
			AND A.B04_GL_ACDOCA_GJAHR = B.B04_GL_ACDOCA_GJAHR
			AND A.B04_GL_ACDOCA_RBUKRS = B.B04_GL_ACDOCA_RBUKRS
			AND A.B04_GL_ACDOCA_MATNR = B.B04_GL_ACDOCA_MATNR

	GROUP BY DBO.REMOVE_LEADING_ZEROES(A.B04_GL_ACDOCA_MATNR)
	) AS A 
	ON [Model Code] = ZF_ACDOCA_MATNR_REMOVE_LEADING_ZEROS
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_TOTAL_COST_GREATER_AVG_COGS_FLAG NVARCHAR(3)
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_SONY_PAID_GREATER_AVG_COGS_FLAG NVARCHAR(3)

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA DROP COLUMN ZF_SONY_PAID_GREATER_AVG_COGS_FLAG, ZF_TOTAL_COST_GREATER_AVG_COGS_FLAG

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_COST_GREATER_AVG_COGS_FLAG = 'No', ZF_SONY_PAID_GREATER_AVG_COGS_FLAG = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_COST_GREATER_AVG_COGS_FLAG = 'Yes'
WHERE [Total Amount Of Account Payable] * ZF_EXCHANGE - ZF_AVG_COGS_PRODUCT > 50
AND ZF_AVG_COGS_PRODUCT > 0 


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_SONY_PAID_GREATER_AVG_COGS_FLAG = 'Yes'
WHERE [Sony Needs To Pay] * ZF_EXCHANGE - ZF_AVG_COGS_PRODUCT > 50
AND ZF_AVG_COGS_PRODUCT > 0 
*/
GO
