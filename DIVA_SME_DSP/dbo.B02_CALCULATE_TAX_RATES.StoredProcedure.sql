USE [DIVA_SME_DSP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROC [dbo].[B02_CALCULATE_TAX_RATES] 
AS

EXEC SP_DROPTABLE 'B04_COMPANY_DATA_FINAL_2025'
SELECT * 
INTO B04_COMPANY_DATA_FINAL_2025
FROM [Value in PDF Files_NEW]


-- Step 0: Get all values into the same unit (Millions)
	
	EXEC SP_DROPTABLE 'B04_00_TT_COMPANY_VALUE_CONVERTED'
	SELECT
	*,
	CASE
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Billions' THEN Col1*1000
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Millions' THEN Col1
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Millions of Yen' THEN Col1
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Thousands' THEN Col1*1000/1000000
		ELSE Col1
	END AS ZF_COL1_CONVERTED,
	CASE
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Billions' THEN Col2*1000
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Millions' THEN Col2
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Millions of Yen' THEN Col2
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Thousands' THEN Col2*1000/1000000
		ELSE Col2
	END AS ZF_COL2_CONVERTED,
	CASE
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Billions' THEN Col3*1000
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Millions' THEN Col3
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Millions of Yen' THEN Col3
		WHEN Z_Category_Reclassified NOT LIKE '1.%' AND Unit = 'Thousands' THEN Col3*1000/1000000
		ELSE Col3
	END AS ZF_COL3_CONVERTED,
	CASE 
		WHEN Unit = 'Millions of Yen'  THEN 'Millions of Yen'
		ELSE 'Millions'
		END AS ZF_UNIT
	INTO B04_00_TT_COMPANY_VALUE_CONVERTED
	FROM B04_COMPANY_DATA_FINAL_2025

	SELECT * FROM B04_00_TT_COMPANY_VALUE_CONVERTED

-- Step 1: Create a table that contains only the first index of each company

	EXEC SP_DROPTABLE 'B04_01_TT_COMPANY_DATA_LATEST_INDEX'
	SELECT
			B04_00_TT_COMPANY_VALUE_CONVERTED.[Index],
			B04_00_TT_COMPANY_VALUE_CONVERTED.[Company name], 
			Link,
			Z_Category_Reclassified,
			Col1 AS Date1,
			LEAD(ZF_COL1_CONVERTED,1,0) OVER(PARTITION BY B04_00_TT_COMPANY_VALUE_CONVERTED.[Company name], [Link] ORDER BY Z_Category_Reclassified) AS ZF_NET_INCOME1,
			LEAD(ZF_COL1_CONVERTED,2,0) OVER(PARTITION BY B04_00_TT_COMPANY_VALUE_CONVERTED.[Company name], [Link] ORDER BY Z_Category_Reclassified) AS ZF_INCOME_TAXES1,
			Col2 AS Date2,
			LEAD(ZF_COL2_CONVERTED,1,0) OVER(PARTITION BY B04_00_TT_COMPANY_VALUE_CONVERTED.[Company name], [Link] ORDER BY Z_Category_Reclassified) AS ZF_NET_INCOME2,
			LEAD(ZF_COL2_CONVERTED,2,0) OVER(PARTITION BY B04_00_TT_COMPANY_VALUE_CONVERTED.[Company name], [Link] ORDER BY Z_Category_Reclassified) AS ZF_INCOME_TAXES2,
			Col3 AS Date3,
			LEAD(ZF_COL3_CONVERTED,1,0) OVER(PARTITION BY B04_00_TT_COMPANY_VALUE_CONVERTED.[Company name], [Link] ORDER BY Z_Category_Reclassified) AS ZF_NET_INCOME3,
			LEAD(ZF_COL3_CONVERTED,2,0) OVER(PARTITION BY B04_00_TT_COMPANY_VALUE_CONVERTED.[Company name], [Link] ORDER BY Z_Category_Reclassified) AS ZF_INCOME_TAXES3,
			ZF_UNIT
	INTO B04_01_TT_COMPANY_DATA_LATEST_INDEX
	FROM B04_00_TT_COMPANY_VALUE_CONVERTED
	INNER JOIN 
	(
		SELECT [Company name], MIN([Index]) AS ZF_MIN_INDEX_PER_COMPANY
		FROM B04_00_TT_COMPANY_VALUE_CONVERTED
		GROUP BY [Company name]
	) A
	ON B04_00_TT_COMPANY_VALUE_CONVERTED.[Index] = A.ZF_MIN_INDEX_PER_COMPANY
	AND B04_00_TT_COMPANY_VALUE_CONVERTED.[Company name] = A.[Company name]

-- Step 2: Pivot the first-index table while selecting only the first rows of each company as they contains the correct Date, Net income, Income taxes

	EXEC SP_DROPTABLE 'B04_02_TT_COMPANY_DATA_FIRST_INDEX_PIVOT'
	SELECT	[Index], [Company name], [Link], Date1 AS [Date], 
			ZF_NET_INCOME1 AS ZF_NET_INCOME, 
			ZF_INCOME_TAXES1 AS ZF_INCOME_TAXES,
			ZF_UNIT
	INTO B04_02_TT_COMPANY_DATA_FIRST_INDEX_PIVOT
	FROM B04_01_TT_COMPANY_DATA_LATEST_INDEX
	WHERE Z_Category_Reclassified = '1. Date'

	UNION

	SELECT	[Index], [Company name], [Link], Date2, ZF_NET_INCOME2, ZF_INCOME_TAXES2, ZF_UNIT
	FROM B04_01_TT_COMPANY_DATA_LATEST_INDEX
	WHERE Z_Category_Reclassified = '1. Date'

	UNION

	SELECT [Index], [Company name], [Link], Date3, ZF_NET_INCOME3, ZF_INCOME_TAXES3, ZF_UNIT
	FROM B04_01_TT_COMPANY_DATA_LATEST_INDEX
	WHERE Z_Category_Reclassified = '1. Date'
	ORDER BY [Index], [Company name], [Date]


-- Step 3: Create a table with the non-first index of each company

	EXEC SP_DROPTABLE 'B04_03_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX'
	SELECT 
		[Index],
		[Company name],
		[Link],
		[Category],
		[Z_Category_Reclassified],
		ZF_COL3_CONVERTED, -- Take only Col3
		ZF_UNIT
	INTO B04_03_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX
	FROM B04_00_TT_COMPANY_VALUE_CONVERTED A
	WHERE NOT EXISTS 
	(
	SELECT 
	1 FROM B04_01_TT_COMPANY_DATA_LATEST_INDEX B WHERE A.[Index] = B.[Index] AND A.[Company name] = B.[Company name]
	)

-- Step 4: Create a pivot table for Net income, Income taxes with the non-first index

	EXEC SP_DROPTABLE 'B04_04_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX_PIVOT'
	SELECT DISTINCT 
	A.[Index],
	A.[Company Name],
	A.[Link],
	B.ZF_COL3_CONVERTED AS ZF_DATE,
	C.ZF_COL3_CONVERTED AS ZF_NET_INCOME,
	D.ZF_COL3_CONVERTED AS ZF_INCOME_TAXES,
	A.ZF_UNIT
	INTO B04_04_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX_PIVOT
	FROM B04_03_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX A
	LEFT JOIN  -- Take Dates
	(
		SELECT DISTINCT [Index], [Company Name], ZF_COL3_CONVERTED
		FROM B04_03_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX 
		WHERE Z_Category_Reclassified = '1. Date'
	) B
	ON A.[Index] =  B.[Index]
	AND A.[Company name] = B.[Company name]
	LEFT JOIN  -- Take Net income
	(
		SELECT DISTINCT [Index], [Company Name], ZF_COL3_CONVERTED
		FROM B04_03_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX 
		WHERE Z_Category_Reclassified = '2. Net income (loss)'
	) C
	ON A.[Index] =  C.[Index]
	AND A.[Company name] = C.[Company name]
	LEFT JOIN  -- Take Income taxes
	(
		SELECT DISTINCT [Index], [Company Name], ZF_COL3_CONVERTED
		FROM B04_03_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX 
		WHERE Z_Category_Reclassified = '3. Cash paid (received) for income taxes'
	) D
	ON A.[Index] =  D.[Index]
	AND A.[Company name] = D.[Company name]


-- Step 5: Combine the first-index table with the non-first index table
	
	EXEC SP_DROPTABLE 'B04_05_IT_COMPANY_DATA_PIVOT_FINAL'
	
	SELECT DISTINCT *
	INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL
	FROM B04_02_TT_COMPANY_DATA_FIRST_INDEX_PIVOT
	UNION 
	SELECT DISTINCT *	
	FROM B04_04_TT_COMPANY_DATA_EXCLUDE_FIRST_INDEX_PIVOT
	ORDER BY [Index] 

-- Insert into the final table the values of Sony

	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2258,'SONY CORP', 2009, -1767, 2450, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2259,'SONY CORP', 2010, 272, 606, 'Millions')	

	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2260,'SONY CORP', 2011, 2071, 1175, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2261,'SONY CORP', 2012, -817, 1289, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2262,'SONY CORP', 2013, 2445, 919, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2263,'SONY CORP', 2014, 260, 1021, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2264,'SONY CORP', 2015, 401, 988, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2265,'SONY CORP', 2016, 3076, 1402, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2266,'SONY CORP', 2017, 2542, 1071, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2267,'SONY CORP', 2018, 7061, 1021, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2268,'SONY CORP', 2019, 10219, 2126, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2269,'SONY CORP', 2020, 8076, 2191, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2270,'SONY CORP', 2021, 12044, 1203, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2271,'SONY CORP', 2022, 11288, 2726, 'Millions')	
	
	INSERT INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL ([Index], [Company name], Date, ZF_NET_INCOME, ZF_INCOME_TAXES,ZF_UNIT)
	VALUES (2272,'SONY CORP', 2023, 12815, 2970, 'Millions')

-- Update to add effective tax rates, effective tax rate buckets and additional flags

	ALTER TABLE B04_05_IT_COMPANY_DATA_PIVOT_FINAL -- Calculate effective tax rates
	ADD  ZF_EFFECTIVE_TAX_RATE FLOAT

	UPDATE B04_05_IT_COMPANY_DATA_PIVOT_FINAL 
	SET ZF_EFFECTIVE_TAX_RATE =
		CASE WHEN ZF_INCOME_TAXES <> '' OR ZF_INCOME_TAXES <> 0 THEN ROUND(100*ZF_INCOME_TAXES / ZF_NET_INCOME,2)
		ELSE NULL END
	
	ALTER TABLE B04_05_IT_COMPANY_DATA_PIVOT_FINAL -- Create buckets of effective tax rates
	ADD  ZF_EFFECTIVE_TAX_RATE_BUCKETS NVARCHAR(255)

	UPDATE B04_05_IT_COMPANY_DATA_PIVOT_FINAL 
	SET ZF_EFFECTIVE_TAX_RATE_BUCKETS =
		CASE 
		WHEN ZF_EFFECTIVE_TAX_RATE < -500 THEN '1. Under -500%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN -500 AND -250 THEN '2. From -500% to -250%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN -250 AND -100 THEN '3. From -250 to -100%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN -100 AND -50 THEN '4. From -100% to -50%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN -50 AND 0 THEN '5. From -50% to 0%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN 0 AND 25 THEN '6. From 0% to 25%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN 25 AND 50 THEN '7. From 25% to 50%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN 50 AND 75 THEN '8. From 50% to 75%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN 75 AND 100 THEN '9. From 75% to 100%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN 100 AND 250 THEN '10. From 100% to 250%'
		WHEN ZF_EFFECTIVE_TAX_RATE BETWEEN 250 AND 500 THEN '10. From 250% to 500%'
		WHEN ZF_EFFECTIVE_TAX_RATE > 500 THEN '11. Over 500%'
		ELSE '0. Undefined Tax Rate' END


		ALTER TABLE B04_05_IT_COMPANY_DATA_PIVOT_FINAL -- Flag if Net income is negative
		ADD  ZF_NET_INCOME_NEG NVARCHAR(3)
		
		UPDATE B04_05_IT_COMPANY_DATA_PIVOT_FINAL 
		SET ZF_NET_INCOME_NEG = 'No'
		UPDATE B04_05_IT_COMPANY_DATA_PIVOT_FINAL 
		SET ZF_NET_INCOME_NEG = 'Yes'
		WHERE ZF_NET_INCOME < 0

		ALTER TABLE B04_05_IT_COMPANY_DATA_PIVOT_FINAL -- Flag if income tax is negative
		ADD  ZF_INCOME_TAX_NEG NVARCHAR(3)

		UPDATE B04_05_IT_COMPANY_DATA_PIVOT_FINAL 
		SET ZF_INCOME_TAX_NEG = 'No'
		UPDATE B04_05_IT_COMPANY_DATA_PIVOT_FINAL 
		SET ZF_INCOME_TAX_NEG = 'Yes'
		WHERE ZF_INCOME_TAXES < 0

	-- Create SONY CORP table	

		EXEC SP_DROPTABLE 'B04_05_IT_COMPANY_DATA_PIVOT_FINAL_SONY'
        SELECT *
        INTO B04_05_IT_COMPANY_DATA_PIVOT_FINAL_SONY
        FROM B04_05_IT_COMPANY_DATA_PIVOT_FINAL
        WHERE [Company name] = 'SONY CORP'


        DELETE FROM B04_05_IT_COMPANY_DATA_PIVOT_FINAL
        WHERE [Company name] = 'SONY CORP' 

		EXEC sp_RENAME_FIELD 'SONY_', 'B04_05_IT_COMPANY_DATA_PIVOT_FINAL_SONY' 
GO
