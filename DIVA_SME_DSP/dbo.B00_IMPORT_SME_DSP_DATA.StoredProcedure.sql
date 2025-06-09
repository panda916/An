USE [DIVA_SME_DSP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROC [dbo].[B00_IMPORT_SME_DSP_DATA] 
AS
/*

-- Step 1 / Create SME DSP with record type is N
DROP TABLE DSP_N
CREATE TABLE DSP_N
(

[Record Type] NVARCHAR(10),
[Provider Key] NVARCHAR(10),
[Client Key] NVARCHAR(10),
[Report Start Date] DATE,
[Report End Date] DATE,
[Vendor Name] NVARCHAR(1000),
[Vendor Key] NVARCHAR(10),
[Country Key] NVARCHAR(10),
[Sales Type Key] NVARCHAR(10),
[External Id] NVARCHAR(1000),
[UPC (Physical Album Product)] NVARCHAR(1000),
[Official SME Product #] NVARCHAR(1000),
[ISRC/Official Track #] NVARCHAR(1000),
[GRID/Official Digital ID] NVARCHAR(1000),
[Product Type Key] NVARCHAR(1000),
[Gross Units] FLOAT,
[Returned Units] FLOAT,
[WPU (Wholesale Price per Unit)] FLOAT,
[WPU Currency] NVARCHAR(10),
[Net Invoice Price] FLOAT, 
[RPU (Retail Price per Unit)] FLOAT,
[RPU Currency] NVARCHAR(1000),
[VAT/TAX] FLOAT,
[VAT/TAX Currency] NVARCHAR(1000),
[Copyright Indicator] NVARCHAR(1000),
[Distribution Type Key] NVARCHAR(1000),
[Transaction Type Key] NVARCHAR(1000),
[Service Type Key] NVARCHAR(1000),
[Participant Full Name] NVARCHAR(1000),
[Product Title] NVARCHAR(1000),
[Track Title] NVARCHAR(1000),
[Media Key] NVARCHAR(1000), 
[Campaign ID] NVARCHAR(1000),
[Customer ID*] NVARCHAR(1000),
[Customer Date of Birth*] NVARCHAR(1000),
[Customer Gender*] NVARCHAR(1000),
[Customer Zip Code + 4*] NVARCHAR(1000),
[Order ID*] NVARCHAR(1000), 
[Transaction Date*] DATE,
Z_FileName nvarchar(1000)

)


select DISTINCT * 

from  DSP_N	
WHERE Z_FileName = 'PTK8_M_20200301_20200331.txt'


-- Step 1 / Create SME DSP with record type is N
DROP TABLE DSP_A

CREATE TABLE DSP_A
(

[Record Type] NVARCHAR(10),
[Provider Key] NVARCHAR(10),
[Report start date] DATE,
[Report end date] DATE,
[Column1]  NVARCHAR(1000),
[Column2]  NVARCHAR(1000),
Z_FileName NVARCHAR(1000)


)


DROP TABLE DSP_M
CREATE TABLE DSP_M
(

[Record Type] NVARCHAR(10),
[Provider Key] NVARCHAR(10),
[Client Key] NVARCHAR(10),
[Report Start Date] DATE,
[Report End Date] DATE,
[Vendor Name] NVARCHAR(1000),
[Vendor Key] NVARCHAR(10),
[Country Key] NVARCHAR(10),
[Column1] FLOAT,
[Column2] FLOAT,
Z_FileName NVARCHAR(1000)
)

DROP TABLE DSP_M
CREATE TABLE DSP_M
(

[Record Type] NVARCHAR(10),
[Provider Key] NVARCHAR(10),
[Client Key] NVARCHAR(10),
[Report Start Date] DATE,
[Report End Date] DATE,
[Vendor Name] NVARCHAR(1000),
[Vendor Key] NVARCHAR(10),
[Country Key] NVARCHAR(10),
[Column1] FLOAT,
[Column2] FLOAT,
Z_FileName NVARCHAR(1000)
)



DROP TABLE DSP_Z
CREATE TABLE DSP_Z
(

[Record Type] NVARCHAR(10),
[Provider Key] NVARCHAR(10),
[Report Start Date] DATE,
[Report End Date] DATE,

[Z_NUMBER_OF_RECORD] INT,

[Column1] FLOAT,
[Column2] FLOAT,
[Column3] FLOAT,
[Column4] FLOAT,
[Column5] FLOAT,

Z_FileName NVARCHAR(1000)
)



SELECT 
	DISTINCT  [P roduct Title],
	[Gross Units],
		[WPU (Wholesale Price per Unit)],
		*
 FROM DSP_N
WHERE [Participant Full Name] = '*NSYNC' and [Track Title] = '(God Must Have Spent) A Little More Time On You'



ALTER TABLE DSP_N ADD ZF_SINGER_SONG_MANY_PRICE_FLAG nvarchar(3);


UPDATE DSP_N
SET ZF_SINGER_SONG_MANY_PRICE_FLAG = 'No'

UPDATE DSP_N
SET ZF_SINGER_SONG_MANY_PRICE_FLAG = 'Yes'
FROM DSP_N
WHERE [Participant Full Name]+[Track Title]+[Vendor Name] IN
(

	SELECT 
	DISTINCT 
		[Participant Full Name]+[Track Title]+[Vendor Name]
	FROM DSP_N
	GROUP BY [Participant Full Name], [Track Title], [Vendor Name]
	HAVING COUNT(DISTINCT [WPU (Wholesale Price per Unit)]) > 1
	

)

select 
ZF_SINGER_SONG_MANY_PRICE_FLAG , count(*) 
from DSP_N
group by ZF_SINGER_SONG_MANY_PRICE_FLAG




SELECT
DISTINCT 
	[Service Type Key]
FROM DSP_N

-- 1703

SELECT  DISTINCT
	[Total # of Users ] * [Rate Card] , [Final Calc Check] , 
	[Total # of Users ] * [Rate Card] - [Final Calc Check] ,

	[Total plays for SME Content] AS AB,
	[Total plays across all content providers] AS AA,
	[Total plays for SME Content] / [Total plays across all content providers],
	*

FROM [Equinox Media (PTK8) Rollup]
WHERE [Vendor Key] = 'PTV2'
AND [Total plays for SME Content] <> [Total plays across all content providers]


-- 
ALTER TABLE [Equinox Media (PTK8) Rollup] ADD ZF_REVENUE_CAL FLOAT

SME Market Share by usage
100



UPDATE [Equinox Media (PTK8) Rollup]
SET ZF_REVENUE_CAL =

CASE 
	WHEN 	CAST([Total plays for SME Content] AS FLOAT) / 	IIF( CAST([Total plays across all content providers] AS FLOAT) = 0 , 1,CAST([Total plays across all content providers] AS FLOAT)) > ([SME Market Share by usage] / 100)
		THEN [Total # of Users ] * 
				AM_RATE_MAPPING.ZF_RATE_NUMBER * 
				(CAST([Total plays for SME Content] AS FLOAT) / CAST([Total plays across all content providers] AS FLOAT))
	ELSE [Total # of Users ] * AM_RATE_MAPPING.ZF_RATE_NUMBER * ([SME Market Share by usage] / 100)
END
		
FROM [Equinox Media (PTK8) Rollup]
INNER JOIN AM_RATE_MAPPING ON [Equinox Media (PTK8) Rollup].[Vendor Key] = AM_RATE_MAPPING.VENDOR_KEY


SELECT 
	[Reporting Start Date],
	[Reporting End Date],
	[Vendor Key],
	[VENDOR NAME],
	[Total # of Users ],
	[Rate Card Rev],
	[Final Calc Check],

	[Total plays for SME Content],
	[Total plays across all content providers],
	[SME Market Share by usage]

FROM [Equinox Media (PTK8) Rollup]
WHERE 
[Total plays for SME Content] <> [Total plays across all content providers]



SELECT 
	[Reporting Start Date],
	[Reporting End Date],
	[Vendor Key],
	[VENDOR NAME],
	[Total # of Users ],
	[Rate Card Rev],
	[Final Calc Check],

	[Total plays for SME Content],
	[Total plays across all content providers],
	[SME Market Share by usage]

FROM [Equinox Media (PTK8) Rollup]
INNER JOIN AM_RA
WHERE 
[Total plays for SME Content] = [Total plays across all content providers]




WHERE [Vendor Key] NOT IN (SELECT DISTINCT VENDOR_KEY FROM AM_RATE_MAPPING)




SELECT 
DISTINCT 
	[SME Market Share by usage] / 100

FROM	[Equinox Media (PTK8) Rollup]


SELECT DISTINCT [Total plays for SME Content]
FROM [Equinox Media (PTK8) Rollup]
WHERE [Total plays across all content providers] = 0 



CREATE TABLE AM_RATE_MAPPING
(
	VENDOR_KEY NVARCHAR(10),
	ZF_RATE_NUMBER FLOAT
		
)



SELECT 
*
FROM DSP_N
WHERE [Report Start Date] = '20200301'
AND [Report End Date] = '2020-03-31'


SELECT 3150 * 1.25

select 
*
FROM DSP_M
WHERE Z_FileName = 'PTK8_M_20200301_20200331.txt'

-- Equinox - Equinox Users (Below 50%)

SELECT
DISTINCT 
	[Vendor Key],
	[Vendor Name]

FROM DSP_N



SELECT 
DISTINCT 
	[Participant Full Name]+[Track Title]+[Vendor Name]+CAST([Gross Units] AS NVARCHAR),DATEDIFF( D,MIN([Report Start Date]), MAX([Report Start Date]))
	, [Participant Full Name], [Track Title], [Vendor Name]
	, MAX([WPU (Wholesale Price per Unit)]) - MIN([WPU (Wholesale Price per Unit)]),
	 MAX([Gross Units] * [WPU (Wholesale Price per Unit)]) - MIN([Gross Units] * [WPU (Wholesale Price per Unit)])
FROM DSP_N
where [Gross Units] > 50
GROUP BY [Participant Full Name], [Track Title], [Vendor Name], [Gross Units]
HAVING COUNT(DISTINCT [WPU (Wholesale Price per Unit)]) > 1
AND DATEDIFF( D,MIN([Report Start Date]), MAX([Report Start Date])) < 40

order by   MAX([Gross Units] * [WPU (Wholesale Price per Unit)]) - MIN([Gross Units] * [WPU (Wholesale Price per Unit)]) DESC




-- Christina AguileraBeautifulEquinox - Enterprise Users1

SELECT 
	[Participant Full Name], [Track Title], [Gross Units], [WPU (Wholesale Price per Unit)], [Report Start Date]
FROM DSP_N
GROUP BY [Participant Full Name], [Track Title], [Gross Units], [WPU (Wholesale Price per Unit)], [Report Start Date]
HAVING COUNT(DISTINCT Z_FileName) > 1


SELECT 
[Participant Full Name],
[Track Title],
[Vendor Name],
[Report Start Date],
[Order ID*],
[Gross Units],
[WPU (Wholesale Price per Unit)],
[Net Invoice Price]
FROM DSP_N
WHERE [Participant Full Name]+[Track Title] in
(
	SELECT 
	DISTINCT 
		[Participant Full Name]+[Track Title]
	FROM DSP_N
	GROUP BY [Participant Full Name], [Track Title]
	HAVING COUNT(DISTINCT [WPU (Wholesale Price per Unit)]) > 1

)
ORDER BY [Participant Full Name],
[Track Title],
[Vendor Name],
[Gross Units]


-- Add 1 



SELECT
 [REPOR]
FROM [Equinox Media (PTK8) Rollup]


SELECT 
	DISTINCT 
	


CASE 
	WHEN 	CAST([Total plays for SME Content] AS FLOAT) / 	IIF( CAST([Total plays across all content providers] AS FLOAT) = 0 , 1,CAST([Total plays across all content providers] AS FLOAT)) > ([SME Market Share by usage] / 100)
		THEN [Total # of Users ] * 
				AM_RATE_MAPPING.ZF_RATE_NUMBER * 
				(CAST([Total plays for SME Content] AS FLOAT) / CAST([Total plays across all content providers] AS FLOAT))
	ELSE [Total # of Users ] * AM_RATE_MAPPING.ZF_RATE_NUMBER * ([SME Market Share by usage] / 100)
END
		
FROM [Equinox Media (PTK8) Rollup]
INNER JOIN AM_RATE_MAPPING ON [Equinox Media (PTK8) Rollup].[Vendor Key] = AM_RATE_MAPPING.VENDOR_KEY




UPDATE [Equinox Media (PTK8) Rollup]
SET ZF_REVENUE_CAL =

CASE 
	WHEN 	CAST([Total plays for SME Content] AS FLOAT) / 	IIF( CAST([Total plays across all content providers] AS FLOAT) = 0 , 1,CAST([Total plays across all content providers] AS FLOAT)) > ([SME Market Share by usage] / 100)
		THEN [Total # of Users ] * 
				AM_RATE_MAPPING.ZF_RATE_NUMBER * 
				(CAST([Total plays for SME Content] AS FLOAT) / CAST([Total plays across all content providers] AS FLOAT))
	ELSE [Total # of Users ] * AM_RATE_MAPPING.ZF_RATE_NUMBER * ([SME Market Share by usage] / 100)
END
		
FROM [Equinox Media (PTK8) Rollup]
INNER JOIN AM_RATE_MAPPING ON [Equinox Media (PTK8) Rollup].[Vendor Key] = AM_RATE_MAPPING.VENDOR_KEY






UPDATE [Equinox Media (PTK8) Rollup]
SET ZF_REVENUE_CAL = 

CASE 
	WHEN 	
	CAST([Total plays for SME Content] AS FLOAT) 
		/ 	
	IIF( CAST([Total plays across all content providers] AS FLOAT) = 0 , 1,CAST([Total plays across all content providers] AS FLOAT))
	> 0.4
	THEN [Total # of Users ] *  AM_RATE_MAPPING.ZF_RATE_NUMBER * 
		(
			CAST([Total plays for SME Content] AS FLOAT) 
			/ 	
			IIF( CAST([Total plays across all content providers] AS FLOAT) = 0 , 1,CAST([Total plays across all content providers] AS FLOAT))
		)
	ELSE [Total # of Users ] * AM_RATE_MAPPING.ZF_RATE_NUMBER * (0.4)
END
		
FROM [Equinox Media (PTK8) Rollup]
INNER JOIN AM_RATE_MAPPING ON [Equinox Media (PTK8) Rollup].[Vendor Key] = AM_RATE_MAPPING.VENDOR_KEY


SELECT
DISTINCT 
	[Vendor Key]
FROM [Equinox Media (PTK8) Rollup]

ALTER TABLE [Equinox Media (PTK8) Rollup] ADD ZF_REPORT_START_DATE DATE
ALTER TABLE [Equinox Media (PTK8) Rollup] ADD ZF_REPORT_END_DATE DATE


SELECT DISTINCT ZF_REPORT_START_DATE FROM [Equinox Media (PTK8) Rollup]

UPDATE [Equinox Media (PTK8) Rollup]
SET ZF_REPORT_START_DATE = CONVERT(DATE, CONVERT(VARCHAR(8), CAST([Reporting Start Date] AS BIGINT)), 112)



UPDATE [Equinox Media (PTK8) Rollup]
SET ZF_REPORT_END_DATE = CONVERT(DATE, CONVERT(VARCHAR(8), CAST([Reporting End Date] AS BIGINT)), 112)


SELECT 
DISTINCT 
	ZF_REVENUE_CAL,
	[Final Calc Check]

FROM [Equinox Media (PTK8) Rollup]
WHERE ZF_REVENUE_CAL <> [Final Calc Check]


ALTER TABLE [Equinox Media (PTK8) Rollup] ADD ZF_NUMBER_MIN_PER_SONG FLOAT
ALTER TABLE [Equinox Media (PTK8) Rollup] ADD ZF_TOTAL_QUANTITY FLOAT


UPDATE [Equinox Media (PTK8) Rollup]
SET ZF_NUMBER_MIN_PER_SONG = 	[Total # of Users ] * [Average minutes delivered per User ]  / B.Quantity
FROM [Equinox Media (PTK8) Rollup] A
INNER JOIN (
SELECT 
	[Vendor Key], 
	YEAR([Report Start Date]) AS ZF_YEAR, 
	MONTH([Report Start Date]) AS ZF_MONTH,
	SUM([Gross Units]) AS Quantity
FROM DSP_N
GROUP BY [Vendor Key], YEAR([Report Start Date]), MONTH([Report Start Date])
) B ON A.[Vendor Key] = B.[Vendor Key]
AND YEAR(A.ZF_REPORT_START_DATE) = B.ZF_YEAR
AND MONTH(A.ZF_REPORT_START_DATE) = B.ZF_MONTH



UPDATE [Equinox Media (PTK8) Rollup]
SET ZF_TOTAL_QUANTITY = 	 B.Quantity
FROM [Equinox Media (PTK8) Rollup] A
INNER JOIN (
SELECT 
	[Vendor Key], 
	YEAR([Report Start Date]) AS ZF_YEAR, 
	MONTH([Report Start Date]) AS ZF_MONTH,
	SUM([Gross Units]) AS Quantity
FROM DSP_N
GROUP BY [Vendor Key], YEAR([Report Start Date]), MONTH([Report Start Date])
) B ON A.[Vendor Key] = B.[Vendor Key]
AND YEAR(A.ZF_REPORT_START_DATE) = B.ZF_YEAR
AND MONTH(A.ZF_REPORT_START_DATE) = B.ZF_MONTH


SELECT 
*
FROM [Equinox Media (PTK8) Rollup]
WHERE ZF_TOTAL_QUANTITY IS NULL 


SELECT
[Total # of Users ] * [Average minutes delivered per User ]  / B.Quantity
FROM [Equinox Media (PTK8) Rollup] A
INNER JOIN (
SELECT 
	[Vendor Key], 
	YEAR([Report Start Date]) AS ZF_YEAR, 
	MONTH([Report Start Date]) AS ZF_MONTH,
	SUM([Gross Units]) AS Quantity
FROM DSP_N
where  Z_FileName = 'PTK8_M_20200301_20200331.txt'
GROUP BY [Vendor Key], YEAR([Report Start Date]), MONTH([Report Start Date])
) B ON A.[Vendor Key] = B.[Vendor Key]
AND YEAR(A.ZF_REPORT_START_DATE) = B.ZF_YEAR
AND MONTH(A.ZF_REPORT_START_DATE) = B.ZF_MONTH





SELECT 
SUM([Gross Units]),
[Vendor Key],
[Vendor Name]
FROM DSP_N
WHERE Z_FileName = 'PTK8_M_20211101_20211130.txt'
GROUP BY [Vendor Key],
[Vendor Name]

-- 77614

SELECT [Total # of Users ] * [Average minutes delivered per User ] / 77614
FROM [Equinox Media (PTK8) Rollup]
WHERE YEAR(ZF_REPORT_START_DATE)  = 2021 AND MONTH(ZF_REPORT_START_DATE) = 11
AND [Vendor Key] = 'PTV2'

EXEC SP_RENAME_FIELD 'Equinox_', 'Equinox Media (PTK8) Rollup'

Equinox_ZF_REPORT_START_DATE

Equinox_Vendor Key


PTV2
2020-03-01
SELECT * FROM [Equinox Media (PTK8) Rollup]


SELECT *
FROM DSP_N

Report Start Date
2020-03-01

SELECT DISTINCT *
FROM DSP_A

[Report Start Date]&[Vendor Key]

Vendor Key
PTV2

*NSYNC	Bye Bye Bye	Equinox - Equinox Users (Below 50%)	2020-10-01		233	1.6968087009	1.6968087009
*NSYNC	Bye Bye Bye	Equinox - Equinox Users (Below 50%)	2021-03-01		357	0.6571645756	0.6571645756
*NSYNC	Bye Bye Bye	Equinox - Equinox Users (Below 50%)	2020-11-01		399	1.6362759366	1.6362759366

*/
GO
