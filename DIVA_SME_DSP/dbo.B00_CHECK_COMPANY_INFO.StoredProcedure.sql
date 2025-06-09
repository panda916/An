USE [DIVA_SME_DSP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROC [dbo].[B00_CHECK_COMPANY_INFO] 
AS

-- Step 1 / Create table to store pdf file


DROP TABLE IF EXISTS B01_DATA_PDF_FILE
SELECT 
	*
INTO B01_DATA_PDF_FILE
FROM PDF_FILE1
where STT BETWEEN 1 AND 23

-- Step 2 / Create table to store pdf update file

DROP TABLE IF EXISTS B01_DATA_PDF_FILE_UPDATE
SELECT 
ROW_NUMBER() OVER (PARTITION BY [PDF Name] ORDER BY CAST( ROW AS int) asc) as ROWID,
CAST( A.ROW AS int) AS ZF_ROW_LINE,
CAST (A.STT AS INT) AS STT,
DATA_SEC_GOV.[Company name],
DATA_SEC_GOV.Link,
DATA_SEC_GOV.[PDF Name],
Category,
Col1,
Col2,
Col3
INTO B01_DATA_PDF_FILE_UPDATE
FROM B01_DATA_PDF_FILE A
	INNER JOIN DATA_SEC_GOV
		ON A.STT = DATA_SEC_GOV.STT

-- Step 3 / Create table to store net income and tax 
-- 3.1 Apple Inc. (AAPL) : 69 records check with jesper STT 19,20,21

SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL, 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	IIF(STT IN (19,20,21), 'Y','') Check_with_Jesper
INTO B03_COMPANY_DATA_CHECK
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Apple Inc. (AAPL)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes'
		)
	OR ROWID = 1
)
ORDER BY STT


-------------------- 3.2 Nvidia_Corp_(NVDA)
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Nvidia Corp (NVDA)' AND [Txt file ?] IS NULL



SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL, 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Nvidia Corp (NVDA)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net'
		)
	OR ROWID = 1
)
ORDER BY STT


--- 3.3   Microsoft Corp (MSFT)
-- 23 RECORDS.

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL, 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'No tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Microsoft Corp (MSFT)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net'
		)
	OR ROWID = 1
)
ORDER BY STT

-- ---------------------------------------3.4 AMAZON COM INC (AMZN) (CIK 0001018724)
-- 22 records-
-- Ok with no tax need to check with Jesper

-- 73 TO 94 : 22
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'AMAZON COM INC (AMZN) (CIK 0001018724)'

DELETE FROM B03_COMPANY_DATA_CHECK
WHERE [Company name] = 'AMAZON COM INC (AMZN) (CIK 0001018724)'

INSERT INTO B01_DATA_PDF_FILE
SELECT * FROM [AMAZON_COM_INC_(AMZN)_(CIK_0001018724) (1)]

UNION
SELECT * FROM [AMAZON_COM_INC_(AMZN)_(CIK_0001018724)_TAX (1)]
WHERE STT < 77

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 73 AND 94

SELECT * FROM [AMAZON_COM_INC_(AMZN)_(CIK_0001018724) (1)]
WHERE STT = 86

-- 77,



INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL or Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'Cash paid for income taxes, net of refunds' Check_with_Jesper

FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'AMAZON COM INC (AMZN) (CIK 0001018724)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaidforincometaxes(netofrefunds)',
		'Cashpaidforincometaxes,netofrefunds',
		'Cashpaidforincometaxes'
		)
	OR ROWID = 1
)
ORDER BY STT

INSERT INTO B03_COMPANY_DATA_CHECK VALUES
(4,77,75,'AMAZON COM INC (AMZN) (CIK 0001018724)','https://www.sec.gov/Archives/edgar/data/1018724/000101872422000005/amzn-20211231.htm'
,'Cash paid for income taxes, net of refunds','881' ,'1713','3688','Cash paid for income taxes, net of refunds'

)


-- 3.5 Meta Platforms, Inc. (META) (CIK 0001326801)
-- 3 records
INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 95 AND 97
UNION 
SELECT *
FROM [Meta_Platforms,_Inc._(META)_(CIK_0001326801)_TAX]

UPDATE  [Meta_Platforms,_Inc._(META)_(CIK_0001326801)_TAX]
SET Column_1 = 10000 + Column_1

SELECT *
FROM [Meta_Platforms,_Inc._(META)_(CIK_0001326801)_TAX]
WHERE STT BETWEEN 95 AND 97


SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Meta Platforms, Inc. (META) (CIK 0001326801)'


DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 95 AND 97

DELETE FROM B03_COMPANY_DATA_CHECK
WHERE STT BETWEEN 95 AND 97 

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL or Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'Need to add tax tax table' Check_with_Jesper

FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Meta Platforms, Inc. (META) (CIK 0001326801)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes'
		)
	OR ROWID = 1
)
ORDER BY STT

------------------------- 3.7 Alphabet Inc. (GOOG, GOOGL) (CIK 0001652044)
-- 0 record.

SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL or Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'No tax' Check_with_Jesper

FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Alphabet Inc. (GOOG, GOOGL) (CIK 0001652044)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes'
		)
	OR ROWID = 1
)
ORDER BY STT

-- 3.8 BERKSHIRE_HATHAWAY_INC_(BRK-B,_BRK-A)_(CIK_0001067983)_TAX
-- 22

DELETE FROM B03_COMPANY_DATA_CHECK
WHERE [Company name] = 'BERKSHIRE HATHAWAY INC (BRK-B, BRK-A) (CIK 0001067983)'

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL or Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'K91' Check_with_Jesper

FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'BERKSHIRE HATHAWAY INC (BRK-B, BRK-A) (CIK 0001067983)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Netearnings(loss)'
		)
	OR ROWID = 1
)
ORDER BY STT






------------------------ 3.9 Eli Lilly & Co. (LLY)
-- 23 RECORDS
INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 144 AND 166

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL, 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'Check with Jesper about table contain tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Eli Lilly & Co. (LLY)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net'
		)
	OR ROWID = 1
)
ORDER BY STT


-- 3.10 Broadcom Inc. (AVGO)
-- 6 RECORDS
-- 167 TO 172

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 167 AND 172

SELECT 
*
FROM DATA_SEC_GOV
WHERE [Company name] = 'Broadcom Inc. (AVGO)'

INSERT INTO B03_COMPANY_DATA_CHECK 
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'Check with Jesper about table contain tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Broadcom Inc. (AVGO)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes'
		)
	OR ROWID = 1
)
ORDER BY STT

-- 3.11 Jpmorgan Chase & Co. (JPM)
-- 173 TO 217
-- 31

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Jpmorgan Chase & Co. (JPM)' AND [Txt file ?]  IS NULL

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 173 AND 217


INSERT INTO B03_COMPANY_DATA_CHECK 
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Jpmorgan Chase & Co. (JPM)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)'
		)
	OR ROWID = 1
)
ORDER BY STT

-- 3.12 Tesla, Inc. (TSLA)

select *
FROM DATA_SEC_GOV
WHERE [Company name] LIKE '%TESLA%'





-- 3.13 UNITEDHEALTH GROUP INC (UNH) (CIK 0000731766)
-- 220 AND 244



SELECT 
*
FROM DATA_SEC_GOV
WHERE [Company name] = 'UNITEDHEALTH GROUP INC (UNH) (CIK 0000731766)'


-- INSERT INTO B03_COMPANY_DATA_CHECK 
INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'UNITEDHEALTH GROUP INC (UNH) (CIK 0000731766)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)'
		)
	OR ROWID = 1
)
ORDER BY STT


-- EXXON MOBIL CORP (XOM) (CIK 0000034088)

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 245 AND 267

-- 23 

SELECT 23 * 3
SELECT 
*
FROM DATA_SEC_GOV
WHERE [Company name] = 'EXXON MOBIL CORP (XOM) (CIK 0000034088)'

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'EXXON MOBIL CORP (XOM) (CIK 0000034088)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)'
		)
	OR ROWID = 1
)
ORDER BY STT

-- 3.13 Visa Inc. (V)

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Visa Inc. (V)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income'
		)
	OR ROWID = 1
)
ORDER BY STT

-------------------------------------------------------------Procter & Gamble Company (PG)
INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Procter & Gamble Company (PG)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income'
		)
	OR ROWID = 1
)
ORDER BY STT



----------------------Costco Wholesale Corp (COST)
-- 333 AND 357 : 25

-- 49

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 333 AND 357

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Costco Wholesale Corp (COST)'

SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Costco Wholesale Corp (COST)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income'
		)
	OR ROWID = 1
)
ORDER BY STT


----------------------------- -  3.18 Johnson & Johnson (JNJ)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Johnson & Johnson (JNJ)' AND [Txt file ?] IS  NULL



------------------------------- 3/19 Mastercard Inc (MA) (CIK 0001141391)

-- 24
-- 442 AND 465
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Mastercard Inc (MA) (CIK 0001141391)' AND [Txt file ?] IS  NULL

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 442 AND 465
-- 49
INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'No tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Mastercard Inc (MA) (CIK 0001141391)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income'
		)
	OR ROWID = 1
)
ORDER BY STT

-------------------------------------------------- Home Depot, Inc. (HD)
-- 466 AND 486
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Home Depot, Inc. (HD)' AND [Txt file ?] IS NULL


INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 466 AND 486
-- 49
INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Home Depot, Inc. (HD)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income'
		)
	OR ROWID = 1
)
ORDER BY STT


-----------------------------------------------------------------------------Abbvie Inc. (ABBV)
-- 13
-- 490 AND 502
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Abbvie Inc. (ABBV)'

INSERT INTO B01_DATA_PDF_FILE
SELECT * FROM PDF_FILE1
WHERE STT BETWEEN 490 AND 502

-- 490 AND 502
INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'CHECK 501 502' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Abbvie Inc. (ABBV)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income'
		)
	OR ROWID = 1
)
ORDER BY STT

------------------------------------------------------Walmart Inc. (WMT)

-- 7
-- 503 AND 509
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Walmart Inc. (WMT)'

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 503 AND 509

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'CHECK 501 502' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Walmart Inc. (WMT)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome'
		)
	OR ROWID = 1
)
ORDER BY STT


-------------------------------------- Netflix Inc (NFLX)
-- 24
-- 510 AND 533

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Netflix Inc (NFLX)'
ORDER BY STT

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 510 AND 533

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'CHECK 531 532 533 TAX' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Netflix Inc (NFLX)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome'
		)
	OR ROWID = 1
)
ORDER BY STT

---------------------------------------------  Merck & Co., Inc. (MRK)
-- 534 AND 557
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Merck & Co., Inc. (MRK)'
ORDER BY STT

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 534 AND 557

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'NO TAX' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Merck & Co., Inc. (MRK)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome'
		)
	OR ROWID = 1
)
ORDER BY STT

---------------------------------------------  COCA COLA CO (KO) (CIK 0000021344)
-- 534 AND 557
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'COCA COLA CO (KO) (CIK 0000021344)'
ORDER BY STT

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 583 AND 603

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'NO TAX' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'COCA COLA CO (KO) (CIK 0000021344)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome'
		)
	OR ROWID = 1
)
ORDER BY STT

-----------------------------------------Cisco Systems, Inc. (CSCO)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Cisco Systems, Inc. (CSCO)'
ORDER BY STT

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 801 AND 823

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 801 AND 823

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Cisco Systems, Inc. (CSCO)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome'
		)
	OR ROWID = 1
)
ORDER BY STT

-----------------------------------------Accenture Plc (ACN)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Accenture Plc (ACN)'
ORDER BY STT

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 785 AND 800

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 801 AND 823

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Accenture Plc (ACN)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net'
		)
	OR ROWID = 1
)
ORDER BY STT



-----------------------------------------Accenture Plc (ACN)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Accenture Plc (ACN)'
ORDER BY STT

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 785 AND 800

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 801 AND 823

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Accenture Plc (ACN)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net'
		)
	OR ROWID = 1
)
ORDER BY STT


--

-----------------------------------------Accenture Plc (ACN)


SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Servicenow, Inc. (NOW)'
ORDER BY STT

-- 1196 AND 1207 -- 12

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1196 AND 1207 

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 801 AND 823

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Servicenow, Inc. (NOW)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid'
		)
	OR ROWID = 1
)
ORDER BY STT

--------------------------Intuitive Surgical Inc. (ISRG)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Intuitive Surgical Inc. (ISRG)'
ORDER BY STT

-- 1196 AND 1207 -- 12

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1172 AND 1195 

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 801 AND 823

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	IIF( CATEGORY = 'Income taxes paid','Income taxes paid', 'no tax') Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Intuitive Surgical Inc. (ISRG)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid'
		)
	OR ROWID = 1
)
ORDER BY STT

--------------------------Intuitive Surgical Inc. (ISRG)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Verizon Communications (VZ)'
ORDER BY STT

-- 1196 AND 1207 -- 12

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1149 AND 1171 

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 801 AND 823

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	IIF( CATEGORY = 'Income taxes paid','Income taxes paid', 'no tax') Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Verizon Communications (VZ)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid'
		)
	OR ROWID = 1
)
ORDER BY STT

-----------------------------Amgen Inc (AMGN)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Amgen Inc (AMGN)'
ORDER BY STT

-- 1196 AND 1207 -- 12

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1123 AND 1148 

DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 801 AND 823

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	IIF( CATEGORY = 'Income taxes paid','Income taxes paid', 'no tax') Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Amgen Inc (AMGN)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid'
		)
	OR ROWID = 1
)
ORDER BY STT

-----------------------------Applied Materials Inc (AMAT) --- ERROR
------------------ INTERNATIONAL BUSINESS MACHINES CORP (IBM) (CIK 0000051143) --- 0 VALUE
------------------ DANAHER CORP /DE/ (DHR) (CIK 0000313616)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'DANAHER CORP /DE/ (DHR) (CIK 0000313616)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 1054 AND 1075 

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1054 AND 1075 


INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	IIF( CATEGORY = 'Income taxes paid','Income taxes paid', 'no tax') Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'DANAHER CORP /DE/ (DHR) (CIK 0000313616)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations'
		)
	OR ROWID = 1
)
ORDER BY STT

-------

------------------ DANAHER CORP /DE/ (DHR) (CIK 0000313616) operating activities not :

------------------- Philip Morris International Inc. (PM) : operating activities not :
--------------------------Intuit Inc (INTU)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Intuit Inc (INTU)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 996 AND 1017 

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 996 AND 1017 


INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	IIF( CATEGORY = 'Income taxes paid','Income taxes paid', 'no tax') Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Intuit Inc (INTU)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Incometaxes',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations'
		)
	OR ROWID = 1
)
ORDER BY STT


----------------------GENERAL ELECTRIC CO (GE) (CIK 0000040545) : check
SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Abbott Laboratories (ABT)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 948 AND 970 

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 948 AND 970 


INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Abbott Laboratories (ABT)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations',
		'Cashpaidduringtheyearforincometaxes'
		)
	OR ROWID = 1
)
ORDER BY STT

----------------------GENERAL ELECTRIC CO (GE) (CIK 0000040545) : check
-- Qualcomm Inc (QCOM) CHECK 
-- Wells Fargo & Co. (WFC) 0 VALUE
-- Caterpillar Inc. (CAT) 0 VALUE
-- Walt Disney Co (DIS) (CIK 0001744489) : NO
-- Goldman Sachs Group Inc. (GS)



SELECT distinct [Company name]
FROM B03_COMPANY_DATA_CHECK


INSERT INTO B03_COMPANY_DATA_CHECK([Company name], Check_with_Jesper) VALUES
('Pfizer Inc. (PFE)','no result'),
('Caterpillar Inc. (CAT)', 'no result'),
('INTERNATIONAL BUSINESS MACHINES CORP (IBM) (CIK 0000051143)', 'no result')


SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Comcast Corp (CMCSA)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 1423 AND 1444 

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1423 AND 1444 


INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'no tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Comcast Corp (CMCSA)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations',
		'Cashpaidduringtheyearforincometaxes',
		'Netincomefromcontinuingoperations',
		'Netincomefromconsolidatedoperations'
		)
	OR ROWID = 1
)
ORDER BY STT

-----Pfizer Inc. (PFE)



SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Pfizer Inc. (PFE)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 1299 AND 1322 

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1299 AND 1322 


INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Pfizer Inc. (PFE)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations',
		'Cashpaidduringtheyearforincometaxes',
		'Netincomefromcontinuingoperations'
		)
	OR ROWID = 1
)
ORDER BY STT


-----------------RTX Corp (RTX) (CIK 0000101829) check
-- Uber Technologies, Inc. (UBER) / need to add 1 more table
-- Union Pacific Corp. (UNP)


SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Union Pacific Corp. (UNP)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 1476 AND 1496 

INSERT INTO B01_DATA_PDF_FILE
SELECT Row	,STT,	[File name],	Type,	Category,	Col1,	Col2,	Col3
FROM PDF_FILE1
WHERE STT BETWEEN 1476 AND 1496 
AND Category IS NOT NULL 
AND Category <> 'ï»¿'

select *
FROM PDF_FILE1
WHERE STT = 1483 AND Category = 'ï»¿'

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '' OR Category <> 'NET INCOME', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'no tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Union Pacific Corp. (UNP)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations',
		'Cashpaidduringtheyearforincometaxes',
		'Netincomefromcontinuingoperations',
		'Netincomefromconsolidatedoperations'
		)
	OR ROWID = 1
)
ORDER BY STT


----- At&t Inc. (T)


SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'AMERICAN EXPRESS CO (AXP) (CIK 0000004962)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 1497 AND 1519 

INSERT INTO B01_DATA_PDF_FILE
SELECT Row	,STT,	[File name],	Type,	Category,	Col1,	Col2,	Col3
FROM PDF_FILE1
WHERE STT BETWEEN 1497 AND 1519 


INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '' OR Category <> 'NET INCOME', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'no tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'AMERICAN EXPRESS CO (AXP) (CIK 0000004962)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations',
		'Cashpaidduringtheyearforincometaxes',
		'Netincomefromcontinuingoperations',
		'Netincomefromconsolidatedoperations'
		)
	OR ROWID = 1
)
ORDER BY STT

---- LOWES COMPANIES INC (LOW) (CIK 0000060667)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'PROGRESSIVE CORP/OH/ (PGR) (CIK 0000080661)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 1648 AND 1671 

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1648 AND 1671 


INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '' OR Category <> 'NET INCOME', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'no tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'PROGRESSIVE CORP/OH/ (PGR) (CIK 0000080661)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations',
		'Cashpaidduringtheyearforincometaxes',
		'Netincomefromcontinuingoperations',
		'Netincomefromconsolidatedoperations',
		'NetincomeattributabletoProgressive'
		)
	OR ROWID = 1
)
ORDER BY STT

----Conocophillips (COP)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Conocophillips (COP)'
ORDER BY STT



SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'PROGRESSIVE CORP/OH/ (PGR) (CIK 0000080661)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 1672 AND 1696 

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1672 AND 1696 

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '' OR Category <> 'NET INCOME', 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'no tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Conocophillips (COP)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations',
		'Cashpaidduringtheyearforincometaxes',
		'Netincomefromcontinuingoperations',
		'Netincomefromconsolidatedoperations',
		'NetincomeattributabletoProgressive'
		)
	OR ROWID = 1
)
ORDER BY STT

--------Honeywell International, Inc. (HON)

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Lam Research Corp (LRCX)'
ORDER BY STT

-- 1196 AND 1207 -- 12
DELETE FROM B01_DATA_PDF_FILE
WHERE STT BETWEEN 1994 AND 2015 

INSERT INTO B01_DATA_PDF_FILE
SELECT Column_1	,STT,	File_name,	Type,	Category,	Col1,	Col2,	Col3
FROM [temp5 (1)]
WHERE STT BETWEEN 1994 AND 2015 
SELECT *
FROM PDF_FILE1
WHERE STT = 1955

INSERT INTO B03_COMPANY_DATA_CHECK
SELECT 
	ROWID,
	ZF_ROW_LINE,
	STT,
	[Company name],
	Link,
	IIF(Category IS NULL OR Category = '' , 'Date', Category) as Category,
	Col1,
	Col2,
	Col3,
	'no tax' Check_with_Jesper
FROM B01_DATA_PDF_FILE_UPDATE
WHERE [Company name] = 'Lam Research Corp (LRCX)'
AND 
(
	TRIM(REPLACE(Category,' ','')) IN ('Netincome(loss)', ' Netincome','Netincome','Cashpaidforincometaxes,net',
		'Cashpaid(received)forincometaxes,net',
		'Cashincometaxespaid,net',
		'Netearnings',
		'Incometaxespaid',
		'Incometaxespaid(received)',
		'NETLOSS',
		'Netincome–Lindeplc',
		'Cashpaid(refund)forincometaxes,net',
		'Cashpaid(refund)fortaxes',
		'Cashpaidfortaxes',
		'Cashpaidforincometaxes,net',
		'Cashpaidforincometaxes',
		'Cashincometaxespaid,net(a)',
		'Incometaxespaid,netofrefunds ',
		'Netincomeincludingnon-controllinginterest',
		'Net(loss)income',
		'Consolidatednetincome',
		'Incometaxespaid,net',
		'Taxespaid',
		'Netearningsfromoperations',
		'Cashpaidduringtheyearforincometaxes',
		'Netincomefromcontinuingoperations',
		'Netincomefromconsolidatedoperations',
		'NetincomeattributabletoProgressive',
		'Incometaxes',
		'Cashpaymentsforincometaxes',
		'Cashpaymentsforincometaxes,net'
		)
	OR ROWID = 1
)
ORDER BY STT


SELECT 
DISTINCT [Company name]

FROM B03_COMPANY_DATA_CHECK







SELECT *
FROM PDF_FILE1 
WHERE STT = 1895










SELECT * FROM PDF_FILE1 WHERE STT =1503




UPDATE B01_DATA_PDF_FILE_UPDATE
SET  Category = 'Date', COL1 = '2017', Col2 = '2016', COL3 = '2015'
WHERE ZF_ROW_LINE = 74484  AND STT = 1503


UPDATE B01_DATA_PDF_FILE
SET  Category = 'Date', COL1 = '2017', Col2 = '2016', COL3 = '2015'
WHERE Row = 74484  AND STT = 1503

UPDATE B01_DATA_PDF_FILE_UPDATE
SET  Category = 'Date', COL1 = '2018', Col2 = '2017', COL3 = '2016'
WHERE ZF_ROW_LINE = 74448  AND STT = 1502


UPDATE B01_DATA_PDF_FILE
SET  Category = 'Date', COL1 = '2018', Col2 = '2017', COL3 = '2016'
WHERE Row = 74448  AND STT = 1502



UPDATE B01_DATA_PDF_FILE_UPDATE
SET  Category = 'Date', COL1 = '2006', Col2 = '2005', COL3 = '2004'
WHERE ZF_ROW_LINE = 47208  AND STT = 966


UPDATE B01_DATA_PDF_FILE
SET  Category = 'Date', COL1 = '2006', Col2 = '2005', COL3 = '2004'
WHERE Row = 47208  AND STT = 966




DELETE FROM  B01_DATA_PDF_FILE
WHERE STT = 966

INSERT INTO B01_DATA_PDF_FILE
select *
FROM PDF_FILE1
WHERE STT = 966


UPDATE B01_DATA_PDF_FILE
SET  Category = 'Date', COL1 = 'April 30, 2008', Col2 = 'December 31 2007', COL3 = 'December 31 2006'
WHERE Row = 47121  AND STT = 964









UPDATE B01_DATA_PDF_FILE_UPDATE
SET COL1 = '2003', Col2 = '2002', COL3 = '2001'
WHERE ZF_ROW_LINE = 53443  AND STT = 1073


UPDATE B01_DATA_PDF_FILE
SET COL1 = '2003', Col2 = '2002', COL3 = '2001'
WHERE Row = 53443  AND STT = 1073



SELECT 
*
FROM [temp5 (1)]
WHERE STT = 1055








UPDATE B01_DATA_PDF_FILE_UPDATE
SET COL1 = 'January 29,2006', Col2 = 'January 30,2005', COL3 = 'February 1,2004'
WHERE ZF_ROW_LINE = 23064  AND STT = 485


UPDATE B01_DATA_PDF_FILE
SET COL1 = 'January 29,2006', Col2 = 'January 30,2005', COL3 = 'February 1,2004'
WHERE Row = 23014  AND STT = 484

UPDATE B01_DATA_PDF_FILE_UPDATE
SET COL1 = 'January 29,2006', Col2 = 'January 30,2005', COL3 = 'February 1,2004'
WHERE ZF_ROW_LINE = 23014  AND STT = 484


UPDATE B01_DATA_PDF_FILE
SET COL1 = 'January 28,2007', Col2 = 'January 29,2006', COL3 = 'January 30,2005'
WHERE Row = 22964  AND STT = 483

UPDATE B01_DATA_PDF_FILE_UPDATE
SET COL1 = 'February 1,2009', Col2 = 'February 3,2008', COL3 = 'January 28,2007'
WHERE ZF_ROW_LINE = 22964  AND STT = 483



UPDATE B01_DATA_PDF_FILE
SET COL1 = 'February 1,2009', Col2 = 'February 3,2008', COL3 = 'January 28,2007'
WHERE Row = 22861  AND STT = 481

UPDATE B01_DATA_PDF_FILE_UPDATE
SET COL1 = 'February 1,2009', Col2 = 'February 3,2008', COL3 = 'January 28,2007'
WHERE ZF_ROW_LINE = 22861  AND STT = 481


UPDATE B01_DATA_PDF_FILE
SET COL1 = 'February 3,2008', Col2 = 'January 28,2007', COL3 = 'January 29,2006'
WHERE Row = 22914  AND STT = 482

UPDATE B01_DATA_PDF_FILE_UPDATE
SET COL1 = 'February 3,2008', Col2 = 'January 28,2007', COL3 = 'January 29,2006'
WHERE ZF_ROW_LINE = 22914  AND STT = 482








SELECT 
	DISTINCT [Company name]
FROM B03_COMPANY_DATA_CHECK



SELECT 42 * 3


SELECT 
*
FROM DATA_SEC_GOV
WHERE [Company name] = 'Procter & Gamble Company (PG)'
and [Txt file ?] is NULL





SELECT *
FROM [temp5 (1)]
WHERE STT = 245



SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 270 AND 288



SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Visa Inc. (V)'

INSERT INTO B01_DATA_PDF_FILE
SELECT *
FROM PDF_FILE1
WHERE STT BETWEEN 270 AND 288






SELECT *

FROM B03_COMPANY_DATA_CHECK
WHERE Category = 'DATE'
OR Category IS NULL
OR Category = ''


SELECT *
FROM [temp5 (1)] 
WHERE STT = 8

-- 30-Sep-17	24-Sep-16	26-Sep-15


UPDATE B01_DATA_PDF_FILE
SET COL1 = 'November 4,2018', Col2 = 'October 29,2017', COL3 = 'October 30,2016'
WHERE Row = 8159  AND STT = 172

UPDATE B01_DATA_PDF_FILE_UPDATE
SET COL1 = 'November 4,2018', Col2 = 'October 29,2017', COL3 = 'October 30,2016'
WHERE ZF_ROW_LINE = 8159  AND STT = 172

UPDATE B03_COMPANY_DATA_CHECK
SET COL1 = 'September 28,2019', Col2 = 'September 29,2018', COL3 = 'September 30,2017'
WHERE ZF_ROW_LINE = 171 AND STT = 5



UPDATE B03_COMPANY_DATA_CHECK
SET Category = 'Date'
WHERE Category = ''

SELECT *
FROM B03_COMPANY_DATA_CHECK
WHERE [Company name] = 'Apple Inc. (AAPL)'
AND Category = ''

SELECT *
FROM B01_DATA_PDF_FILE_UPDATE
WHERE ZF_ROW_LINE = 256 



SELECT 
*
FROM B01_DATA_PDF_FILE
WHERE STT = 8

SELECT *
FROM B01_DATA_PDF_FILE_UPDATE
WHERE STT = 8










select *
FROM DATA_THUAN
WHERE [Company name] = 'Alphabet Inc. (GOOG, GOOGL) (CIK 0001652044)'




SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Alphabet Inc. (GOOG, GOOGL) (CIK 0001652044)'
and [Txt file ?] is  null










SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'Meta Platforms, Inc. (META) (CIK 0001326801)'
and [Txt file ?] is  null





SELECT *
FROM DATA_THUAN
WHERE [Company name] = 'AMAZON COM INC (AMZN) (CIK 0001018724)'


SELECT *
FROM B01_DATA_PDF_FILE_UPDATE
WHERE STT = 73
AND Category LIKE '%TAX%'


-- 22 records

SELECT *
FROM DATA_SEC_GOV
WHERE [Company name] = 'AMAZON COM INC (AMZN) (CIK 0001018724)'
and [Txt file ?] is  null











update B01_DATA_PDF_FILE
SET Col1 = 'September  28,2013', Col2 = 'September  29,2012', Col3 = '	September  24,2011'
WHERE row = 444

select *
FROM  B01_DATA_PDF_FILE
WHERE row = 444
GO
