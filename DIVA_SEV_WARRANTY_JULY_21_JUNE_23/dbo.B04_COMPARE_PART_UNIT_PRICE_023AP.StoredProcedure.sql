USE [DIVA_SEV_WARRANTY_JULY_21_JUNE_23]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[B04_COMPARE_PART_UNIT_PRICE_023AP]
AS


-- 1. Regarding Warranty dashboard.

-- Step 1/ Create Warranty Submit table 

DROP TABLE B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT

SELECT *
INTO B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
AND 
(
	( 
		YEAR([Repair Completed Date]) = 2023 	AND MONTH([Repair Completed Date]) BETWEEN 4 AND 12
	)
	OR
	(
		YEAR([Repair Completed Date]) = 2024 	AND MONTH([Repair Completed Date]) BETWEEN 1 AND 9
	)
)

-- 1.2 Remove line with part code len = 1


DELETE FROM  B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT
WHERE LEN([Part Code]) = 1

-- 1.3 Check if Submit and Rejected need to deleted if part code is rejected 
-- DELETED 59 records

DELETE FROM B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT
WHERE   ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled')
AND ZF_PART_FEE_CLAIM_STATUS = 'RC Rejected'

-- 1.4 Add repair completed date year month

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT ADD ZF_YEAR_MONTH_REPAIR_COMPLETED_DATE NVARCHAR(10)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT
SET ZF_YEAR_MONTH_REPAIR_COMPLETED_DATE = CONCAT( YEAR([Repair Completed Date]), '-',FORMAT(MONTH([Repair Completed Date]), '00'))


-- 2. Handle 02 data.
-- Step 2.1 / Related to 02 data.

ALTER TABLE [02_NPC_Purchase_Invoice_Apr23 to Sep24 1] ADD ZF_RPSI_RECEIVE_DATE_UPDATE DATE

UPDATE [02_NPC_Purchase_Invoice_Apr23 to Sep24 1]
SET ZF_RPSI_RECEIVE_DATE_UPDATE =CONVERT(DATE, RPSI_RECEIVE_DATE, 105) 

-- 2.2 Update the Year and Month from ZF_RPSI_RECEIVE_DATE_UPDATE
ALTER TABLE [02_NPC_Purchase_Invoice_Apr23 to Sep24 1] ADD ZF_YEAR_MONTH_RPSI_RECEIVE_DATE NVARCHAR(10)

UPDATE [02_NPC_Purchase_Invoice_Apr23 to Sep24 1]
SET ZF_YEAR_MONTH_RPSI_RECEIVE_DATE = CONCAT( YEAR(ZF_RPSI_RECEIVE_DATE_UPDATE), '-',FORMAT(MONTH(ZF_RPSI_RECEIVE_DATE_UPDATE), '00'))


-- Hanlde 3 / Related to 03 table
-- Step 3.1. Update invoice date format incorrect.

UPDATE A
SET ZF_INVOICE_DATE_UPDATE = formatted_date,
	ZF_SOURCE_FLAG = SOURCE
FROM [03_Report sale- adjust out Z parts (Apr23 to Sep24)] A
	INNER JOIN _03_FINAL B
		ON A.Invoice_no = B.Invoice_no
		AND A.NC_sales_no = B.NC_sales_no

/*
SELECT 
    date_column,
    CASE 
        -- Tru?ng h?p có d?u "/" (dd/mm/yyyy ho?c d/m/yyyy)
        WHEN date_column LIKE '%/%/%' THEN CONVERT(DATE, date_column, 103)  

        -- Tru?ng h?p có d?u "-" (dd-mm-yy)
        WHEN date_column LIKE '%-%-%' THEN 
            CONVERT(DATE, 
                '20' + RIGHT(date_column, 2) + '-' + SUBSTRING(date_column, 4, 2) + '-' + LEFT(date_column, CHARINDEX('-', date_column) - 1), 
                120)  
    END AS formatted_date
FROM your_table;

Option 2
CONVERT(DATE, date_column, 103)


*/
			   
-- Step 3.2  Update the Year and Month from Invoice_date

ALTER TABLE [03_Report sale- adjust out Z parts (Apr23 to Sep24)] ADD ZF_YEAR_MONTH_INVOICE_DATE NVARCHAR(10)


UPDATE [03_Report sale- adjust out Z parts (Apr23 to Sep24)]
SET ZF_YEAR_MONTH_INVOICE_DATE = CONCAT( YEAR(ZF_INVOICE_DATE_UPDATE), '-',FORMAT(MONTH(ZF_INVOICE_DATE_UPDATE), '00'))



--- Hanlde 4 / 
-- 4.1

DROP TABLE AM_PART_CODE_MAPPING
SELECT *
INTO AM_PART_CODE_MAPPING
FROM (

SELECT DISTINCT 
	INVOICE_PART_NO , '02'  AS ZF_SOUR_FLAG
FROM 
[02_NPC_Purchase_Invoice_Apr23 to Sep24 1]
UNION 
SELECT DISTINCT 
	Invoice_part_code, '03'  AS ZF_SOUR_FLAG
FROM 
[03_Report sale- adjust out Z parts (Apr23 to Sep24)]
UNION
SELECT DISTINCT [Part Code], 'AP-NEWSIS' AS ZF_SOUR_FLAG
FROM B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT
WHERE LEN([Part Code]) > 1
)A

-- Step 4.2 Add ZF_PART_CODE flag found in 3 file

ALTER TABLE AM_PART_CODE_MAPPING ADD ZF_PART_CODE NVARCHAR(1000)

-- 4.2.1 Exists in 3 data

UPDATE AM_PART_CODE_MAPPING
SET ZF_PART_CODE = 'Exists in 3 data'
FROM AM_PART_CODE_MAPPING
WHERE INVOICE_PART_NO IN (
	SELECT INVOICE_PART_NO
	FROM AM_PART_CODE_MAPPING
	GROUP BY INVOICE_PART_NO
	HAVING COUNT(*) = 3
)

-- 4.2.2 02 Only
UPDATE AM_PART_CODE_MAPPING
SET ZF_PART_CODE = '02 Only'
FROM AM_PART_CODE_MAPPING
WHERE INVOICE_PART_NO IN (
	SELECT INVOICE_PART_NO
	FROM AM_PART_CODE_MAPPING
	GROUP BY INVOICE_PART_NO
	HAVING COUNT(*) = 1
)
AND ZF_SOUR_FLAG = '02'
AND  ZF_PART_CODE IS NULL

-- 4.2.3 03 Only
UPDATE AM_PART_CODE_MAPPING
SET ZF_PART_CODE = '03 Only'
FROM AM_PART_CODE_MAPPING
WHERE INVOICE_PART_NO IN (
	SELECT INVOICE_PART_NO
	FROM AM_PART_CODE_MAPPING
	GROUP BY INVOICE_PART_NO
HAVING COUNT(*) = 1
)
AND ZF_SOUR_FLAG = '03'
AND  ZF_PART_CODE IS NULL

-- 4.2.4 AP-NEWSIS only
UPDATE AM_PART_CODE_MAPPING
SET ZF_PART_CODE = 'AP-NEWSIS only'
FROM AM_PART_CODE_MAPPING
WHERE INVOICE_PART_NO IN (
	SELECT INVOICE_PART_NO
	FROM AM_PART_CODE_MAPPING
	GROUP BY INVOICE_PART_NO
	HAVING COUNT(*) = 1
)
AND ZF_SOUR_FLAG = 'AP-NEWSIS'
AND  ZF_PART_CODE IS NULL

-- 4.2.5 02, 03 only

UPDATE AM_PART_CODE_MAPPING
SET ZF_PART_CODE = '02, 03 only'
FROM AM_PART_CODE_MAPPING
WHERE INVOICE_PART_NO IN (
	SELECT INVOICE_PART_NO
	FROM AM_PART_CODE_MAPPING
	WHERE ZF_SOUR_FLAG <> 'AP-NEWSIS'
	GROUP BY INVOICE_PART_NO
	HAVING COUNT(*) = 2
)
AND  ZF_PART_CODE IS NULL

-- 4.2.6  03, AP-NEWSIS only

UPDATE AM_PART_CODE_MAPPING
SET ZF_PART_CODE = '03, AP-NEWSIS only'
FROM AM_PART_CODE_MAPPING
WHERE INVOICE_PART_NO IN (
	SELECT INVOICE_PART_NO
	FROM AM_PART_CODE_MAPPING
	WHERE  ZF_SOUR_FLAG <> '02'
	GROUP BY INVOICE_PART_NO
HAVING COUNT(*) = 2
)
AND  ZF_PART_CODE IS NULL

-- 4.2.7 02, AP-NEWSIS only

-- 02, AP-NEWSIS only
UPDATE AM_PART_CODE_MAPPING
SET ZF_PART_CODE = '02, AP-NEWSIS only'
FROM AM_PART_CODE_MAPPING
WHERE INVOICE_PART_NO IN (
	SELECT INVOICE_PART_NO
	FROM AM_PART_CODE_MAPPING
	WHERE   ZF_SOUR_FLAG <> '03'
	GROUP BY INVOICE_PART_NO
	HAVING COUNT(*) = 2
)
AND  ZF_PART_CODE IS NULL

-- Step 4.4 Create AM_PART_CODE_MAPPING_FINAL table 

DROP TABLE AM_PART_CODE_MAPPING_FINAL

select  DISTINCT INVOICE_PART_NO, 
	CASE 
		WHEN ZF_PART_CODE = 'Exists in 3 data' THEN '1. Exists in 3 data'
		WHEN ZF_PART_CODE = '02 Only' THEN '2. 02 Only'
		WHEN ZF_PART_CODE = '03 Only' THEN '3. 03 Only'
		WHEN ZF_PART_CODE = 'AP-NEWSIS only' THEN '4. AP-NEWSIS only'
		WHEN ZF_PART_CODE = '02, 03 only' THEN '5. 02, 03 only'
		WHEN ZF_PART_CODE = '02, AP-NEWSIS only' THEN '6. 02, AP-NEWSIS only'
		ELSE '7. 03, AP-NEWSIS only'
	END ZF_INVOICE_PART_NO_FLAG,
	CASE 
		WHEN 
				UPPER(RIGHT(TRIM(INVOICE_PART_NO), 1)) IN (  'Z' , 'L') THEN 'Ends with Z/L'
				ELSE 'Other'
	END AS ZF_INVOICE_PART_NO_END_WITH_FLAG,
	ZF_YEAR_MONTH_MAPPING
INTO AM_PART_CODE_MAPPING_FINAL
FROM AM_PART_CODE_MAPPING, (SELECT DISTINCT ZF_YEAR_MONTH_MAPPING FROM AM_YEAR_MONTH_MAPPING)A


------------------------------- DONE--- RECHECK VALUE IN DASHBOARD.






--------------------------------- 5 Re-repair same Product and Part code -------------------------------------------------------------

-- 5.1 Add flag to calculated value in Qlik KPI flag based on Job, model, serial and part code.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_FLAG NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'No'

-- 2273 records.
UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'Yes'
WHERE [Job Number]+[Serial No]+[Model Code]+[PART CODE] IN (

SELECT DISTINCT [Job Number]+[Serial No]+[Model Code]+[PART CODE]
FROM (
SELECT 
    [Job Number],
    LAG([Job Number]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]) AS PreviousJob,
    DATEDIFF(DAY, 
		LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]), 
		[Repair Completed Date]
		) AS RepairGap,
		[Serial No],
		[Model Code],
		[PART CODE],
		[Part Unit Price]
FROM (
SELECT 
    [Serial No],
    [Model Code],
    [Repair Completed Date],
    [Job Number],
	[PART CODE],
	[Part Unit Price]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] <> ''
and [Model Code] <> ''
and ZF_PART_NO_END_WITH_FLAG = 'Ends with Z/L'
and [Part Unit Price] > 0
AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
)A
)A
WHERE A.[RepairGap] IS NOT NULL AND A.[RepairGap] >0
)

-- Step 5.2 Add full line with Product and Part code re-repair

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PRODUCT_PART_CODE_RE_REPAIR_FLAG NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'Yes'
WHERE [Serial No]+[Model Code]+[PART CODE] IN
(
	SELECT 
		DISTINCT [Serial No]+[Model Code]+[PART CODE]
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE 
	 ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'Yes'
	AND [Serial No] <> ''
	and [Model Code] <> ''
	and ZF_PART_NO_END_WITH_FLAG = 'Ends with Z/L'
	and [Part Unit Price] > 0
	AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
	AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
	 

)
AND [Serial No] <> ''
and [Model Code] <> ''
and ZF_PART_NO_END_WITH_FLAG = 'Ends with Z/L'
and [Part Unit Price] > 0
AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'


-- Step 5.3 Add day gap between current and prevoiues

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DAY_GAP_PRODUCT_PART_CODE_RE_REPAIR INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_DAY_GAP_PRODUCT_PART_CODE_RE_REPAIR = RepairGap
FROM B01_04_IT_WARRANTY_FINAL_DATA A1
INNER JOIN (
  SELECT DISTINCT [Job Number],RepairGap FROM (
SELECT 
        
        [Job Number],
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap
    FROM (
		SELECT 
        [Serial No],
		[Model Code], 
		[PART CODE],
        [Repair Completed Date],
        [Job Number]
        FROM B01_04_IT_WARRANTY_FINAL_DATA
		WHERE 	 ZF_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'Yes'
	
	
	) as c
) AS TEMP
) AS B
ON A1.[Job Number] = B.[Job Number]


--------------------------------- 6 Re-repair same Product and Part code with Part code end and start with A -------------------------------------------------------------
-- Start and End with A
-- Condition filter : LEFT( [Part Code],1) = 'A' AND  RIGHT( [Part Code],1) = 'A'



ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_START_END_A_FLAG NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_START_END_A_FLAG = 'No'

-- 1253 records.
UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_START_END_A_FLAG = 'Yes'
WHERE [Job Number]+[Serial No]+[Model Code]+[PART CODE] IN (

SELECT DISTINCT [Job Number]+[Serial No]+[Model Code]+[PART CODE]
FROM (
SELECT 
    [Job Number],
    LAG([Job Number]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]) AS PreviousJob,
    DATEDIFF(DAY, 
		LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]), 
		[Repair Completed Date]
		) AS RepairGap,
		[Serial No],
		[Model Code],
		[PART CODE],
		[Part Unit Price]
FROM (
		SELECT 
			[Serial No],
			[Model Code],
			[Repair Completed Date],
			[Job Number],
			[PART CODE],
			[Part Unit Price]
		FROM B01_04_IT_WARRANTY_FINAL_DATA
		WHERE [Serial No] <> ''
		and [Model Code] <> ''
		and LEFT( [Part Code],1) = 'A' AND  RIGHT( [Part Code],1) = 'A'
		and [Part Unit Price] > 0
		AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
		AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
)A
)A
WHERE A.[RepairGap] IS NOT NULL AND A.[RepairGap] >0
)

-- -- Step 5.2 Add full line with Product and Part code re-repair and Part code start and end with A

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PRODUCT_PART_CODE_RE_REPAIR_START_END_A_FLAG NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_PART_CODE_RE_REPAIR_START_END_A_FLAG = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_PART_CODE_RE_REPAIR_START_END_A_FLAG = 'Yes'
WHERE [Serial No]+[Model Code]+[PART CODE] IN
(
	SELECT 
		DISTINCT [Serial No]+[Model Code]+[PART CODE]
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE 
	 ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_START_END_A_FLAG = 'Yes'
	AND [Serial No] <> ''
	and [Model Code] <> ''
	and LEFT( [Part Code],1) = 'A' AND  RIGHT( [Part Code],1) = 'A'
	and [Part Unit Price] > 0
	AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
	AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
	 

)
AND [Serial No] <> ''
and [Model Code] <> ''
and LEFT( [Part Code],1) = 'A' AND  RIGHT( [Part Code],1) = 'A'
and [Part Unit Price] > 0
AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'


-- Step 5.3 Add day gap between current and prevoiues for part code start and end with A

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DAY_GAP_PRODUCT_PART_CODE_START_END_A_RE_REPAIR INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_DAY_GAP_PRODUCT_PART_CODE_START_END_A_RE_REPAIR = RepairGap
FROM B01_04_IT_WARRANTY_FINAL_DATA A1
INNER JOIN (
  SELECT DISTINCT [Job Number],RepairGap FROM (
SELECT 
        
        [Job Number],
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap
    FROM (
		SELECT 
        [Serial No],
		[Model Code], 
		[PART CODE],
        [Repair Completed Date],
        [Job Number]
        FROM B01_04_IT_WARRANTY_FINAL_DATA
		WHERE 	 ZF_PRODUCT_PART_CODE_RE_REPAIR_START_END_A_FLAG = 'Yes'
	
	
	) as c
) AS TEMP
) AS B
ON A1.[Job Number] = B.[Job Number]


GO
