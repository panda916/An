USE [DIVA_SEV_WARRANTY_JULY_21_JUNE_23]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE       PROC [dbo].[B02_COMBINE_WARRANTY_CLAIM_DATA]

AS

-- Step 1 / Create the fee columns then get data from Claim data into Warranty data.

-- Step 1.1 Add Part fee value and Status columns.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PART_FEE_CLAIM FLOAT
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PART_FEE_CLAIM_STATUS VARCHAR(12)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PART_FEE_CLAIM = AMOUNT,
    ZF_PART_FEE_CLAIM_STATUS = STATUS
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (
    SELECT [Job No],
        ISNULL( SUM([Claim Amount]),0) AMOUNT,
        ISNULL(MIN([Claim Status]),'') STATUS 
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Fee Type] = 'Part Fee'
    GROUP BY [Job No]
    ) AS A
ON [Job No] = [Job Number]

-- Step 1.2 Add Labor fee value and Status columns.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_LABOR_FEE_CLAIM FLOAT
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_LABOR_FEE_CLAIM_STATUS VARCHAR(12)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_LABOR_FEE_CLAIM = AMOUNT,
    ZF_LABOR_FEE_CLAIM_STATUS = STATUS
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]),0) AMOUNT,
        ISNULL(MIN([Claim Status]),'') STATUS 
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Fee Type] = 'Labor Fee'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Step 1.3 Add Home service fee value and Status columns.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_HOME_SERVICE_FEE_CLAIM FLOAT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_HOME_SERVICE_FEE_CLAIM_STATUS VARCHAR(12)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_HOME_SERVICE_FEE_CLAIM = AMOUNT,
    ZF_HOME_SERVICE_FEE_CLAIM_STATUS = STATUS
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]),0) AMOUNT,
        ISNULL(MIN([Claim Status]),'') STATUS 
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Fee Type] = 'Home Service Fee'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Step 1.4  Add Inspection fee value and Status columns.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_INSPECTION_FEE_CLAIM FLOAT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_INSPECTION_FEE_CLAIM_STATUS VARCHAR(12)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_INSPECTION_FEE_CLAIM = AMOUNT,
    ZF_INSPECTION_FEE_CLAIM_STATUS = STATUS
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]),0) AMOUNT,
        ISNULL(MIN([Claim Status]),'') STATUS 
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Fee Type] = 'Inspection Charge'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Step 1.5  Add Handling fee value and Status columns.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_HANDLING_FEE_CLAIM FLOAT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_HANDLING_FEE_CLAIM_STATUS VARCHAR(12)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_HANDLING_FEE_CLAIM = AMOUNT,
    ZF_HANDLING_FEE_CLAIM_STATUS = STATUS
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]),0) AMOUNT,
        ISNULL(MIN([Claim Status]),'') STATUS 
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Fee Type] = 'Handling Fee'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Step 1.6  Add Transfer Repair Fee  value and Status columns.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_TRANSFER_REPAIR_FEE_CLAIM FLOAT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS VARCHAR(12)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TRANSFER_REPAIR_FEE_CLAIM = AMOUNT,
    ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS = STATUS
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]),0) AMOUNT,
        ISNULL(MIN([Claim Status]),'') STATUS 
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Fee Type] = 'Transfer Repair Fee'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Step 1.7  Add Check Fee value and Status columns.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_CHECK_FEE_CLAIM FLOAT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_CHECK_FEE_CLAIM_STATUS VARCHAR(12)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_CHECK_FEE_CLAIM = AMOUNT,
    ZF_CHECK_FEE_CLAIM_STATUS = STATUS
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]),0) AMOUNT,
        ISNULL(MIN([Claim Status]),'') STATUS 
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Fee Type] = 'Check Fee'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Step 1.8  Add Transportation Charge value and Status columns.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_TRANSPORTATION_FEE_CLAIM FLOAT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_TRANSPORTATION_FEE_CLAIM_STATUS VARCHAR(12)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TRANSPORTATION_FEE_CLAIM = AMOUNT,
    ZF_TRANSPORTATION_FEE_CLAIM_STATUS = STATUS
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]),0) AMOUNT,
        ISNULL(MIN([Claim Status]),'') STATUS 
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Fee Type] = 'Transportation Charge'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

--------------------------------------------------------------- PART 2 Add Total tax, Total Rejected/Cancel ------------------------------------------
-- Task 2 / Add total tax and total Reject/Cancel 
-- Task 2.1 Add total ZF_TOTAL_TAX_SUBMIT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA  ADD ZF_TOTAL_TAX_SUBMIT FLOAT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_TAX_SUBMIT = AMOUNT
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Tax Amount]),0) AMOUNT
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Claim Status] = 'RC Submit'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Task 2.2 Add total ZF_TOTAL_TAX_REJECTED

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_TOTAL_TAX_REJECTED FLOAT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_TAX_REJECTED = AMOUNT
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Tax Amount]),0) AMOUNT
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Claim Status] <> 'RC Submit'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Task 2.3 Add total ZF_TOTAL_SONY_NEEDS_TO_PAY

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA  ADD ZF_TOTAL_SONY_NEEDS_TO_PAY FLOAT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_SONY_NEEDS_TO_PAY = AMOUNT
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]+[Tax Amount]),0) AMOUNT
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Claim Status] = 'RC Submit'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]

-- Task 2.4 Add total ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA  ADD ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED FLOAT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED = AMOUNT
FROM B01_04_IT_WARRANTY_FINAL_DATA
INNER JOIN (

    SELECT [Job No],
        ISNULL( SUM([Claim Amount]+[Tax Amount]),0) AMOUNT
    FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
    WHERE [Claim Status] <> 'RC Submit'
    GROUP BY [Job No]

    ) AS A
ON [Job No] = [Job Number]


---------------------------------------------------------- PART 3 : UPDATE 6 Special Jobs in Claim Data: Same Job and Fee Type with 2 Claim Statuses -----------------------
-- Task 3 / 

-- 3.1 Job number : J12320148

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_HOME_SERVICE_FEE_CLAIM = 400000,
    ZF_HOME_SERVICE_FEE_CLAIM_STATUS = 'RC Submit',
    ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED = 715000,
    ZF_TOTAL_SONY_NEEDS_TO_PAY = 6063200,
    ZF_TOTAL_TAX_REJECTED = 65000,
    ZF_TOTAL_TAX_SUBMIT = 551200
WHERE [Job Number] = 'J12320148'

-- 3.2 Job number : JB0104276

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_HOME_SERVICE_FEE_CLAIM = 150000,
    ZF_HOME_SERVICE_FEE_CLAIM_STATUS = 'RC Rejected',
    ZF_LABOR_FEE_CLAIM = 150000,
    ZF_LABOR_FEE_CLAIM_STATUS = 'RC Rejected'
WHERE [Job Number] = 'JB0104276'


-- 3.3 Job number : J12065533

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PART_FEE_CLAIM  = 4806000,
    ZF_PART_FEE_CLAIM_STATUS  = 'RC Submit',
    ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED = 5286600,
    ZF_TOTAL_SONY_NEEDS_TO_PAY = 6001600,
    ZF_TOTAL_TAX_REJECTED = 480600,
    ZF_TOTAL_TAX_SUBMIT = 545600
WHERE [Job Number] = 'J12065533'


-- 3.4 Job number : JA0009503
UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PART_FEE_CLAIM  = 5181000,
    ZF_PART_FEE_CLAIM_STATUS  = 'RC Submit',
    ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED = 364100,
    ZF_TOTAL_SONY_NEEDS_TO_PAY = 6612100,
    ZF_TOTAL_TAX_REJECTED = 33100,
    ZF_TOTAL_TAX_SUBMIT = 601100
WHERE [Job Number] = 'JA0009503'


-- 3.5 Job number : JA0126769
UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PART_FEE_CLAIM  = 7972000,
    ZF_PART_FEE_CLAIM_STATUS  = 'RC Submit',
    ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED = 1463000,
    ZF_TOTAL_SONY_NEEDS_TO_PAY = 9687200,
    ZF_TOTAL_TAX_REJECTED = 133000,
    ZF_TOTAL_TAX_SUBMIT = 865200
WHERE [Job Number] = 'JA0126769'


-- 3.6 Job number : JB0138576
UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PART_FEE_CLAIM  = 292000,
    ZF_PART_FEE_CLAIM_STATUS  = 'RC Submit',
    ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED = 1830400,
    ZF_TOTAL_SONY_NEEDS_TO_PAY = 321200,
    ZF_TOTAL_TAX_REJECTED = 146400,
    ZF_TOTAL_TAX_SUBMIT = 29200
WHERE [Job Number] = 'JB0138576'


--------------------------------------------------------------------- PART 4 /  UPDATE NULL VALUE TO 0. ---------------------------------------------------

-- Task 4.1 Update for Part fee

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PART_FEE_CLAIM = 0,
	ZF_PART_FEE_CLAIM_STATUS = ''
WHERE ZF_PART_FEE_CLAIM_STATUS IS NULL

-- Task 4.2 Update for Labor fee

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_LABOR_FEE_CLAIM = 0,
	ZF_LABOR_FEE_CLAIM_STATUS = ''
WHERE ZF_LABOR_FEE_CLAIM IS NULL

-- Task 4.3 Update for Home service fee

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_HOME_SERVICE_FEE_CLAIM = 0,
	ZF_HOME_SERVICE_FEE_CLAIM_STATUS = ''
WHERE ZF_HOME_SERVICE_FEE_CLAIM IS NULL

-- Task 4.4 Update for Inspection fee

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_INSPECTION_FEE_CLAIM = 0,
	ZF_INSPECTION_FEE_CLAIM_STATUS = ''
WHERE ZF_INSPECTION_FEE_CLAIM IS NULL

-- Task 4.5 Update for Handling fee

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_HANDLING_FEE_CLAIM = 0,
	ZF_HANDLING_FEE_CLAIM_STATUS = ''
WHERE ZF_HANDLING_FEE_CLAIM IS NULL

-- Task 4.6 Update for Tranfer repair

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TRANSFER_REPAIR_FEE_CLAIM = 0,
	ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS = ''
WHERE ZF_TRANSFER_REPAIR_FEE_CLAIM IS NULL

-- Task 4.7 Update for Tranfer repair

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_CHECK_FEE_CLAIM = 0,
	ZF_CHECK_FEE_CLAIM_STATUS = ''
WHERE ZF_CHECK_FEE_CLAIM IS NULL

-- Task 4.8 Update for Tranfer repair

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TRANSPORTATION_FEE_CLAIM = 0,
	ZF_TRANSPORTATION_FEE_CLAIM_STATUS = ''
WHERE ZF_TRANSPORTATION_FEE_CLAIM IS NULL

-- Task 4.9 Update for ZF_TOTAL_TAX_SUBMIT and ZF_TOTAL_TAX_REJECTED and ZF_TOTAL_SONY_NEEDS_TO_PAY and ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_TAX_SUBMIT = 0
WHERE ZF_TOTAL_TAX_SUBMIT IS NULL

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_TAX_REJECTED = 0
WHERE ZF_TOTAL_TAX_REJECTED IS NULL

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_SONY_NEEDS_TO_PAY = 0
WHERE ZF_TOTAL_SONY_NEEDS_TO_PAY IS NULL

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED = 0
WHERE ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED IS NULL


---------------------------------------------------------- PART 4  / UPDATE IW then Job number not found in Claim data ----------------------------------------

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PART_FEE_CLAIM = [Part Fee],
	ZF_LABOR_FEE_CLAIM = [Labor Fee],
	ZF_HOME_SERVICE_FEE_CLAIM = [Home Service Fee],
	ZF_INSPECTION_FEE_CLAIM = [Inspection Fee],
	ZF_HANDLING_FEE_CLAIM = [Handling Fee],

	ZF_PART_FEE_CLAIM_STATUS = 'Pending',
	ZF_LABOR_FEE_CLAIM_STATUS = 'Pending',
	ZF_HOME_SERVICE_FEE_CLAIM_STATUS = 'Pending',
	ZF_INSPECTION_FEE_CLAIM_STATUS = 'Pending',
	ZF_HANDLING_FEE_CLAIM_STATUS = 'Pending',
	ZF_TOTAL_SONY_NEEDS_TO_PAY = [Sony Needs To Pay]
WHERE [Job Number] NOT IN 
(
	SELECT DISTINCT [Job No]
	FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT

)
AND [Warranty Type] = 'IW'
AND [Sony Needs To Pay] > 0


--------------


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_CLAIM_STATUS_FLAG = 
(
CASE
    WHEN ZF_PART_FEE_CLAIM_STATUS = 'Pending' THEN 'Pending'
    
    WHEN  (
			ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS like '%submit%' 
			AND (
			ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS  like '%Rejected%' 
			OR ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS  like '%Cancel%')
			) 
		OR (
			ZF_TOTAL_SONY_NEEDS_TO_PAY>0 AND ZF_TOTAL_SONY_NEEDS_TO_PAY_REJECTED>0
		    ) THEN 'Submit and Rejected/Canceled'

    WHEN 
		ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS like '%submit%' 
		AND ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS not like '%Rejected%' 
		AND ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS not like '%Cancel%' 
			THEN 'Submit'
    WHEN 
		ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS NOT like '%submit%' 
		AND (ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS  like '%Rejected%' OR ZF_PART_FEE_CLAIM_STATUS+ZF_LABOR_FEE_CLAIM_STATUS+ZF_HOME_SERVICE_FEE_CLAIM_STATUS+ZF_INSPECTION_FEE_CLAIM_STATUS+ZF_HANDLING_FEE_CLAIM_STATUS+ZF_TRANSFER_REPAIR_FEE_CLAIM_STATUS+ZF_CHECK_FEE_CLAIM_STATUS+ZF_TRANSPORTATION_FEE_CLAIM_STATUS  like '%Cancel%'
		) THEN 'Rejected/Canceled'
    ELSE 'Not found'
END
)


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_CLAIM_STATUS_FLAG = 'Not Found, IW and Sony paid = 0'
WHERE ZF_CLAIM_STATUS_FLAG = 'Pending'
AND [Sony Needs To Pay] = 0




--------------------------------------------------------- NOW WE NEED WE NEED TO UPDATE ALL RECORDS FLAG----------------------------------

--- Related to Section 1 : Strange of serial no
-- ZF_STRANGE_SERIAL_NO_CASE
-- ZF_STRANGE_OF_SER_NO
-- 262792
-- 262792
-- 262789

-- ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')

-- Step 5.2 / Related to Add strange serial number

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_STRANGE_SERIAL_NO_CASE INT

-- Case 1 : Serial numbers contain only alphabetic characters, with no numeric digits.

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_SERIAL_NO_CASE =  1
WHERE [Serial No] +  [Job Number] IN
(
	SELECT distinct  [Serial No] +  [Job Number]
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE [Serial No] LIKE '%[a-zA-Z]%'
		and [Serial No] NOT LIKE  '%[0-9]%'
		AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
)
AND ZF_STRANGE_SERIAL_NO_CASE IS NULL
AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')

-- Case 2 : Serial numbers are empty

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_SERIAL_NO_CASE =  2
WHERE [Serial No] +  [Job Number] IN
(
	SELECT distinct  [Serial No] +  [Job Number]
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE 
	(
		[Serial No] = ''
		OR LEN([Serial No]) = 0
		OR [Serial No] IS NULL
	)
	AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
)
AND ZF_STRANGE_SERIAL_NO_CASE IS NULL
AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')

-- Case 3 : Serial number values are the same as the model codes

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_SERIAL_NO_CASE = 3
WHERE [Serial No] +  [Job Number] IN
(
	SELECT distinct  [Serial No] +  [Job Number]
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE 
	(
		TRIM([Model Code]) = TRIM([Serial No])
		OR
		TRIM(REPLACE( REPLACE([Model Name],'VN3','') ,'KD-','')) = TRIM(REPLACE( REPLACE([Serial No],'VN3','') ,'KD-',''))
	)
		AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
		and [Serial No] <> ''
)
AND ZF_STRANGE_SERIAL_NO_CASE IS NULL
AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')

--  Case 4 / Serial number value is same Phone/Mobie

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_SERIAL_NO_CASE = 4
WHERE [Serial No] +  [Job Number] IN
(
		SELECT distinct  [Serial No] +  [Job Number]
		FROM B01_04_IT_WARRANTY_FINAL_DATA
		WHERE 	
		(
			[Serial No] = MOBIL OR 
			[Serial No] = PHONE
		)
		AND [Serial No] <> ''
		AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
)
AND ZF_STRANGE_SERIAL_NO_CASE IS NULL
AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')

-- Case 5 : Serial numbers starting with VN or SVN.


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_SERIAL_NO_CASE = 5 
WHERE [Serial No] +  [Job Number] IN
(
		SELECT distinct  [Serial No] +  [Job Number]
		FROM B01_04_IT_WARRANTY_FINAL_DATA
		WHERE 	
		(
			[Serial No] LIKE 'VN%'
			OR 
			[Serial No] LIKE 'SVN%'
		)
		AND [Serial No] <> ''
		AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
)
AND ZF_STRANGE_SERIAL_NO_CASE IS NULL
AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')

-- Case 6 : Serial numbers have 3 to 5 characters

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_SERIAL_NO_CASE = 6
WHERE [Serial No] +  [Job Number] IN
(
		SELECT distinct  [Serial No] +  [Job Number]
		FROM B01_04_IT_WARRANTY_FINAL_DATA
		WHERE 	
		(
			LEN([Serial No]) BETWEEN 3 AND 5
		)
		AND [Serial No] <> ''
		AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
)
AND ZF_STRANGE_SERIAL_NO_CASE IS NULL
AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')


-- Check


ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_STRANGE_OF_SER_NO NVARCHAR(3); -- Strange Serial numbers 

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_OF_SER_NO = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_STRANGE_OF_SER_NO = 'Yes'
WHERE ZF_STRANGE_SERIAL_NO_CASE IS NOT NULL



--- Section 2 : Xoa section 2 /  ZF_SAME_SERIAL_DIFF_MODEL_CODE ZF_SAME_SERIAL_DIFF_MODEL_CODE_PRODUCT_CATE

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA DROP COLUMN ZF_SAME_SERIAL_DIFF_MODEL_CODE, ZF_SAME_SERIAL_DIFF_MODEL_CODE_PRODUCT_CATE



-- Section 3 : Xoa section 3 / ZF_CHANGE_NEW_PRODUCT_FLAG 

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA DROP COLUMN ZF_CHANGE_NEW_PRODUCT_FLAG

-- Section 4 : ZF_JOB_RELATED_TO_CHECKING_PRODUCT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_RELATED_TO_CHECKING_PRODUCT NVARCHAR(3)


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_TO_CHECKING_PRODUCT = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_TO_CHECKING_PRODUCT = 'Yes'
WHERE [Job Number] IN
(

	select distinct [Job Number] from B01_04_IT_WARRANTY_FINAL_DATA
	where (replace([Repair Action/Technician Remarks],' ', '') LIKE N'%tuv?n%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%tuv?n%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%tuvan%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%tuvan%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%hdsd%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%hdkh%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%hu?ngd?n%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%huongd?n%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%hu?ngdan%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%huongdan%' 
	OR [Repair Code] = '70 - FUNCTIONAL / SPECIFICATIONS CHECK'
	OR [Repair Code] = '69 - EXPLANATION FOR CUSTOMER'
)
AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
AND ZF_PART_FEE_CLAIM =0
)

-- Section 5 : ZF_JOB_RELATED_TO_CHECKING_PRODUCT

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_RETURNED_WITHOUT_REPAIR_FLAG NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_RETURNED_WITHOUT_REPAIR_FLAG = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_RETURNED_WITHOUT_REPAIR_FLAG = 'Yes'
WHERE [Job Number] IN
(
    SELECT DISTINCT [Job Number] FROM B01_04_IT_WARRANTY_FINAL_DATA 
    WHERE  
		ZF_TOTAL_SONY_NEEDS_TO_PAY*ZF_EXCHANGE>400
    AND [Repair Code] = '81 - RETURNED WITHOUT REPAIR'
    AND ZF_PART_FEE_CLAIM = 0
	AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
)



SELECT DISTINCT [Job Number], ZF_TOTAL_SONY_NEEDS_TO_PAY*ZF_EXCHANGE FROM B01_04_IT_WARRANTY_FINAL_DATA 
WHERE  
	 (replace([Repair Action/Technician Remarks],' ', '') LIKE N'%tuv?n%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%tuv?n%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%tuvan%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%tuvan%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%hdsd%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%hdkh%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%hu?ngd?n%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%huongd?n%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%hu?ngdan%' 
	OR replace([Repair Action/Technician Remarks],' ', '') LIKE N'%huongdan%' 
	OR [Repair Code] = '70 - FUNCTIONAL / SPECIFICATIONS CHECK'
	OR [Repair Code] = '69 - EXPLANATION FOR CUSTOMER'
)
AND  ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
AND ZF_PART_FEE_CLAIM =0
order by ZF_TOTAL_SONY_NEEDS_TO_PAY*ZF_EXCHANGE DESC



-- Pending : Jobs not found in Claim data, Warranty type IW and Sony need to pay > 0



-- Section 13

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_REPAIR_4_TIME_SONY_PAID_GREATER_500 NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_REPAIR_4_TIME_SONY_PAID_GREATER_500 = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_REPAIR_4_TIME_SONY_PAID_GREATER_500 = 'Yes'
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No]+[Model Code]+[ASC Name] IN 
(
	SELECT [Serial No]+[Model Code]+[ASC Name]
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE [Serial No] <> ''
	AND [Model Code] <> ''
	AND  ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
	GROUP BY [Serial No], [Model Code], [ASC Name]
	HAVING COUNT(DISTINCT [Job Number]) > 3 -- Same product same ASC code repair >= 4 time
	AND SUM(ZF_TOTAL_SONY_NEEDS_TO_PAY * ZF_EXCHANGE) > 500
	   
)
AND  ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')




-- Section 14: ZF_NOT_TV_HOME_SERVICE 


ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_NOT_TV_HOME_SERVICE NVARCHAR(3)
UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_NOT_TV_HOME_SERVICE = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_NOT_TV_HOME_SERVICE = 'Yes'
WHERE [Job Number] IN (
    SELECT DISTINCT [Job Number] 
    FROM B01_04_IT_WARRANTY_FINAL_DATA
    WHERE 
    (([Product Category] = '07LCDTV' AND [Model Name] LIKE '%RMF%')
    OR ([Product Category] = '07LCDTVACCY' AND [Model Name] LIKE '%CMU%')
    OR ([Product Category] <> '07LCDTV' AND [Product Category] <> 'PROFESSIONAL MONITOR' AND [Product Category] <> '07LCDTVACCY' AND [Product Category] <> '' AND [Product Category] <> 'BRC'))
    AND [Service Type] = 'Home Service' 
    AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
)


-- Section 16

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_RELATED_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC = 'Yes'
WHERE [Job Number] IN
(  SELECT DISTINCT [Job Number] FROM (
SELECT 
        LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Begin Repair Date]) AS PreviousRepairDate,
        [Job Number],
        LAG([Job Number]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]) AS PreviousJob,
        LAG([ASC Name]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]) AS PreviousASCName,
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,[ASC Name],[Serial No],[Model Code]
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],
         [ASC Name] from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
    and  ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
    ) as c
) AS TEMP
WHERE RepairGap<90
and [ASC Name] <> PreviousASCName

)

SELECT DISTINCT ZF_CLAIM_STATUS_FLAG
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_JOB_RELATED_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC = 'Yes'

------------ZF_PRODUCT_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC---------------------------
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PRODUCT_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC = 'Yes'
where [Serial No]+[Model Code] in
(  SELECT DISTINCT [Serial No]+[Model Code] FROM (
SELECT 
        LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Begin Repair Date]) AS PreviousRepairDate,
        [Job Number],
        LAG([Job Number]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]) AS PreviousJob,
        LAG([ASC Name]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]) AS PreviousASCName,
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,[ASC Name],[Serial No],[Model Code]
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],
        [ASC Name] from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
    AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
    ) as c
) AS TEMP
WHERE RepairGap<90
and [ASC Name] <> PreviousASCName

)
and ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')


SELECT DISTINCT ZF_CLAIM_STATUS_FLAG
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_PRODUCT_RE_RPAIR_IN_SHORT_TERM_DIFF_ASC = 'Yes'


-----------------------ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE_DIFF_ASC---------------------------------

alter table B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE_DIFF_ASC INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE_DIFF_ASC = RepairGap
FROM B01_04_IT_WARRANTY_FINAL_DATA A1
INNER JOIN (
  SELECT DISTINCT [Job Number],RepairGap FROM (
SELECT 
        
        [Job Number],
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code]  ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],[asc code]
         from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
    and  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')) as c
) AS TEMP
) AS B
ON A1.[Job Number] = B.[Job Number]


------------------------------------ SECTION 17 --- 
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PRODUCT_RELATED_TV_EXCHANGE NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_RELATED_TV_EXCHANGE = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_RELATED_TV_EXCHANGE = 'Yes'
WHERE [Job Number] IN (
    SELECT DISTINCT [Job Number] 
    FROM B01_04_IT_WARRANTY_FINAL_DATA
    WHERE 
    (
        ([Product Category] = '07LCDTV' AND [Model Name] NOT LIKE '%RMF%')
        OR ([Product Category] = '07LCDTVACCY' AND [Model Name] NOT LIKE '%CMU%')
        OR [Product Category] = 'PROFESSIONAL MONITOR'  
		AND [Product Category] = '' 
    )
    AND [Service Type] = 'Product Exchange' 
    AND ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')

)

-- Section 17.2 
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA add ZF_PRODUCT_RELATED_TV_EXCHANGE_PART_FEE NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_RELATED_TV_EXCHANGE_PART_FEE = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_RELATED_TV_EXCHANGE_PART_FEE = 'Yes'
WHERE [Job Number] IN (
    SELECT DISTINCT [Job Number] 
    FROM B01_04_IT_WARRANTY_FINAL_DATA
    WHERE 
    (
        ([Product Category] = '07LCDTV' AND [Model Name] NOT LIKE '%RMF%')
        OR ([Product Category] = '07LCDTVACCY' AND [Model Name] NOT LIKE '%CMU%')
        OR [Product Category] = 'PROFESSIONAL MONITOR'  
		AND [Product Category] = '' 
    )
    AND [Service Type] = 'Product Exchange' 
    AND ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
	AND ZF_PART_FEE_CLAIM > 0

)

----------------------------------- SECTION 10:

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_SAME_WARRANTY_CARD_NO_DIFF_CUSTOMER NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
set ZF_SAME_WARRANTY_CARD_NO_DIFF_CUSTOMER = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
set ZF_SAME_WARRANTY_CARD_NO_DIFF_CUSTOMER = 'Yes'
WHERE [Warranty Card No] IN 
(
        SELECT [Warranty Card No]
        FROM B01_04_IT_WARRANTY_FINAL_DATA
        WHERE [Warranty Card No] <> '' 
        AND ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit') and COALESCE(NULLIF(MOBIL, ''), PHONE) <> '' 
        AND CUSTOMER_NAME <> ''
        and Seq =1
        GROUP BY [Warranty Card No]
        HAVING (COUNT(DISTINCT CUSTOMER_NAME+COALESCE(NULLIF(MOBIL, ''), PHONE)) > 1 )
)
AND [Warranty Card No] <> '' 
        AND ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit') and COALESCE(NULLIF(MOBIL, ''), PHONE) <> '' 
        AND CUSTOMER_NAME <> ''



-- Section 16

-------------------ZF_JOB_RELATED_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG-------------------------------------

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_RELATED_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG NVARCHAR(3)


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG = 'Yes'
where [Job Number] in
(  SELECT DISTINCT [Job Number] FROM (
SELECT 
        LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code] ORDER BY [Begin Repair Date]) AS PreviousRepairDate,
        [Job Number],
        LAG([Job Number]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code] ORDER BY [Repair Completed Date]) AS PreviousJob,
        LAG([ASC Code]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code] ORDER BY [Repair Completed Date]) AS PreviousASCName,
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,[ASC Code],[Serial No],[Model Code]
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],
        [Sony Needs To Pay], [ASC Code] from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
     AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
    ) as c
) AS TEMP
WHERE RepairGap<90

)



------------ZF_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG---------------------------
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG = 'Yes'
where [Serial No]+[Model Code]+[ASC Code] in
(  SELECT DISTINCT [Serial No]+[Model Code]+[ASC Code] FROM (
SELECT 
        LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code] ORDER BY [Begin Repair Date]) AS PreviousRepairDate,
        [Job Number],
        LAG([Job Number]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code] ORDER BY [Repair Completed Date]) AS PreviousJob,
        LAG([ASC Code]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code] ORDER BY [Repair Completed Date]) AS PreviousASCName,
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,[ASC Code],[Serial No],[Model Code]
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],
        [Sony Needs To Pay], [ASC Code] from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
	AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
    ) as c
) AS TEMP
WHERE RepairGap<90
)
AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')




-----------------------ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE---------------------------------
alter table B01_04_IT_WARRANTY_FINAL_DATA
add ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE = RepairGap
FROM B01_04_IT_WARRANTY_FINAL_DATA A1
INNER JOIN (
  SELECT DISTINCT [Job Number],RepairGap FROM (
SELECT 
        
        [Job Number],
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [ASC Code]  ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],[asc code],
        [Sony Needs To Pay] from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
    AND ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')) as c
) AS TEMP
) AS B
ON A1.[Job Number] = B.[Job Number]


SELECT 
	[Job Number],
	MIN_CLAIM_DATE,
	MAX_CLAIM_DATE,
	DATEDIFF(DAY, MIN_CLAIM_DATE, MAX_CLAIM_DATE) AS _Gap_Max_Min_ClaimDate,


	CONVERT(DATE, [Repair Completed Date], 102) AS 'Repair completed date',

	DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), MAX_CLAIM_DATE) AS 'MAX claim date - Repair completed date',
	DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), MIN_CLAIM_DATE) AS 'MIN claim date - Repair completed date'

FROM B01_04_IT_WARRANTY_FINAL_DATA A
INNER JOIN (
	SELECT 
		[Job No], 
		MIN(CONVERT(DATE, [Claim Status Date], 102)) AS MIN_CLAIM_DATE, 
		MAX(CONVERT(DATE, [Claim Status Date], 102)) AS MAX_CLAIM_DATE

	FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
	WHERE [Claim Status] = 'RC Submit'
	GROUP BY [Job No]
	HAVING COUNT(DISTINCT CONVERT(DATE, [Claim Status Date], 102)) > 1
)B
	ON A.[Job Number] = B.[Job No]
AND SEQ = 1
ORDER BY 'MAX claim date - Repair completed date' DESC


-- LOGIC 
/*
With Jobs found Claim and Warranty get the Jobs with Claim status Submit.

For each Job get max Claim status date.

*/

-- SECTION 9 
-- Step 1/ Get Claim status date from Claim data
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_CLAIM_STATUS_DATE DATE
UPDATE A
SET ZF_CLAIM_STATUS_DATE = MAX_CLAIM_DATE
FROM B01_04_IT_WARRANTY_FINAL_DATA A
INNER JOIN 
		(
			SELECT 
				DISTINCT [Job No], MAX(CONVERT(DATE, [Claim Status Date], 102)) AS MAX_CLAIM_DATE
			FROM 	CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
			WHERE [Claim Status] = 'RC Submit'
			GROUP BY [Job No]

		)B
	ON A.[Job Number] = B.[Job No]
-- Step 2 / Add filter calculated day gaps
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED = DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), ZF_CLAIM_STATUS_DATE)

-- Step 3 / Add filter if gap >= 33 days
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 NVARCHAR(3)


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'Yes'
WHERE ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 33

-- Step 4 / Add day gap bucket

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_BUCKET NVARCHAR(20);

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_BUCKET = 

	CASE
			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 33
				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 59 THEN '1.33 -> 59 days'
			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 60
				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 89 THEN '2.60 -> 89 days'
			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 90
				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 119 THEN '3.90 -> 119 days'
			ELSE '4.>= 120 days'
		END
WHERE ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'Yes'



/*
-- Check 

SELECT 
	[Job Number],
	MIN_CLAIM_DATE,
	MAX_CLAIM_DATE,
	DATEDIFF(DAY, MIN_CLAIM_DATE, MAX_CLAIM_DATE) AS _Gap_Max_Min_ClaimDate,


	CONVERT(DATE, [Repair Completed Date], 102) AS 'Repair completed date',

	DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), MAX_CLAIM_DATE) AS 'MAX claim date - Repair completed date',
	DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), MIN_CLAIM_DATE) AS 'MIN claim date - Repair completed date'

FROM B01_04_IT_WARRANTY_FINAL_DATA A
INNER JOIN (
	SELECT 
		[Job No], 
		MIN(CONVERT(DATE, [Claim Status Date], 102)) AS MIN_CLAIM_DATE, 
		MAX(CONVERT(DATE, [Claim Status Date], 102)) AS MAX_CLAIM_DATE

	FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
	WHERE [Claim Status] = 'RC Submit'
	GROUP BY [Job No]
	HAVING COUNT(DISTINCT CONVERT(DATE, [Claim Status Date], 102)) > 1
)B
	ON A.[Job Number] = B.[Job No]
AND SEQ = 1
ORDER BY 'MAX claim date - Repair completed date' DESC


SELECT 
    [Job Number],
	[Sony Needs To Pay],
	[Repair Completed Date],
	[Inspection Fee],
	[Install Fee],
	[Labor Fee],
	[Part Fee],
    [DA Fee],
    [MU Fee],
    [Install Fee],
    [Handling Fee] ,
    [Fit/Unfit Fee],
    [Adjustment Fee],
    [Travel Allowance Fee],*
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Job Number] in ( 'J11774292'
)
and seq = 1

SELECT [Job No], [Claim Status Date],  [Claim Amount], [Tax Amount], [Fee Type],[Claim Status], *
FROM CLAIM_FULL_DATA_REMOVED_DUP
WHERE [Job No] IN ( 'J11774292'
)




-- LOGIC 
/*
With Jobs found Claim and Warranty get the Jobs with Claim status Submit.

For each Job get max Claim status date.

*/

-- SECTION 9 
-- Step 1/ Get Claim status date from Claim data
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_CLAIM_STATUS_DATE DATE
UPDATE A
SET ZF_CLAIM_STATUS_DATE = MAX_CLAIM_DATE
FROM B01_04_IT_WARRANTY_FINAL_DATA A
INNER JOIN 
		(
			SELECT 
				DISTINCT [Job No], MAX(CONVERT(DATE, [Claim Status Date], 102)) AS MAX_CLAIM_DATE
			FROM 	CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
			WHERE [Claim Status] = 'RC Submit'
			GROUP BY [Job No]

		)B
	ON A.[Job Number] = B.[Job No]
-- Step 2 / Add filter calculated day gaps
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED = DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), ZF_CLAIM_STATUS_DATE)

-- Step 3 / Add filter if gap >= 33 days
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 NVARCHAR(3)


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'Yes'
WHERE ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 33

-- Step 4 / Add day gap bucket

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_BUCKET NVARCHAR(20);

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_BUCKET = 

	CASE
			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 33
				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 59 THEN '1.33 -> 59 days'
			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 60
				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 89 THEN '2.60 -> 89 days'
			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 90
				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 119 THEN '3.90 -> 119 days'
			ELSE '4.>= 120 days'
		END
WHERE ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'Yes'


SELECT YEAR([Repair Completed Date]), MONTH([Repair Completed Date]), COUNT(DISTINCT [Job Number]) A
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'Yes'
and [ASC Name] = N'TTBH Th? Ð?c'
GROUP BY YEAR([Repair Completed Date]), MONTH([Repair Completed Date])
ORDER BY A DESC



SELECT 

	CASE
		WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 33
			AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 59 THEN '1.33 -> 59 days'
		WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 60
			AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 89 THEN '2.60 -> 89 days'
		WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 90
			AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 119 THEN '3.90 -> 119 days'
		ELSE '4.>= 120 days'
	END,
	COUNT(DISTINCT [Job Number])
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'YES'
GROUP BY 
	CASE
		WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 33
			AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 59 THEN '33 -> 59'
		WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 60
			AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 89 THEN '60 -> 89'
		WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 90
			AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 119 THEN '90 -> 119'
		ELSE '>= 120'
	END





--1994
SELECT 
	DISTINCT 
		COUNT(DISTINCT [Job Number]) A, 
		DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), MAX_CLAIM_DATE) AS DIFF
FROM B01_04_IT_WARRANTY_FINAL_DATA  A
	INNER JOIN 
		(
			SELECT 
				DISTINCT [Job No], MAX(CONVERT(DATE, [Claim Status Date], 102)) AS MAX_CLAIM_DATE
			FROM 	CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
			WHERE [Claim Status] = 'RC Submit'
			GROUP BY [Job No]

		)B
	ON A.[Job Number] = B.[Job No]
WHERE ZF_CLAIM_STATUS_FLAG IN (  'SUBMIT', 'Submit and Rejected/Canceled')
GROUP BY DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), MAX_CLAIM_DATE)





SELECT COUNT(DISTINCT [Job Number])
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_CLAIM_STATUS_FLAG IN (  'SUBMIT', 'Submit and Rejected/Canceled')


SELECT DISTINCT ZF_CLAIM_STATUS_FLAG
FROM B01_04_IT_WARRANTY_FINAL_DATA





-- Check
-- 33479

SELECT COUNT(DISTINCT [Job ID])
FROM ['FY23-1HFY24$']
WHERE [Job ID] IN
(
	SELECT DISTINCT [Job Number]
	FROM B01_04_IT_WARRANTY_FINAL_DATA

)

/*
Repaired
Scrap

*/

SELECT 
	DISTINCT *
FROM ['FY23-1HFY24$']
WHERE [Job ID] = 'JC0103641'
ORDER BY Sequence



SELECT Invoice_part_code
FROM [03_Report sale- adjust out Z parts (Apr23 to Sep24)]
GROUP BY Invoice_part_code
HAVING COUNT(*) > 1


SELECT A.Invoice_part_code, B.INVOICE_PART_NO, A.ASC_QTY, B.NPC_QTY, ABS(A.ASC_QTY - B.NPC_QTY) A
FROM (
	SELECT Invoice_part_code, SUM(Invoice_part_qty) AS ASC_QTY
	FROM [03_Report sale- adjust out Z parts (Apr23 to Sep24)]
	GROUP BY Invoice_part_code
)A
INNER JOIN 
(
	SELECT INVOICE_PART_NO, SUM( CAST ( INVOICE_QTY AS INT)) AS NPC_QTY
	FROM [02_NPC_Purchase_Invoice_Apr23 to Sep24 1]
	GROUP BY INVOICE_PART_NO
)B
ON A.Invoice_part_code = B.INVOICE_PART_NO
WHERE ASC_QTY > NPC_QTY

ORDER BY A DESC



SELECT sum(CAST( INVOICE_QTY AS INT))
FROM [02_NPC_Purchase_Invoice_Apr23 to Sep24 1]
WHERE INVOICE_PART_NO = '147473121Z'

-- 620 NPC

-- 1073 ASC

SELECT SUM(Invoice_part_qty)
FROM [03_Report sale- adjust out Z parts (Apr23 to Sep24)]
WHERE Invoice_part_code = '147473121Z'


-- Check in warranty data ?
--


SELECT *
FROM 

--147473121Z

SELECT *
FROM [03_Report sale- adjust out Z parts (Apr23 to Sep24)]
WHERE Invoice_part_code = '147473121Z'


SELECT MIN([Repair Completed Date]), MAX([Repair Completed Date])
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [ASC Name] = 'RH Tuan Khang'
AND [Job Number] NOT IN 
(
	
	SELECT DISTINCT [Job ID]
	FROM ['FY23-1HFY24$']
)



-	01_R data: Data for spare parts returned to Sony’s Warehouse from RH (repaired & non-repairable).

-	02_NPC Purchase Invoice: NPC purchase refurbished spare parts from RH 
-	03_Report Sale: ASC purchase refurbished spare parts from NPC.

-- 01 : NPC TO ASC : 0

-- 03 WITH WARRANTY DATA " PRICE
-- 02 _ 03 QTY AFTER AFTER WARRANTY DATA : COMPARE WITH QTY 01 : STATUS REPAIRED

-- 2 pm : 



select *
from ['FY23-1HFY24$']

-	04_Z_parts mapping list: Mapping list to map the refurbished part number to the product model. 

-- In 03 take price per part (_
-- compare with price in warranty data

-- maybe same model code ?


SELECT *
FROM [03_Report sale- adjust out Z parts (Apr23 to Sep24)]
WHERE Invoice_part_code = 'A2201069AZ'

SELECT [Model Code], [Model Name], [Warranty Type], ZF_TOTAL_SONY_NEEDS_TO_PAY, [ASC pay], [Caused by customer]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Model Code] LIKE '%A2201069%' AND [Warranty Type] = 'IW'
AND SEQ = 1

-- Link 03 data with warranty : Compare Invoice price compare with part fee

-- In warranty type IW and Part fee > 0

-- Let me check it




*/


---- Requestion from Jesper 2025-02-17 add Claim amount for Part fee ----------------------------------------------

SELECT *
FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT

-- 261215

SELECT [Job No], ZF_PART_RETURN, AVG([Claim Amount]) AS ZF_AVG_PART_CLAIM_AMOUNT
INTO CLAIM_DATA_GROUP_PART_CODE_JOB_AVG_CLAIM
FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
WHERE  [Claim Status] = 'RC Submit'
AND [Fee Type] = 'Part Fee'
AND [Job No] IN (

SELECT 
	DISTINCT [Job Number]
FROM B01_04_IT_WARRANTY_FINAL_DATA

)
AND ZF_PART_RETURN IS NOT NULL
GROUP BY [Job No], ZF_PART_RETURN


ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT ADD ZF_PART_CODE_AVG_CLAIM_AMOUNT FLOAT

UPDATE A
SET ZF_PART_CODE_AVG_CLAIM_AMOUNT = B.ZF_AVG_PART_CLAIM_AMOUNT
FROM B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT A 
INNER JOIN CLAIM_DATA_GROUP_PART_CODE_JOB_AVG_CLAIM B 
ON A.[Job Number] = B.[Job No]
AND A.[Part Code] = B.ZF_PART_RETURN


-- Question 1 

SELECT [Job No], [Part Return]
FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
WHERE [Fee Type] = 'Part Fee'
AND [Claim Status] = 'RC SUBMIT'
AND [Job No] IN 
(
	SELECT DISTINCT [Job Number] FROM B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT 
)
GROUP BY [Job No], [Part Return]
HAVING COUNT(*) > 1
and count(*) = 2
-- Example 1

SELECT [Job Number],[Part Code], [Part Unit Price], ZF_PART_CODE_AVG_CLAIM_AMOUNT,[Sony Needs To Pay], ZF_TOTAL_SONY_NEEDS_TO_PAY,[Part Fee],*
FROM B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT
WHERE [Job Number] = 'JB0070205'


SELECT [Job No],[Fee Type],ZF_PART_RETURN, [Claim Amount],[Tax Amount],[Claim Status] , *
FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
WHERE 
 [Claim Status] = 'RC SUBMIT'
AND  [Job No] IN ('JB0070205')

SELECT *
FROM CLAIM_DATA_GROUP_PART_CODE_JOB_AVG_CLAIM
WHERE  [Job No] IN ('JB0070205')



-- Example 2

SELECT [Job Number],[Part Code], [Part Unit Price], ZF_PART_CODE_AVG_CLAIM_AMOUNT,[Sony Needs To Pay], ZF_TOTAL_SONY_NEEDS_TO_PAY,[Part Fee],*
FROM B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT
WHERE [Job Number] = 'JC0103841'


SELECT [Job No],[Fee Type],ZF_PART_RETURN, [Claim Amount],[Tax Amount],[Claim Status] , *
FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
WHERE 
 [Claim Status] = 'RC SUBMIT'
AND  [Job No] IN ('JC0103841')

SELECT *
FROM CLAIM_DATA_GROUP_PART_CODE_JOB_AVG_CLAIM
WHERE  [Job No] IN ('JC0103841')

-- Example 3










SELECT [Job No], [Part Return]
FROM CLAIM_FULL_DATA_REMOVED_DUP
WHERE [Fee Type] = 'Part Fee'
AND [Claim Status] = 'RC SUBMIT'
AND [Job No] IN 
(
	SELECT DISTINCT [Job Number] FROM B01_04_IT_WARRANTY_FINAL_DATA 
)
GROUP BY [Job No], [Part Return]
HAVING COUNT(*) > 1

-- 10,578

SELECT [Part Code], [Part Unit Price], ZF_PART_CODE_AVG_CLAIM_AMOUNT,[Sony Needs To Pay], ZF_TOTAL_SONY_NEEDS_TO_PAY,[Part Fee],*
FROM B01_04_IT_WARRANTY_FINAL_DATA_SUBMIT
WHERE [Job Number] = 'JB0045743'


-- 1,322,145
-- 6,963,000

SELECT [Part Return],ZF_PART_RETURN, [Claim Amount],[Claim Status], [Tax Amount], *
FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
WHERE [Fee Type] = 'PART FEE'
AND [Claim Status] = 'RC SUBMIT'
AND  [Job No] IN ('JB0045743')



-- 2000		000
SELECT *
FROM CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
WHERE [Job No] IN ('JB0045743', 'JB0076750')
GO
