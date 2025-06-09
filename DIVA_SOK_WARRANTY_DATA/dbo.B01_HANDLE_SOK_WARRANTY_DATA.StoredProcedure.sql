USE [DIVA_SOK_WARRANTY_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROC [dbo].[B01_HANDLE_SOK_WARRANTY_DATA]

AS

-- Step 1 / Append the data together.
DROP TABLE IF EXISTS B01_01_TT_SOK_WARRANTY

SELECT 
	[??] AS [ASC Code],
	[????] AS [Receipt number], 
	[???] AS [Model Name],
	[?????] AS [Serial No],
	[?????] AS [In-Warranty (IW) part fee],
	[?????] AS [In-Warranty (IW) labor],
	[?????] AS [Out-Warranty (OW) part  fee],
	[?????] AS [Out-Warranty (OW) labor fee],
	CAST( [????] AS datetime) AS [Receipt date from customer],
	CAST( [??????]  AS datetime) AS [Repair Completed Date],
	CAST( [????]  AS datetime) AS [Shipping to customer date],
	CAST( [????]  AS datetime) AS [Purchased Date],
	CAST( [?????]  AS datetime) AS [Warranty Expiry date],
	[Warrnaty] AS [Warranty classification],
	'1 CSNET Reapir Data ( 2023-04~ 2025-03 ) (PS)' AS ZF_SOURCE
INTO B01_01_TT_SOK_WARRANTY
FROM [1 CSNET Reapir Data ( 2023-04~ 2025-03 ) (PS)]
UNION
SELECT 
	[??] AS [ASC Code],
	[????] AS [Receipt number], 
	[???] AS [Model Name],
	[?????] AS [Serial No],
	[?????] AS [In-Warranty (IW) part fee],
	[?????] AS [In-Warranty (IW) labor],
	[?????] AS [Out-Warranty (OW) part  fee],
	[?????] AS [Out-Warranty (OW) labor fee],
	CAST( [????] AS datetime) AS [Receipt date from customer],
	CAST( [??????]  AS datetime) AS [Repair Completed Date],
	CAST( [????]  AS datetime) AS [Shipping to customer date],
	CAST( [????]  AS datetime) AS [Purchased Date],
	CAST( [?????]  AS datetime) AS [Warranty Expiry date],
	???? AS [Warranty classification],
	'1. Complete Repairs data from CSNET for the audit period (Updated)_R1 (CP)' AS ZF_SOURCE
FROM [1].[ Complete Repairs data from CSNET for the audit period (Updated)_R1 (CP)]


-- Step 2 / Check primary key : [Receipt number], [Serial No], [Model Name], [ASC Code] : unique


SELECT 
	 [Receipt number], [Serial No], [Model Name],[ASC Code]

FROM B01_01_TT_SOK_WARRANTY
GROUP BY [Receipt number], [Serial No], [Model Name], [ASC Code]
HAVING COUNT(*) > 1

-- Step 3 / Check Consumer Product (CP) ASC List table 

-- Step 3.1 Add brand into SOK data

--ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_SONY_NOT_SONY_FLAG NVARCHAR(100)

--UPDATE B01_01_TT_SOK_WARRANTY
--SET ZF_SONY_NOT_SONY_FLAG = 'No Sony only'


--UPDATE A
--SET ZF_SONY_NOT_SONY_FLAG = B.BRAND
--FROM B01_01_TT_SOK_WARRANTY A
--	INNER JOIN AM_BRAND_MAPPING B 
--		ON A.[ASC Code] = B.????

-- Step 4/ Create AM exchange rate 

SELECT 
	2023 ZF_YEAR, CAST(1 AS float) / CAST(1305.979  AS FLOAT) AS ZF_EXCHANGE_RATE, 'https://www.exchangerates.org.uk/USD-KRW-spot-exchange-rates-history-2023.html' AS ZF_LINK
INTO AM_EXCHANGE_RATE
UNION
SELECT 
	2024 ZF_YEAR, CAST(1 AS float) / CAST(1363.5693  AS FLOAT) AS ZF_EXCHANGE_RATE, 'https://www.exchangerates.org.uk/USD-KRW-spot-exchange-rates-history-2024.html' AS ZF_LINK
UNION
SELECT 
	2025 ZF_YEAR, CAST(1 AS float) / CAST(1452.9004  AS FLOAT) AS ZF_EXCHANGE_RATE,  'https://www.exchangerates.org.uk/USD-KRW-spot-exchange-rates-history-2025.html' AS ZF_LINK


ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_EXCHANGE FLOAT

-- Add exchange rate for korean to USD

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_EXCHANGE = B.ZF_EXCHANGE_RATE
FROM B01_01_TT_SOK_WARRANTY A
	INNER JOIN AM_EXCHANGE_RATE B 
		ON YEAR([Repair Completed Date]) = B.ZF_YEAR
		                                 

-- Step 5 / Add main key columns 

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_MAIN_COLUMN_KEY NVARCHAR(1000)


UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_MAIN_COLUMN_KEY = CONCAT( [Receipt number], [Serial No], [Model Name], [ASC Code] )


-- Step 6 / Add Sony needs to pay and Customer needs to pay.
-- ASC no need to pay
-- Sony needs to pay = IW larbor fee and part fee 
-- Customer need to pay = OW larbor + OW part fee

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_SONY_NEED_TO_PAY MONEY

-- Step 6.1 Update for Sony need to pay

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_SONY_NEED_TO_PAY = [In-Warranty (IW) labor] + [In-Warranty (IW) part fee]

-- Check warranty type
-- International Warranty : Customer need to pay

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_SONY_NEED_TO_PAY = 0
WHERE [Warranty classification] = 'International Warranty'

-- Step 6.2 Update for Customer pay

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_CUSTOMER_PAY MONEY

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_CUSTOMER_PAY = [Out-Warranty (OW) labor fee] + [Out-Warranty (OW) part  fee]

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_CUSTOMER_PAY =  [In-Warranty (IW) labor] + [In-Warranty (IW) part fee]
WHERE [Warranty classification] = 'International Warranty'


-- Step 7 / Add Calendar year and Fiscal year .

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_CALENDAR_YEAR INT

-- Step 7.1 Add calendar year

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_CALENDAR_YEAR = YEAR([Repair Completed Date])

-- Step 7.2 Add fiscal year 

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_FISCAL_YEAR INT

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_FISCAL_YEAR =

	CASE 
		WHEN CAST ([Repair Completed Date] AS DATE) BETWEEN  '2023-04-01' AND '2024-03-31' THEN 2023
		WHEN CAST ([Repair Completed Date] AS DATE) BETWEEN  '2024-04-01' AND '2025-03-31' THEN 2024
		ELSE 2025
	END 


-- Step 8 /  Add Consumer or Professional  flag.

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_CONSUMER_PROFESSIONAL_FLAG NVARCHAR(100)

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_CONSUMER_PROFESSIONAL_FLAG = 'Not found'

-- Update cosumer and Professional flag

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_CONSUMER_PROFESSIONAL_FLAG = B.FLAG
FROM B01_01_TT_SOK_WARRANTY A
	INNER JOIN  AM_MAPPING_PS_CP B 
		ON A.[ASC Code] = B.[center code]



-- Step 9 / Add name of ASC code into Warranty data.

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_ASC_NAME NVARCHAR(1000)


UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_ASC_NAME = B.[Company Name]
FROM B01_01_TT_SOK_WARRANTY A
	INNER JOIN  AM_MAPPING_PS_CP B 
		ON A.[ASC Code] = B.[center code]
		

-- Step 10 / Combine ASC code and ASC name in qlik

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_ASC_CODE_NAME NVARCHAR(1000)

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_ASC_CODE_NAME = 
CASE 
	WHEN ZF_ASC_NAME IS NULL THEN [ASC Code]
	ELSE CONCAT([ASC Code],' - ', ZF_ASC_NAME)

END

-- Step 11 / Add filter Warranty type = OW then Sony need to pay > 0

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_SONY_PAID_OW_FLAG NVARCHAR(3)

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_SONY_PAID_OW_FLAG = 'No'

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_SONY_PAID_OW_FLAG = 'Yes'
WHERE [Warranty classification] = 'OW'
AND ZF_SONY_NEED_TO_PAY > 0  


-- Step 12 / Update purchase date is blanbk when purhcase date is null

UPDATE B01_01_TT_SOK_WARRANTY
SET [Purchased Date] = '1900-01-01'
WHERE [Purchased Date] IS NULL


UPDATE B01_01_TT_SOK_WARRANTY
SET [Warranty Expiry date] = '1900-01-01'
WHERE [Warranty Expiry date] IS NULL


-- Step 12 / Check [Receipt date from customer] AND [Warranty Expiry date]

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_RECEIPT_BEFORE_0_2_DAY_EXPIRY_DATE NVARCHAR(3)

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_RECEIPT_BEFORE_0_2_DAY_EXPIRY_DATE = 'No'

-- Update if Receipt date from customer before 0-1-2 days with Warranty Expiry date

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_RECEIPT_BEFORE_0_2_DAY_EXPIRY_DATE = 'Yes'
WHERE DATEDIFF(DAY, CAST([Receipt date from customer] AS DATE), CAST([Warranty Expiry date] AS DATE)) IN (0,1,2)
AND YEAR([Receipt date from customer]) <> 1900
AND YEAR([Warranty Expiry date]) <> 1900
AND ZF_SONY_NEED_TO_PAY > 0 


-- Step 13 / Check [Receipt date from customer] AND [Warranty Expiry date]

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_RECEIPT_AFTER_EXPIRY_DATE NVARCHAR(3)

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_RECEIPT_AFTER_EXPIRY_DATE = 'No'

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_RECEIPT_AFTER_EXPIRY_DATE = 'Yes'
WHERE DATEDIFF(DAY, CAST([Warranty Expiry date] AS DATE), CAST([Receipt date from customer] AS DATE)) > 0
AND YEAR([Receipt date from customer]) <> 1900
AND YEAR([Warranty Expiry date]) <> 1900
AND ZF_SONY_NEED_TO_PAY > 0 


------------------------------------------------------------------------------- 2025-04-21----------------------------------------------------------------------------
-- Get detail table from Yeanchoo for Part code

-- Step 14 / Related to part code and customer complain
--  Complete Repairs data from CSNET for the audit period (Updated)_FY23 (CP)
--  Complete Repairs data from CSNET for the audit period (Updated)_FY24 (CP)
--  CSNET Reapir Data ( 2023-04~ 2025-03 ) (Updated) (PS)

-- Step 14.1 Union all excel files.

DROP TABLE IF EXISTS B02_01_TT_SOK_DETAIL_TABLE
SELECT *,
	'Complete Repairs data from CSNET for the audit period (Updated)_FY23 (CP)' AS ZF_DETAIL_FLAG
INTO B02_01_TT_SOK_DETAIL_TABLE
FROM CP_DETAIL1 
UNION ALL
SELECT *,
	'Complete Repairs data from CSNET for the audit period (Updated)_FY24 (CP)'
FROM CP_DETAIL2
UNION  ALL
SELECT *,
'CSNET Reapir Data ( 2023-04~ 2025-03 ) (Updated) (PS)'
FROM PS_DETAIL


ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE ADD ZF_MAIN_KEY_COLUMNS NVARCHAR(1000)


UPDATE B02_01_TT_SOK_DETAIL_TABLE
SET ZF_MAIN_KEY_COLUMNS = CONCAT(

	
CAST( [Center Code] AS NVARCHAR(1000)),
	CAST( [Reception No] AS NVARCHAR(1000)),
	CAST( [Customer Group 1] AS NVARCHAR(1000)),
	CAST( [Customer Group 2] AS NVARCHAR(1000)),
	CAST( [Transfer job No] AS NVARCHAR(1000)),
	CAST( [MODEL_NAME] AS NVARCHAR(1000)),
	CAST( [Serial Number] AS NVARCHAR(1000)),
	CAST( [Symptom code ] AS NVARCHAR(1000)),
	CAST( [Reapir Code] AS NVARCHAR(1000)),
	CAST( [Customer Complaint ] AS NVARCHAR(1000)),
	CAST( [Repair Action/Technician Remarks ] AS NVARCHAR(1000)),
	CAST( [Parts No] AS NVARCHAR(1000)),
	CAST( [Parts description ] AS NVARCHAR(1000)),
	CAST( [Qty] AS NVARCHAR(1000)),
	CAST( [Free Parts] AS NVARCHAR(1000)),
	CAST( [Free Tech] AS NVARCHAR(1000)),
	CAST( [Charge Parts] AS NVARCHAR(1000)),
	CAST( [Charge Tech] AS NVARCHAR(1000)),
	CAST( [IN DATE] AS NVARCHAR(1000)),
	CAST( [Finish DATE] AS NVARCHAR(1000)),
	CAST( [OUT DATE] AS NVARCHAR(1000)),
	CAST( [Warranty Out DATE] AS NVARCHAR(1000)),
	CAST( [Warrnty] AS NVARCHAR(1000) ))


ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE ADD ZF_FLAG_DUP NVARCHAR(3)

UPDATE B02_01_TT_SOK_DETAIL_TABLE
SET ZF_FLAG_DUP = 'Yes'
WHERE ZF_MAIN_KEY_COLUMNS IN (
SELECT ZF_MAIN_KEY_COLUMNS
FROM B02_01_TT_SOK_DETAIL_TABLE
GROUP BY ZF_MAIN_KEY_COLUMNS
HAVING COUNT(*) > 1
)


--- Step 14.2 Create table without duplicate 


DROP TABLE IF EXISTS B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SELECT *,
	'Complete Repairs data from CSNET for the audit period (Updated)_FY23 (CP)' AS ZF_DETAIL_FLAG
INTO B02_01_TT_SOK_DETAIL_TABLE_NO_DUP          
FROM CP_DETAIL1 
UNION 
SELECT *,
	'Complete Repairs data from CSNET for the audit period (Updated)_FY24 (CP)'
FROM CP_DETAIL2
UNION  
SELECT *,
'CSNET Reapir Data ( 2023-04~ 2025-03 ) (Updated) (PS)'
FROM PS_DETAIL

-- Step 14.3 add Main key column

ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_MAIN_COLUMN_KEY NVARCHAR(1000)


--UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
--SET ZF_MAIN_COLUMN_KEY = CONCAT( [Reception No], [Serial Number], [MODEL_NAME], [Center Code] )


--SELECT *
--FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
--WHERE ZF_MAIN_COLUMN_KEY NOT IN 
--(
--	SELECT DISTINCT ZF_MAIN_COLUMN_KEY
--	FROM B01_01_TT_SOK_WARRANTY

--)

-- 14.4 Add column to show Main key column not exists in warranty table.

ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_MAIN_KEY_NOT_FOUND_WARRANTY NVARCHAR(3)

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_MAIN_KEY_NOT_FOUND_WARRANTY = 'No'

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_MAIN_KEY_NOT_FOUND_WARRANTY = 'Yes'
WHERE NOT EXISTS 
(

	SELECT TOP 1 1 
	FROM B01_01_TT_SOK_WARRANTY
	WHERE B01_01_TT_SOK_WARRANTY.ZF_MAIN_COLUMN_KEY = B02_01_TT_SOK_DETAIL_TABLE_NO_DUP.ZF_MAIN_COLUMN_KEY_JOIN_DM

)



------------------------------------------------------------------------ QUESTION FOR YEANCHOO ----------------------------------------------------------

-- 1 / Duplicate in Part code excel file

SELECT *
FROM B02_01_TT_SOK_DETAIL_TABLE
WHERE ZF_FLAG_DUP = 'YES'



SELECT *
FROM B02_01_TT_SOK_DETAIL_TABLE
WHERE [CENTER CODE] = 'A6'
AND [Reception No] = '24020003'
AND ZF_FLAG_DUP = 'Yes'

--  2 /Complete Repairs data from CSNET for the audit period (Updated)_FY23 (CP) : Warranty column




-- 3/  B02_01_TT_SOK_DETAIL_TABLE Duplicate value in Complete Repairs data from CSNET for the audit period (Updated)_FY23 (CP)
-- Complete Repairs data from CSNET for the audit period (Updated)_FY24 (CP)
-- CSNET Reapir Data ( 2023-04~ 2025-03 ) (Updated) (PS)

SELECT 
DISTINCT [Parts No]
FROM B02_01_TT_SOK_DETAIL_TABLE
WHERE NOT EXISTS 
(

	SELECT TOP 1 1 
	FROM [Parts Master_202503]
	WHERE 
		[Parts No] = [Material_Number]
)

------------------------------------------------------------- Link part code with Part code master then update for part code detail table ------------------------------------------------------------
-- Step 15/ Add COGS, FOB unit price and Dealer price and retail IW and retail OW


-- Step 15.1 Add ZF_COGS value

ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_COGS FLOAT

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_COGS = CAST(REPLACE(COGS, ',','') AS float)
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP A 
	INNER JOIN [Parts Master_202503_2] B 
		ON A.[Parts No] = B.Material_Number
WHERE A.[Parts No] IS NOT NULL

-- Step 15.2 Add ZF_FOB unit price

ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_FOB_Unit_Price FLOAT

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_FOB_Unit_Price = CAST(REPLACE([FOB ??], ',','') AS float)
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP A 
	INNER JOIN [Parts Master_202503_2] B 
		ON A.[Parts No] = B.Material_Number
WHERE A.[Parts No] IS NOT NULL

-- Step 15.3 Add Dealer price 

ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_Dealer_Price FLOAT

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_Dealer_Price = CAST(REPLACE([Dealer Price], ',','') AS float)
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP A 
	INNER JOIN [Parts Master_202503_2] B 
		ON A.[Parts No] = B.Material_Number
WHERE A.[Parts No] IS NOT NULL

-- Step 15.4 Add retail IW 

ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_Retail_I_W FLOAT

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_Retail_I_W = CAST(REPLACE([Retail I/W], ',','') AS float)
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP A 
	INNER JOIN [Parts Master_202503_2] B 
		ON A.[Parts No] = B.Material_Number
WHERE A.[Parts No] IS NOT NULL

-- Step 15.4 Add retail OW 


ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_Retail_O_W FLOAT

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_Retail_O_W = CAST(REPLACE([Retail O/W], ',','') AS float)
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP A 
	INNER JOIN [Parts Master_202503_2] B 
		ON A.[Parts No] = B.Material_Number
WHERE A.[Parts No] IS NOT NULL

------------------------------------------------------------------- 2025-04-24 -------------------------------------------------------------------------------------

-- Update price for part code : A5016707D

SELECT *
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE [Parts No] = 'A5016707A'

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_COGS = 56560,

	ZF_Dealer_Price = 51004 ,
	ZF_Retail_I_W = 67787,
	ZF_Retail_O_W = 67787 
WHERE [Parts No] = 'A5016707D'


---------------------------------------------------------------------- 2025-04-25 ----------------------------------------------------------------------------------------
-- Step 16 / Add Retail IW * qty * 1.1 higher IW part fee Sony need to pays.


ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_HIGH_PART_FEE_FLAG NVARCHAR(3);
UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_HIGH_PART_FEE_FLAG = 'No'

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_HIGH_PART_FEE_FLAG = 'Yes'
FROM B01_01_TT_SOK_WARRANTY
INNER JOIN (

			SELECT DISTINCT 
				ZF_MAIN_COLUMN_KEY_JOIN_DM,
				SUM(ZF_Retail_I_W * Qty *ZF_EXCHANGE_PART_CODE ) AS ZF_TOTAL_RETAIL_IW_USD
			FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
			WHERE [Free Parts] IS NOT NULL
			AND ZF_Retail_I_W IS NOT NULL
			GROUP BY ZF_MAIN_COLUMN_KEY_JOIN_DM
       
    
) C
ON ZF_MAIN_COLUMN_KEY =  ZF_MAIN_COLUMN_KEY_JOIN_DM
WHERE  [In-Warranty (IW) part fee] * ZF_EXCHANGE > ZF_TOTAL_RETAIL_IW_USD * 1.1
AND ([In-Warranty (IW) part fee] * ZF_EXCHANGE)  -  (ZF_TOTAL_RETAIL_IW_USD * 1.1) >= 2


-- Step 17 / Create test for same Job but Sony and customer need to pay Part fee.

ALTER TABLE B01_01_TT_SOK_WARRANTY ADD ZF_SONY_CUSTOMER_PAY_PART_CODE NVARCHAR(3)

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_SONY_CUSTOMER_PAY_PART_CODE = 'No'

UPDATE B01_01_TT_SOK_WARRANTY
SET ZF_SONY_CUSTOMER_PAY_PART_CODE = 'Yes'
WHERE [Serial No] IS NOT NULL
AND [Model Name] IS NOT NULL
AND [In-Warranty (IW) part fee] > 0
AND [Out-Warranty (OW) part  fee] > 0
AND [Warranty classification] IN ('IW','OW')

---

ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_SONY_CUSTOMER_PAY_PART_CODE_TABLE NVARCHAR(3)


UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_SONY_CUSTOMER_PAY_PART_CODE_TABLE = 'No'


UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_SONY_CUSTOMER_PAY_PART_CODE_TABLE = 'Yes'
WHERE ZF_MAIN_COLUMN_KEY_JOIN_DM IN
(
	SELECT 
		DISTINCT ZF_MAIN_COLUMN_KEY
	FROM B01_01_TT_SOK_WARRANTY
	WHERE ZF_SONY_CUSTOMER_PAY_PART_CODE = 'Yes'

)






SELECT
	[Serial Number],
	MODEL_NAME,
	[Reception No],
	[Parts No],
	ZF_Retail_I_W,
	Qty,
	ZF_Retail_I_W * QTY * 1.09 AS [ZF_Retail_I_W * QTY * 1.09],
	*
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE [Serial Number] = '1820477'
AND MODEL_NAME = 'SELP28135G'
AND [Reception No] IN ('23040196')
AND [Parts No] IS NOT NULL



SELECT *
FROM B01_01_TT_SOK_WARRANTY
WHERE [Serial No] = '1820477'
AND [Model Name] = 'SELP28135G'







	SELECT 
	DISTINCT [Parts No], ZF_DETAIL_FLAG
	FROM B02_01_TT_SOK_DETAIL_TABLE
	WHERE [Parts No] NOT IN 
	(
		SELECT DISTINCT Material_Number
		FROM [Parts Master_202503_2]
		UNION
		SELECT DISTINCT Material_Number
		FROM [Parts Master_202503]
	)
	AND [Parts No] IS NOT NULL

-- A5016707D

SELECT 
	DISTINCT [Parts No] 
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE [Parts No] IS NOT NULL
AND ZF_Retail_I_W = 0





SELECT DISTINCT *
FROM [Parts Master_202503]
WHERE Material_Number IN 
(
'A5036913K',
'A5036913K',
'A5036914K',
'A5070546A',
'A5070547A'
)


SELECT *
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE [Parts No] IS NOT NULL
AND ZF_Retail_O_W IS NULL


-- 100165611

ALTER TABLE [Parts Master_202503_2] ADD Material_Number NVARCHAR(100)


UPDATE [Parts Master_202503_2]
SET Material_Number =
CASE 
	WHEN LEFT([?? ??],2) = '00' THEN RIGHT([?? ??], LEN([?? ??]) -2)
	ELSE [?? ??]

END 





SELECT DISTINCT 
	LEFT([?? ??],2),
	[?? ??],
	RIGHT([?? ??], LEN([?? ??]) -2)
FROM [Parts Master_202503_2]
WHERE LEFT([?? ??],2) = '00'



------------------------------------------------------------------------- STEP 16 Add customer complain ----------------------------------------------



ALTER TABLE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP ADD ZF_CUS_COM_EN NVARCHAR(MAX)

UPDATE B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
SET ZF_CUS_COM_EN = [Customer Complaint (EN)]
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP A 
	INNER JOIN Customer_ B 
		ON TRIM(A.[Customer Complaint ]) = TRIM(B.[Customer Complaint ])

SELECT DISTINCT [Customer Complaint ], REPLACE([Customer Complaint ],' ','')
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE ZF_CUS_COM_EN IS NULL 



SELECT [Customer Complaint ]
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE REPLACE([Customer Complaint ],' ','') = N'???????? ??????: ???????: ?????: ??:'

SELECT *
FROM Customer_
WHERE [Customer Complaint ] = N'??? ?? ??/???? ??? ???/HDMI ???? ?????? :  ??? ???? :  ??? ?? :  ?? :'




SELECT DISTINCT [Parts No]
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE [Parts No] IS NOT NULL

-- 6129
-- 5314

SELECT DISTINCT [Parts No]
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE [Parts No] IS NOT NULL
AND [Parts No] NOT IN 

(

	SELECT DISTINCT [Material_Number]
	FROM [Parts Master_202503]
	
)




-- 93078


SELECT COUNT(*)
FROM [Parts Master_202503]





SELECT *
FROM [Parts Master_202503]
WHERE COGS LIKE '%.%'











-- 23,924,600


-- 25030135, DSC-W810, 1191152

SELECT *
FROM B01_01_TT_SOK_WARRANTY
WHERE [Receipt number] = '25030135'
AND [Model Name]  = 'DSC-W810'





SELECT DISTINCT 
	[Model Name],
	SUM(ZF_SONY_NEED_TO_PAY * ZF_EXCHANGE) A
FROM B01_01_TT_SOK_WARRANTY
GROUP BY [Model Name]
ORDER BY A DESC

select *
FROM B01_01_TT_SOK_WARRANTY
WHERE [Warranty Expiry date] < [Repair Completed Date]
AND ZF_SONY_NEED_TO_PAY > 0
AND YEAR([Warranty Expiry date]) <> 1900
AND DATEDIFF(D, [Warranty Expiry date], [Warranty Expiry date]) > 30

---- Phan tioch

select 
	SUM(ZF_SONY_NEED_TO_PAY * ZF_EXCHANGE)
FROM B01_01_TT_SOK_WARRANTY
WHERE [Warranty Expiry date] < [Receipt date from customer]
AND ZF_SONY_NEED_TO_PAY > 0
AND [Warranty classification] IN ( 'IW', 'OW')



SELECT *
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE [Parts No] = 'A5016707A'


SELECT DISTINCT 
	[Receipt date from customer]
FROM B01_01_TT_SOK_WARRANTY
ORDER BY [Receipt date from customer] 

--107,900
-- 3237000

SELECT 107900 * 30


select *
FROM B02_01_TT_SOK_DETAIL_TABLE_NO_DUP
WHERE [Parts No] = '100166212'



---------------------------------- Question for YeanChoo

-- 1. Receipt number ?

--

SELECT *
FROM B01_01_TT_SOK_WARRANTY
WHERE [Receipt number] = '100166212'

-- Sony needs to pay, ASC pay, Customer pay, Total account payable

-- IW : Sony : labor fee + part fee
-- OW : Custonmer need to pay

SELECT 
	MIN([Repair Completed Date]),
	MAX([Repair Completed Date])
FROM B01_01_TT_SOK_WARRANTY
GROUP BY ZF_SOURCE

-- 

SELECT 
	DISTINCT *
FROM B01_01_TT_SOK_WARRANTY
WHERE [Warranty classification] = 'OW'
AND 
(
	
	[In-Warranty (IW) part fee] <> 0
	OR [In-Warranty (IW) labor] <> 0

)
ORDER BY [In-Warranty (IW) part fee] DESC




-- flag
-- Consumer only
-- Professional only
-- both
-- NOT FOUND ?




-- asc code ?


select *
FROM B01_01_TT_SOK_WARRANTY


--Exception Warranty : 
--IW
--International Warranty : proudct not bought from korean : customer pay
--OW



SELECT SUM(ZF_SONY_NEED_TO_PAY * ZF_EXCHANGE)
FROM B01_01_TT_SOK_WARRANTY
WHERE
DATEDIFF(DAY,[Receipt date from customer] , [Warranty Expiry date]) IN ( 1,2,3)
GO
