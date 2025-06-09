USE [DIVA_SME_DSP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROC [dbo].[B01_HANDLE_SME_SOUNDTRACK] 
AS


-- Step 1 / Create a cube to store tireA, B and C
-- Main key : [Vendor Key], [Reporting Start Date], Country
/*
Vendor Key	VENDOR NAME                             Tire
POU3		STYB – Basic Customized Service			A
POU5		STYB - Self-Curated Service				C
POU4		STYB - Enhanced Customized Service		B
*/

DROP TABLE IF EXISTS B01_SME_STATEMENT_DATA 
SELECT
 CONVERT(DATE, CAST(CAST([Reporting Start Date] AS BIGINT) AS CHAR(8)), 112) AS [Reporting Start Date Convert],
 CONVERT(DATE, CAST(CAST([Reporting End Date] AS BIGINT) AS CHAR(8)), 112) AS [Reporting End Date Convert],
	*
INTO B01_SME_STATEMENT_DATA
FROM SME_STATEMENT
WHERE [Vendor Key] <> 'PVR7'

-- Step 1 / SME’s Usage Percentage : Calculation
-- Monthly Playback Number for Authorized Recordings (column AB, Total plays for SME Content) divided by Monthly Playback Number for all Licensed Music Content (column AA, Total plays across all content providers)
-- group by vendor key + month
DROP  TABLE IF EXISTS B02_SME_USAGE_PERCENTAGE

SELECT 
	[Vendor Key],
	[Vendor Name],
	Country,
	[Reporting Start Date Convert],
	SUM([Total plays for SME Content]) / SUM([Total plays across all content providers]) AS ZF_SME_USAGE_PERCENTAGE,
	SUM([Total plays for SME Content]) AS ZF_TOTAL_PLAYS_FOR_SME_CONTENT,
	 SUM([Total plays across all content providers]) AS ZF_TOTAL_PLAYS_ACROSS_ALL_CONTEN
INTO B02_SME_USAGE_PERCENTAGE
FROM B01_SME_STATEMENT_DATA
GROUP BY [Vendor Key], [Reporting Start Date Convert], [Vendor Name], Country
ORDER BY [Vendor Key], [Reporting Start Date Convert]

-- 

ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_SME_USAGE_PERCENTAGE FLOAT;

UPDATE A
SET A.ZF_SME_USAGE_PERCENTAGE = B.ZF_SME_USAGE_PERCENTAGE

FROM B01_SME_STATEMENT_DATA A
INNER JOIN B02_SME_USAGE_PERCENTAGE B
	ON A.[Vendor Key] = B.[Vendor Key]
	AND A.[Reporting Start Date Convert] = B.[Reporting Start Date Convert]
	AND A.Country = B.Country


SELECT [Vendor Key]
FROM B02_SME_USAGE_

PERCENTAGE
GROUP BY [Vendor Key] , [Reporting Start Date Convert], Country
HAVING COUNT(*) > 1


SELECT MAX([Reporting Start Date Convert]) FROM B01_SME_STATEMENT_DATA
WHERE [Vendor Key] = 'POU4'


select DISTINCT [Exchange Rate], [Reporting Start Date Convert]
FROM B01_SME_STATEMENT_DATA
where [Local Currency for Revenue ] = 'EUR'


-- Step 2 / Applicable Service Fee : Calculation
-- 142

ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_APPLICABLE_FEE FLOAT


-- Question 1 /  RCD Added - Fees (Jul 20) COPY tab in excel

-- Question 2 / 

SELECT 
	DISTINCT Country, [Local Currency for Revenue ], *
FROM B01_SME_STATEMENT_DATA
WHERE [Vendor Key] = 'POU4'
AND MONTH([Reporting Start Date Convert]) = 7 AND YEAR([Reporting Start Date Convert]) = 2020
AND Country IN 
(
	SELECT MARKET
	FROM [RCD Added - Fees (Jul 20) COPY]
	GROUP BY MARKET
	HAVING COUNT(*) > 1
)

SELECT *
	FROM [RCD Added - Fees (Jul 20) COPY]
WHERE MARKET IN (
'BG',
'BH',
'MA',
'MT'
)

-- country- market
-- currency - l
-- Question 3 

SELECT *
FROM [RCD Added - Fees (Jul 20) COPY]
WHERE MARKET = 'MT'


-- Step 2.1 Update value for TireB vendor key = POU4 : 
-- STYB - Enhanced Customized Service
-- 59 Records.
UPDATE A
SET A.ZF_APPLICABLE_FEE = B.FEE
FROM B01_SME_STATEMENT_DATA A 
	INNER JOIN 
		(
			SELECT *
			FROM [RCD Added - Fees (Jul 20) COPY]
			WHERE NOT(MARKET = 'MT' AND FEE = 3.55)
		)AS B
	ON A.Country = B.MARKET
	AND A.[Local Currency for Revenue ] = B.CURRENCY
WHERE [Vendor Key] = 'POU4'
AND MONTH([Reporting Start Date Convert]) = 7 AND YEAR([Reporting Start Date Convert]) = 2020

-- Step 2.2
-- Update tireB with Report start from 08/2020
-- TireB1 : Sound Zone Minima (from August 1 2020 to January 31 2021 
-- Question for Jesper
SELECT *
FROM B01_SME_STATEMENT_DATA A
	INNER JOIN [RCD Added - Fees (Aug 20 fw] B
		ON A.Country = B.MARKET	   
		AND A.[Local Currency for Revenue ] <> B.Currency
WHERE  [Vendor Key] = 'POU4'
AND [Reporting Start Date Convert] BETWEEN '2020-08-01' AND '2021-01-01'

-- 
UPDATE A
SET A.ZF_APPLICABLE_FEE = B.TierB1
FROM B01_SME_STATEMENT_DATA A
	INNER JOIN [RCD Added - Fees (Aug 20 fw] B
		ON A.Country = B.MARKET	   
WHERE  [Vendor Key] = 'POU4'
AND [Reporting Start Date Convert] BETWEEN '2020-08-01' AND '2021-01-01'
AND ZF_APPLICABLE_FEE IS NULL

-- -- TireB2 : Sound Zone Minima (from February 1 2021 onwards) 
-- 1315
UPDATE A
SET A.ZF_APPLICABLE_FEE = B.TierB11
FROM B01_SME_STATEMENT_DATA A
	INNER JOIN [RCD Added - Fees (Aug 20 fw] B
		ON A.Country = B.MARKET	   
WHERE  [Vendor Key] = 'POU4'
AND ZF_APPLICABLE_FEE IS NULL

-- Step 2.3 Update tireA
-- 1170

UPDATE A
SET A.ZF_APPLICABLE_FEE = B.[Tier A]
FROM B01_SME_STATEMENT_DATA A
	INNER JOIN [RCD Added - Fees (Aug 20 fw] B
		ON A.Country = B.MARKET	   
WHERE [Vendor Key] = 'POU3'
AND ZF_APPLICABLE_FEE IS NULL

-- Step 2.4 Update applicable fee tireC
-- 2219
UPDATE A
SET A.ZF_APPLICABLE_FEE = B.[Tier C]
FROM B01_SME_STATEMENT_DATA A
	INNER JOIN [RCD Added - Fees (Aug 20 fw] B
		ON A.Country = B.MARKET	   
WHERE [Vendor Key] = 'POU5'
AND ZF_APPLICABLE_FEE IS NULL

---------------------------------------------------------------------Revenue calculation per service type ---------------------------------------------------------------


ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_REVENUE_VALUE FLOAT;
ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_REVENUE_FLAG NVARCHAR(100);
ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_REVENUE_OPTION1_VALUE FLOAT;
ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_REVENUE_OPTION2_VALUE FLOAT;

-- Step 3 .Revenue calculation per service type
/*
Basic Customized Service (Tier A)
The greater of:
•	SME’s Usage Percentage (described below) multiplied by 15% of net revenue (column V, Net Revenue Across All Content Providers in Local Currency), or
•	Number of subscriptions (column K, Total # of Users) multiplied by applicable service fee (refer to RCD Added – Fees tabs, described below) multiplied by SME’s Usage Percentage


*/
-- Step 3.1 Update for tierA

UPDATE B01_SME_STATEMENT_DATA
SET ZF_REVENUE_OPTION1_VALUE = ZF_SME_USAGE_PERCENTAGE * 0.15 * [Net Revenue across all content providers in Local  Currency],
	ZF_REVENUE_OPTION2_VALUE = [Total # of Users ] * ZF_APPLICABLE_FEE * ZF_SME_USAGE_PERCENTAGE
WHERE  [Vendor Key] = 'POU3' 

UPDATE B01_SME_STATEMENT_DATA
SET ZF_REVENUE_VALUE =
	CASE 
		WHEN ZF_REVENUE_OPTION1_VALUE > ZF_REVENUE_OPTION2_VALUE THEN ZF_REVENUE_OPTION1_VALUE
		ELSE ZF_REVENUE_OPTION2_VALUE
	END,
ZF_REVENUE_FLAG = 
	CASE 
		WHEN ZF_REVENUE_OPTION1_VALUE > ZF_REVENUE_OPTION2_VALUE THEN 'Option 1'
		ELSE  'Option 2'
	END
WHERE  [Vendor Key] = 'POU3'

-- Step 3.2 Update tireC
/*
•	SME’s Usage Percentage (described below) multiplied by 50% of net revenue (column V, Net Revenue Across All Content Providers in Local Currency), or
•	Number of subscriptions (column K, Total # of Users) multiplied by applicable service fee (refer to RCD Added – Fees tabs, described below) multiplied by SME’s Usage Percentage

*/

UPDATE B01_SME_STATEMENT_DATA
SET ZF_REVENUE_OPTION1_VALUE = ZF_SME_USAGE_PERCENTAGE * 0.5 * [Net Revenue across all content providers in Local  Currency],
	ZF_REVENUE_OPTION2_VALUE = [Total # of Users ] * ZF_APPLICABLE_FEE * ZF_SME_USAGE_PERCENTAGE
WHERE  [Vendor Key] = 'POU5' 


UPDATE B01_SME_STATEMENT_DATA
SET ZF_REVENUE_VALUE =
	CASE 
		WHEN ZF_REVENUE_OPTION1_VALUE > ZF_REVENUE_OPTION2_VALUE THEN ZF_REVENUE_OPTION1_VALUE
		ELSE ZF_REVENUE_OPTION2_VALUE
	END,
ZF_REVENUE_FLAG = 
	CASE 
		WHEN ZF_REVENUE_OPTION1_VALUE > ZF_REVENUE_OPTION2_VALUE THEN 'Option 1'
		ELSE  'Option 2'
	END
WHERE  [Vendor Key] = 'POU5'

-- Step 3.3 / TireB

/*
•	SME’s Usage Percentage (described below) multiplied by 22% of net revenue (column V, Net Revenue Across All Content Providers in Local Currency, described below), or
•	Number of subscriptions (column K, Total # of Users) multiplied by applicable service fee (refer to RCD Added – Fees tabs, described below) multiplied by SME’s Usage Percentage


*/

UPDATE B01_SME_STATEMENT_DATA
SET ZF_REVENUE_OPTION1_VALUE = ZF_SME_USAGE_PERCENTAGE * IIF(MONTH([Reporting Start Date Convert]) = 7 AND YEAR([Reporting Start Date Convert]) = 2020, 0.2,0.22) * [Net Revenue across all content providers in Local  Currency],
	ZF_REVENUE_OPTION2_VALUE = [Total # of Users ] * ZF_APPLICABLE_FEE * ZF_SME_USAGE_PERCENTAGE
WHERE  [Vendor Key] = 'POU4'

-- 
UPDATE B01_SME_STATEMENT_DATA
SET ZF_REVENUE_VALUE =
	CASE 
		WHEN ZF_REVENUE_OPTION1_VALUE > ZF_REVENUE_OPTION2_VALUE THEN ZF_REVENUE_OPTION1_VALUE
		ELSE ZF_REVENUE_OPTION2_VALUE
	END,
ZF_REVENUE_FLAG = 
	CASE 
		WHEN ZF_REVENUE_OPTION1_VALUE > ZF_REVENUE_OPTION2_VALUE THEN 'Option 1'
		ELSE  'Option 2'
	END
WHERE  [Vendor Key] = 'POU4'


-- Step 8 / Add Local currency and exchange rate into SME file/

ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_LOCAL_CURRENCY_UPDATE NVARCHAR(3);

UPDATE B01_SME_STATEMENT_DATA
SET ZF_LOCAL_CURRENCY_UPDATE = [Local Currency for Revenue ]


UPDATE B01_SME_STATEMENT_DATA
SET ZF_LOCAL_CURRENCY_UPDATE = 'MAD'
WHERE Country = 'MA'


-- Step 9 / Add exchange rate

ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_EXCHANGE_REATE_USD FLOAT

SELECT 	COUNTRY AS ZF_COUNTRY_KEY_KEY_DM,
    USD,
    LINK 
FROM AM_EXCHANGE_RATE

UPDATE A
SET ZF_EXCHANGE_REATE_USD = B.USD
FROM B01_SME_STATEMENT_DATA A 
INNER JOIN AM_EXCHANGE_RATE B 
	ON A.Country = B.COUNTRY





SELECT [Local Currency for Revenue ], [Customer Retail Price - Currency],*
FROM B01_SME_STATEMENT_DATA
WHERE Country = 'MA'




SELECT 
	[Reporting Start Date Convert],
	[Vendor Name],
	Country,
	[Total plays for SME Content] ,
	[Total plays across all content providers] ,
	ZF_SME_USAGE_PERCENTAGE,
	[Net Revenue across all content providers in Local  Currency],
	ZF_REVENUE_OPTION1_VALUE,
	[Total # of Users ],
	ZF_APPLICABLE_FEE,
	ZF_SME_USAGE_PERCENTAGE,
	ZF_REVENUE_OPTION2_VALUE,
	ZF_REVENUE_VALUE,
	ZF_REVENUE_FLAG
FROM B01_SME_STATEMENT_DATA
WHERE [Vendor Key] = 'POU3'

ALTER TABLE B01_SME_STATEMENT_DATA ADD ZF_PERCENT_NET_VALUE NVARCHAR(10);

/*
Vendor Key	VENDOR NAME                             Tire
POU3		STYB – Basic Customized Service			A
POU5		STYB - Self-Curated Service				C
POU4		STYB - Enhanced Customized Service		B

*/

UPDATE B01_SME_STATEMENT_DATA
SET ZF_PERCENT_NET_VALUE = 
CASE 
	WHEN  [Vendor Key] = 'POU3' THEN '15%'
	WHEN [Vendor Key] = 'POU5' THEN '50%'
	WHEN [Vendor Key] = 'POU4' AND MONTH([Reporting Start Date Convert]) = 7 AND YEAR([Reporting Start Date Convert]) = 2020 THEN '20%'
	ELSE '22%'

END 





SELECT DISTINCT 
	Country

FROM B01_SME_STATEMENT_DATA
group by Country
having count(distinct [Local Currency for Revenue ]) > 1


select DISTINCT 
	COUNTRY, [Local Currency for Revenue ]
FROM B01_SME_STATEMENT_DATA




SELECT 
	TierB1
FROM B01_SME_STATEMENT_DATA A
	INNER JOIN [RCD Added - Fees (Aug 20 fw] B
		ON A.Country = B.MARKET	   
WHERE  [Vendor Key] = 'POU4'
AND [Reporting Start Date Convert] BETWEEN '2020-08-01' AND '2021-01-01'


/*
GI	GIP
MX	MXN
*/

SELECT *
FROM [RCD Added - Fees (Aug 20 fw]
WHERE MARKET IN ( 'GI','MX')



SELECT *
FROM AM_RATE_MAPPING







GO
