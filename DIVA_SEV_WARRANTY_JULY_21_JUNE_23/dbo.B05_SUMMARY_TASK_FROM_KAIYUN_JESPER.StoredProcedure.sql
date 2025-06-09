USE [DIVA_SEV_WARRANTY_JULY_21_JUNE_23]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [dbo].[B05_SUMMARY_TASK_FROM_KAIYUN_JESPER]
AS

/* 
	Same serial no and Model code and repair more than 1 time
*/
--- 1 . Flag : With 90 days or not ?
--  2. Same part code yes (Same serial + model code + asc : > 1 times too)

-- Make pivot table number of repair : Count job, Sum part fee, other fees. (-- Claim data ? warranty data)
-- Example cases

-- case : 1
-- Count jobs number  : 5

-- number of repair : 5 : count case 1


SELECT

	[Repair Completed Date],
	[Job Number],
	Seq,
	[Part Code],
	[ASC Code],
	ZF_TOTAL_SONY_NEEDS_TO_PAY,
	[Part Fee],
	*
FROM 
DIVA_SEV_WARRANTY_JULY_21_JUNE_23..B01_04_IT_WARRANTY_FINAL_DATA
WHERE   ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
AND [Serial No] = '4200730'
AND [Model Code] = '12541909'

-- Request 2 / Repair in north side annd next repair in south side.

SELECT

[Repair Completed Date],
[Job Number],
Seq,
[Part Code],
[ASC Code],
ZF_TOTAL_SONY_NEEDS_TO_PAY,
[Part Fee],
*

FROM 
DIVA_SEV_WARRANTY_JULY_21_JUNE_23..B01_04_IT_WARRANTY_FINAL_DATA
WHERE   ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
AND [Serial No] = '4200180'
AND [Model Code] = '12541509'


-- Request 3 /  First IW and OW 

SELECT

	[Repair Completed Date],
	[Job Number],
	Seq,
	[Part Code],
	[ASC Code],
	ZF_TOTAL_SONY_NEEDS_TO_PAY,
	[Part Fee],
	[Warranty Category],
	[Warranty Type],
	*
FROM 
DIVA_SEV_WARRANTY_JULY_21_JUNE_23..B01_04_IT_WARRANTY_FINAL_DATA
WHERE   ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
AND [Serial No] = '4200919'
AND [Model Code] = '12484809'

---------------------------------------------------- Request 4 / Request from Jesper check ----------------------------------------------------------------

-- Step 1 / Create summary table with part code end with Z
-- Calcuate Total part unit price and number of job number

DROP TABLE IF EXISTS AM_PART_CODE_WITH_END_Z

SELECT 
	DISTINCT 
		[Part Code], 
		LEFT(TRIM([Part Code]), LEN(TRIM([Part Code])) - 1) AS ZF_PART_CODE_WITHOUT_Z,
		ROUND(  SUM([Part Unit Price] * ZF_EXCHANGE)  , 2 ) AS ZF_TOTAL_PART_UNIT_CODE,
		COUNT([Job Number]) AS ZF_TOTAL_JOBS,
		ROUND(  SUM([Part Unit Price] * ZF_EXCHANGE)  , 2 ) / COUNT([Job Number])  as ZF_TOTAL_AMOUNT_DIVIDE_COUNT_JOBS
INTO AM_PART_CODE_WITH_END_Z
FROM  B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
AND RIGHT([Part Code],1) = 'Z'
GROUP BY [Part Code]


-- Step 2 / Create summary table with part code end without Z
-- Calcuate Total part unit price and number of job number

DROP TABLE IF EXISTS AM_PART_CODE_WITHOUT_END_Z

SELECT 
	DISTINCT [Part Code]
	,ROUND(  SUM([Part Unit Price] * ZF_EXCHANGE)  , 2 ) AS ZF_TOTAL_PART_UNIT_CODE,
	COUNT([Job Number]) AS ZF_TOTAL_JOBS,
	ROUND(  SUM([Part Unit Price] * ZF_EXCHANGE)  , 2 ) / COUNT([Job Number]) 
	as ZF_TOTAL_AMOUNT_DIVIDE_COUNT_JOBS
INTO AM_PART_CODE_WITHOUT_END_Z
FROM  B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
AND RIGHT([Part Code],1) <> 'Z'
AND [Part Code] IN (SELECT DISTINCT ZF_PART_CODE_WITHOUT_Z FROM AM_PART_CODE_WITH_END_Z)
GROUP BY [Part Code]

-- Step 3 / Create part code summary table combine Part code with Z and without Z.

DROP TABLE IF EXISTS AM_PART_CODE_SUMMMARY

SELECT 
	A.[Part Code]  AS [Part Code Z],
	A.ZF_TOTAL_PART_UNIT_CODE as ZF_TOTAL_PART_UNIT_CODE_Z,
	A.ZF_TOTAL_JOBS AS ZF_TOTAL_JOBS_Z,
	ROUND(A.ZF_TOTAL_AMOUNT_DIVIDE_COUNT_JOBS,2) AS ZF_TOTAL_AMOUNT_DIVIDE_COUNT_JOBS_Z,
	B.[Part Code] AS [Part Code withoutZ],
	B.ZF_TOTAL_PART_UNIT_CODE as ZF_TOTAL_PART_UNIT_CODE_WITHOUT_Z,
	B.ZF_TOTAL_JOBS AS ZF_TOTAL_JOBS_WITHOUT_Z,
	ROUND(B.ZF_TOTAL_AMOUNT_DIVIDE_COUNT_JOBS,2) AS ZF_TOTAL_AMOUNT_DIVIDE_COUNT_JOBS_WITHOUT_Z,
	b.ZF_TOTAL_AMOUNT_DIVIDE_COUNT_JOBS / A.ZF_TOTAL_AMOUNT_DIVIDE_COUNT_JOBS AS [New / Refurbished]
INTO AM_PART_CODE_SUMMMARY
FROM AM_PART_CODE_WITH_END_Z A 
	INNER JOIN  AM_PART_CODE_WITHOUT_END_Z B 
		ON A.ZF_PART_CODE_WITHOUT_Z = B.[Part Code]

ORDER BY  [New / Refurbished] DESC

-- Step 4 / For each part code we need to add max number of repair for same serial no and model code relevant


ALTER TABLE AM_PART_CODE_SUMMMARY ADD ZF_MAX_NUMBER_REPAIR INT

UPDATE AM_PART_CODE_SUMMMARY 
SET ZF_MAX_NUMBER_REPAIR = B.ZF_MAX
FROM AM_PART_CODE_SUMMMARY A
INNER JOIN (
	SELECT 
		[Part Code],  
		MAX(ZF_NUMBER_JOBS) AS ZF_MAX
	FROM (
	SELECT [Serial No], [Model Code],[Part Code], count(DISTINCT [Job Number]) AS ZF_NUMBER_JOBS,
	CONCAT([Serial No],'_', [Model Code],'_',  Count(DISTINCT [Job Number])) AS ZF_CONCAT
	FROM   B01_04_IT_WARRANTY_FINAL_DATA
	WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
	AND [Part Code] in
	(
		SELECT DISTINCT [Part Code]
		FROM AM_PART_CODE_WITH_END_Z
	)
	GROUP BY [Serial No], [Model Code],[Part Code]
	HAVING COUNT(DISTINCT [Job Number]) > 1
	)A
	GROUP BY [Part Code]
) B
	ON A.[Part Code Z] = B.[Part Code] 


------------------------------------------------------------------------ QUESTION FOR JESPER-----------------------------------------------------


-- Question 1 / 
-- Step 1 / Show the summary table 

SELECT *
FROM AM_PART_CODE_SUMMMARY
WHERE ZF_MAX_NUMBER_REPAIR > [New / Refurbished]
and [Part Code Z] = 'A5045700AZ'
ORDER BY ZF_TOTAL_PART_UNIT_CODE_Z DESC

-- Step 2 / Combine Serial no and Model code how many Jobs number
-- Filter submit and Part code = A5045700AZ

SELECT [Serial No], [Model Code], count(DISTINCT [Job Number]) as 'Number of Job'
FROM   B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
and [Part Code] = 'A5045700AZ'
GROUP BY [Serial No], [Model Code]
HAVING COUNT(DISTINCT [Job Number]) > 1
ORDER BY count(DISTINCT [Job Number]) DESC

-- 8670493	12539909

SELECT [Serial No], [Model Code], [Part Code], [Part Unit Price] * ZF_EXCHANGE, [Job Number],
Customer_Complaint, [Repair Action/Technician Remarks],
[Begin Repair Date],
[Reservation Create Date],
[Repair Completed Date]
FROM   B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
and [Part Code] = 'A5045700AZ'
AND [Serial No] = '8670493'
AND [Model Code] = '12539909'


-- Question 2 A5046335AZ

SELECT *
FROM AM_PART_CODE_SUMMMARY
WHERE ZF_MAX_NUMBER_REPAIR > [New / Refurbished]
and [Part Code Z] = 'A5046335AZ'
ORDER BY ZF_TOTAL_PART_UNIT_CODE_Z DESC

-- Step 2 / Combine Serial no and Model code how many Jobs number
-- Filter submit and Part code = A5045700AZ

SELECT [Serial No], [Model Code], count(DISTINCT [Job Number]) as 'Number of Job'
FROM   B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
and [Part Code] = 'A5046335AZ'
GROUP BY [Serial No], [Model Code]
HAVING COUNT(DISTINCT [Job Number]) > 1
ORDER BY count(DISTINCT [Job Number]) DESC

-- 8670493	12539909

SELECT [Serial No], [Model Code], [Part Code], [Part Unit Price] * ZF_EXCHANGE as Part_unit_Price_usd, [Job Number],
Customer_Complaint, [Repair Action/Technician Remarks],
[Begin Repair Date],
[Reservation Create Date],
[Repair Completed Date]
FROM   B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
and [Part Code] = 'A5046335AZ'
AND [Serial No] = '8672802'
AND [Model Code] = '12539309'

-- -- Question 3


SELECT *
FROM AM_PART_CODE_SUMMMARY
WHERE ZF_MAX_NUMBER_REPAIR > [New / Refurbished]
and [Part Code Z] = 'A5030472A'
ORDER BY ZF_TOTAL_PART_UNIT_CODE_Z DESC


SELECT [Serial No], [Model Code], [Part Code], [Part Unit Price] * ZF_EXCHANGE as Part_unit_Price_usd, [Job Number],
Customer_Complaint, [Repair Action/Technician Remarks],
[Begin Repair Date],
[Reservation Create Date],
[Repair Completed Date]
FROM   B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
and ZF_PART_CODE_WITHOUT_Z = 'A5030472A'
AND [Serial No] = '8555989'
AND [Model Code] = '12485709'
ORDER BY [Reservation Create Date] ASC


-- -- Question 4 : Cases Kaiyun want to see more

SELECT *
FROM AM_PART_CODE_SUMMMARY
WHERE ZF_MAX_NUMBER_REPAIR > [New / Refurbished]
and [Part Code Z] = 'A5027267AZ'
ORDER BY ZF_TOTAL_PART_UNIT_CODE_Z DESC


SELECT [Serial No], [Model Code], [Part Code], [Part Unit Price] * ZF_EXCHANGE as Part_unit_Price_usd, [Job Number],
Customer_Complaint, [Repair Action/Technician Remarks],
[Begin Repair Date],
[Reservation Create Date],
[Repair Completed Date]
FROM   B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
and ZF_PART_CODE_WITHOUT_Z = 'A5027267A'
AND [Serial No] = '4212294'
AND [Model Code] = '12486909'
ORDER BY [Reservation Create Date] ASC



SELECT [Serial No], [Model Code], count(DISTINCT [Job Number]) as 'Number of Job'
FROM   B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
and [Part Code] = 'A5027267AZ'
GROUP BY [Serial No], [Model Code]
HAVING COUNT(DISTINCT [Job Number]) > 1
ORDER BY count(DISTINCT [Job Number]) DESC





select 60.74* 2



-- Cases Kaiyun want to see more


SELECT *
FROM AM_PART_CODE_SUMMMARY
WHERE ZF_MAX_NUMBER_REPAIR > [New / Refurbished]
and [Part Code Z] = 'A5000285AZ'
ORDER BY ZF_TOTAL_PART_UNIT_CODE_Z DESC






-- 4009759	18308309	A5017610A


SELECT [Serial No], [Model Code], ZF_PART_CODE_WITHOUT_Z, SUM(IIF(RIGHT([Part Code],1) = 'Z',1,0))
FROM   B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
AND ZF_PART_CODE_WITHOUT_Z IN

(
	SELECT DISTINCT [Part Code withoutZ]
	FROM AM_PART_CODE_SUMMMARY

)
GROUP BY [Serial No], [Model Code], ZF_PART_CODE_WITHOUT_Z
HAVING COUNT(DISTINCT [Part Code]) > 1
AND COUNT(DISTINCT [Job Number]) >2 
ORDER BY SUM(IIF(RIGHT([Part Code],1) = 'Z',1,0)) DESC



-- ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_FISCAL_YEAR_H1_H2 NVARCHAR(10)


--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_FISCAL_YEAR_H1_H2 = 
 
--	CASE 
--		-- 2021
--		WHEN CONVERT(DATE, [Repair Completed Date], 102) BETWEEN '2021-04-01' AND '2021-09-30' THEN '2021-H1'
--		WHEN CONVERT(DATE, [Repair Completed Date], 102) BETWEEN '2021-10-01' AND '2022-03-31' THEN '2021-H2'
--		-- 2022
--		WHEN CONVERT(DATE, [Repair Completed Date], 102) BETWEEN '2022-04-01' AND '2022-09-30' THEN '2022-H1'
--		WHEN CONVERT(DATE, [Repair Completed Date], 102) BETWEEN '2022-10-01' AND '2023-03-31' THEN '2022-H2'
--		-- 2023
--		WHEN CONVERT(DATE, [Repair Completed Date], 102) BETWEEN '2023-04-01' AND '2023-09-30' THEN '2023-H1'
--		WHEN CONVERT(DATE, [Repair Completed Date], 102) BETWEEN '2023-10-01' AND '2024-03-31' THEN '2023-H2'
--		-- 2024
--		WHEN CONVERT(DATE, [Repair Completed Date], 102) BETWEEN '2024-04-01' AND '2024-09-30' THEN '2024-H1'
--		WHEN CONVERT(DATE, [Repair Completed Date], 102) BETWEEN '2024-10-01' AND '2025-03-31' THEN '2024-H2'

--	END 


	
--FROM B01_04_IT_WARRANTY_FINAL_DATA


GO
