USE [DIVA_SOTHAI_WARRANTY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROC [dbo].[B01_HANLDE_DATA_FOR_SOTHAI_WARRANTY]

AS

------------------------------------- HANDLE DATA ------------------------------------------------------------------------------------------------
-- Step 1 / 
-- Related to update new data before hanlding. / Need to Z_Repairset_SEV_FULL some main column is null to blank.
-- Related to null value date


SELECT * FROM SOTHAI_WARRANTY_RAW

UPDATE SOTHAI_WARRANTY_RAW
SET
	[Adjustment Fee] =    ISNULL ( [Adjustment Fee] , '')   ,
	[Assigned_by] =    ISNULL ( [Assigned_by] , '')   ,
	[Begin Repair Date] =    ISNULL ( [Begin Repair Date] , '')   ,
	[CCC_ID] =    ISNULL ( [CCC_ID] , '')   ,
	[Condition_code] =    ISNULL ( [Condition_code] , '')   ,
	[Customer_Complaint] =    ISNULL ( [Customer_Complaint] , '')   ,
	[DA Fee] =    ISNULL ( [DA Fee] , '')   ,
	[Dealer Name] =    ISNULL ( [Dealer Name] , '')   ,
	[Defect Code] =    ISNULL ( [Defect Code] , '')   ,
	[EMAIL] =    ISNULL ( [EMAIL] , '')   ,
	[ESTIMATION_TAT] =    ISNULL ( [ESTIMATION_TAT] , '')   ,
	[FIRST_ESTIMATION_CREATE_DATE] =    ISNULL ( [FIRST_ESTIMATION_CREATE_DATE] , '')   ,
	[Fit/Unfit Fee] =    ISNULL ( [Fit/Unfit Fee] , '')   ,
	[Handling Fee] =    ISNULL ( [Handling Fee] , '')   ,
	[Home Service Fee] =    ISNULL ( [Home Service Fee] , '')   ,
	[Inspection Fee] =    ISNULL ( [Inspection Fee] , '')   ,
	[Install Fee] =    ISNULL ( [Install Fee] , '')   ,
	[internal message] =    ISNULL ( [internal message] , '')   ,
	[IRIS_Line_Transfer_flag] =    ISNULL ( [IRIS_Line_Transfer_flag] , '')   ,
	[Labor Fee] =    ISNULL ( [Labor Fee] , '')   ,
	[LAST_ESTIMATION_DATE] =    ISNULL ( [LAST_ESTIMATION_DATE] , '')   ,
	[LATEST_ESTIMATE_STATUS] =    ISNULL ( [LATEST_ESTIMATE_STATUS] , '')   ,
	[LINKMAN] =    ISNULL ( [LINKMAN] , '')   ,
	[Long fee] =    ISNULL ( [Long fee] , '')   ,
	[MOBIL] =    ISNULL ( [MOBIL] , '')   ,
	[MU Fee] =    ISNULL ( [MU Fee] , '')   ,
	[Part Code] =    ISNULL ( [Part Code] , '')   ,
	[Part Desc] =    ISNULL ( [Part Desc] , '')   ,
	[Part Fee] =    ISNULL ( [Part Fee] , '')   ,
	[Part Unit Price] =    ISNULL ( [Part Unit Price] , '')   ,
	[Part_6D] =    ISNULL ( [Part_6D] , '')   ,
	[PARTS RECEIVED Date] =    ISNULL ( [PARTS RECEIVED Date] , '')   ,
	[PARTS_REQUEST_DATE] =    ISNULL ( [PARTS_REQUEST_DATE] , '')   ,
	[PARTS_WAITING_TAT] =    ISNULL ( [PARTS_WAITING_TAT] , '')   ,
	[PHONE] =    ISNULL ( [PHONE] , '')   ,
	[PO Create Date] =    ISNULL ( [PO Create Date] , '')   ,
	[PO NO] =    ISNULL ( [PO NO] , '')   ,
	[POST_CODE] =    ISNULL ( [POST_CODE] , '')   ,
	[Product Category] =    ISNULL ( [Product Category] , '')   ,
	[Product Sub Category] =    ISNULL ( [Product Sub Category] , '')   ,
	[PROVINCE] =    ISNULL ( [PROVINCE] , '')   ,
	[Purchased Date] =    ISNULL ( [Purchased Date] , '')   ,
	[Repair Action/Technician Remarks] =    ISNULL ( [Repair Action/Technician Remarks] , '')   ,
	[Repair Code] =    ISNULL ( [Repair Code] , '')   ,
	[Repair Fee Type] =    ISNULL ( [Repair Fee Type] , '')   ,
	[Repair Qty] =    ISNULL ( [Repair Qty] , '')   ,
	[Repair Returned Date] =    ISNULL ( [Repair Returned Date] , '')   ,
	[Reservation Create Date] =    ISNULL ( [Reservation Create Date] , '')   ,
	[reserve_id] =    ISNULL ( [reserve_id] , '')   ,
	[Section Code] =    ISNULL ( [Section Code] , '')   ,
	[Service Type] =    ISNULL ( [Service Type] , '')   ,
	[Shipped Date] =    ISNULL ( [Shipped Date] , '')   ,
	[Symptom Code] =    ISNULL ( [Symptom Code] , '')   ,
	[Symptom_Confirmed_By_Technician] =    ISNULL ( [Symptom_Confirmed_By_Technician] , '')   ,
	[transfer_job_no] =    ISNULL ( [transfer_job_no] , '')   ,
	[Travel Allowance Fee] =    ISNULL ( [Travel Allowance Fee] , '')   ,
	[vendor Part Price] =    ISNULL ( [vendor Part Price] , '')   ,
	[Warranty Card No] =    ISNULL ( [Warranty Card No] , '')   


-- Step 1.2 Update the date column only

UPDATE SOTHAI_WARRANTY_RAW
SET	[Job Create Date]=    ISNULL ([Job Create Date] , ''  ) ,
	[First Allocation Date]=    ISNULL ([First Allocation Date] , ''  ) ,
	[Begin Repair Date]=    ISNULL ([Begin Repair Date] , ''  ) ,
	[Repair Completed Date]=    ISNULL ([Repair Completed Date] , ''  ) ,
	[Repair Returned Date]=    ISNULL ([Repair Returned Date] , ''  ) ,
	[PO Create Date]=    ISNULL ([PO Create Date] , ''  ) ,
	[Shipped Date]=    ISNULL ([Shipped Date] , ''  ) ,
	[PARTS RECEIVED Date]=    ISNULL ([PARTS RECEIVED Date] , ''  ) ,
	[LAST Allocation Date]=    ISNULL ([LAST Allocation Date] , ''  ) ,
	[FIRST_ESTIMATION_CREATE_DATE]=    ISNULL ([FIRST_ESTIMATION_CREATE_DATE] , ''  ) ,
	[LAST_ESTIMATION_DATE]=    ISNULL ([LAST_ESTIMATION_DATE] , ''  ) ,
	[PARTS_REQUEST_DATE]=    ISNULL ([PARTS_REQUEST_DATE] , ''  ) ,
	[LAST_STATUS_UPDATE_DATE]=    ISNULL ([LAST_STATUS_UPDATE_DATE] , ''  ) 


-- Step 1.3  Create table to store all information and change dat type for each column.

DROP TABLE IF EXISTS B01_01_TT_WARRANTY_DATA

SELECT 

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
	CONVERT(DATETIME, [Purchased Date], 102) as [Purchased Date],-- Convert datetime to Purchased Date column.
	[Warranty Type] , -- Warranty Type: There are 2 values: IW and OW: In Warranty and Out of Warranty
	[Warranty Category] , -- Warranty Category
	[Warranty Card No] , -- Warranty Card No
	[Warranty Card Type] ,-- Warranty Card Type
	[Technician] , -- Technician
    CONVERT(DATETIME, [Reservation Create Date], 102) as [Reservation Create Date],
    CONVERT(DATETIME, [Job Create Date], 102) as [Job Create Date],
    CONVERT(DATETIME, [First Allocation Date], 102) as [First Allocation Date],
    CONVERT(DATETIME, [Begin Repair Date], 102) as [Begin Repair Date], 
    CONVERT(DATETIME, [Repair Completed Date], 102) as [Repair Completed Date], 
	CONVERT(DATETIME, [Repair Returned Date], 102) as [Repair Returned Date],
	
	[Part Code] , -- Part Code
	[Part Desc] , -- Part Description
	[Repair Qty] , -- Repair quantity.
	CAST([Part Unit Price] as float) as [Part Unit Price] ,  --Part Unit Price
	[PO NO] ,
    CONVERT(DATETIME, [PO Create Date], 102) as [PO Create Date],
    CONVERT(DATETIME, [Shipped Date], 102) as [Shipped Date],
	CONVERT(DATETIME, [PARTS RECEIVED Date], 102) as [PARTS RECEIVED Date],
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
	CONVERT(DATETIME, [LAST Allocation Date], 102) as [LAST Allocation Date],
	CAST([vendor Part Price] as float) as [vendor Part Price] ,

	CONVERT(DATETIME, [FIRST_ESTIMATION_CREATE_DATE], 102) as [FIRST_ESTIMATION_CREATE_DATE],
	CONVERT(DATETIME, [LAST_ESTIMATION_DATE], 102) as [LAST_ESTIMATION_DATE],
   
	[ESTIMATION_TAT] ,
	[LATEST_ESTIMATE_STATUS] ,
	CONVERT(DATETIME, [PARTS_REQUEST_DATE], 102) as [PARTS_REQUEST_DATE],
	[PARTS_WAITING_TAT] ,
	CONVERT(DATETIME, [LAST_STATUS_UPDATE_DATE], 102) as [LAST_STATUS_UPDATE_DATE],
	
	-- Create Calendar Year, Fiscal Year, Calendar month based on request from Jesper.
	YEAR( CONVERT(DATETIME, [Repair Completed Date], 102)   ) AS ZF_CALENDAR_YEAR,
	MONTH(CONVERT(DATETIME, [Repair Completed Date], 102)  ) AS ZF_CALENDAR_MONTH,
	CASE 
	 
		WHEN YEAR( CONVERT(DATE, [Repair Completed Date], 102) ) = 2023 AND MONTH(  CONVERT(DATE, [Repair Completed Date], 102)  ) IN (1,2,3) THEN 2022
		WHEN  CONVERT(DATE, [Repair Completed Date], 102)  BETWEEN '2023-04-01' AND '2024-03-31' THEN 2023
		ELSE 2024
	END  AS ZF_FISCAL_YEAR,		
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
	[Updated by CCC User] ,
	[Dealer Name] ,
	-- Get exchange rate value convert from vnd to usd
	G.ZF_LOCAL_CURRENCY,
	G.ZF_EXCHANGE
INTO B01_01_TT_WARRANTY_DATA
FROM SOTHAI_WARRANTY_RAW A  -- Excel file name received from Jesper. It contains warranty data
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
		ON  YEAR([Repair Completed Date]) = G.ZF_YEAR


-- Step 1.4 Need to add ASC name based on excel file from YeanChoo

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_ASC_NAME_GROUP NVARCHAR(1000);

UPDATE A
SET ZF_ASC_NAME_GROUP = B.[ASC GROUP NAME]

FROM B01_01_TT_WARRANTY_DATA A
	INNER JOIN AM_ASC_CODE_MAPPING B 
		ON A.[ASC Code] = B.[ASC Code]
	

-- Step 2 /  Related to date bucket.
-- 2.1 Based on request from Jesper Add columns to calculate date bucket.
-- Check with An about buckets


ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_TAT_BUCKETS NVARCHAR(30); -- TAT buckets with TAT mean Turnaround Time of warranty.

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

-- 2.2 Repair Completed Date and Repair Returned Date Buckets.

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_COMPLETED_REPAIR_RETURNED_DATE_BUCKETS NVARCHAR(30); 

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

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_REPAIR_COMPLETED_LAST_UPDATE_DATE_BUCKETS NVARCHAR(30); 

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
-- Step 2.5  Update value for Job Create Date and Begin Repair Date Buckets.

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_JOB_CREATED_DATE_BEGIN_REP_DATE_BUCKETS NVARCHAR(30); 

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

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_JOB_CREATED_DATE_LAST_STATUS_UPDATE_DATE_BUCKETS NVARCHAR(30); 

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

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_BEGIN_REP_DATE_PARTS_REQUEST_DATE_BUCKETS NVARCHAR(30); 

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

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_RESERVATION_DATE_BEGIN_REPAIR_DATE NVARCHAR(30); 

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

-- 2.9 Purchased Date vs Reservation Create Date

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_PURCHASE_DATE_RESERVATION_DATE NVARCHAR(30); 

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_PURCHASE_DATE_RESERVATION_DATE =

	CASE
		WHEN YEAR([Purchased Date]) = 1900 OR YEAR([Reservation Create Date]) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Reservation Create Date])) > 365 THEN '10_>365days'
	END

-- 2.10 Purchased Date vs Job Created Date

ALTER TABLE B01_01_TT_WARRANTY_DATA ADD ZF_PURCHASE_DATE_JOB_CREATED_DATE NVARCHAR(30); 

UPDATE B01_01_TT_WARRANTY_DATA
SET ZF_PURCHASE_DATE_JOB_CREATED_DATE =

	CASE
		WHEN YEAR([Purchased Date]) = 1900 OR YEAR([Job Create Date]) = 1900 THEN '01_The day is empty'
		WHEN  ABS( DATEDIFF(DAY, [Purchased Date], [Job Create Date])) < 1 THEN '02_<1days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Job Create Date])) BETWEEN 1 AND 10 THEN '03_1-10days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Job Create Date])) BETWEEN 11 AND 20 THEN '04_11-20days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Job Create Date])) BETWEEN 21 AND 30 THEN '05_21-30days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Job Create Date])) BETWEEN 31 AND 60 THEN '06_31-60days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Job Create Date])) BETWEEN 61 AND 90 THEN '07_61-90days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Job Create Date])) BETWEEN 91 AND 180 THEN '08_91-180days'
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Job Create Date])) BETWEEN 181 AND 365 THEN '09_181-365days'	
		WHEN  ABS(DATEDIFF(DAY, [Purchased Date], [Job Create Date])) > 365 THEN '10_>365days'
	END

-- Step 3 / The purpose of adding a new flag column is to detect strange Serial numbers of product in the warranty data.
-- MoreOver add serial number flag if lenght of serial number is 7 or 15. ( Normal lenght of serial number)
-- Step 3.1 Define strange Serial numbers


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


-- Add 2 column to show customer complaint and repair action remark

SELECT 
DISTINCT 
	[Repair Action/Technician Remarks]
FROM B01_01_TT_WARRANTY_DATA
WHERE [Repair Action/Technician Remarks] <> ''


DROP TABLE B01_04_IT_WARRANTY_FINAL_DATA

SELECT *
INTO B01_04_IT_WARRANTY_FINAL_DATA
FROM B01_01_TT_WARRANTY_DATA

----------------------------------------------------------- UPDATE SERIAL NO ----------------------------------------









---------------------------------------------------------------------------------------- STRANGE OF SERIAL NUMBER -------------------------------------------

-- Just needs to add flag .

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_SERIAL_EMPTY_CONTAINT_NA NVARCHAR(3)



UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_SERIAL_EMPTY_CONTAINT_NA = 'Yes'
WHERE 	
(
		[Serial No] = ''  -- Empty
		OR LEN([Serial No]) = 0 -- Len = 0
		OR [Serial No] IS NULL -- IS NULL
		OR REPLACE([Serial No],' ','') LIKE '%NA%'
		OR REPLACE([Serial No],' ','')  LIKE '%N/A%'
)

--------------------------------------  4 Analysis of Re-repair and days gap less than 90 days with the same ASC code, Serial No, and Model code------------------
-- Step 4.1 Add job related to re-repair
--ZF_JOB_RELATED_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_RELATED_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG = 'Yes'
WHERE [Job Number]+cast([Repair Completed Date]as varchar) in
(  
	SELECT DISTINCT [Job Number] +cast([Repair Completed Date]as varchar)
	FROM (		
		SELECT 
				[Job Number],
				DATEDIFF(DAY, LAG([Repair Completed Date]) OVER 
					(PARTITION BY [Serial No],[Model Code], ZF_ASC_NAME_GROUP ORDER BY [Repair Completed Date]), [Repair Completed Date]) 
						AS RepairGap,[Repair Completed Date]
	FROM (
		SELECT 
			[Serial No],
			[Model Code],
			[Repair Completed Date],
			[Job Number],
			ZF_ASC_NAME_GROUP 
		FROM B01_04_IT_WARRANTY_FINAL_DATA
		WHERE  [Serial No] <> ''
		AND ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'
		and [Model Code] <> ''
    ) as c
) AS TEMP
WHERE RepairGap<=90

)

-- Step 4.2 Flag all Job related re-repair. Based on product and asc name.
--ZF_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG = 'Yes'
WHERE  CONCAT([Serial No],[Model Code],ZF_ASC_NAME_GROUP) IN
(
	SELECT DISTINCT CONCAT([Serial No],[Model Code],ZF_ASC_NAME_GROUP)
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE 
		ZF_JOB_RELATED_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG = 'Yes'
		AND [Serial No] <> ''
		AND ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'
		AND [Model Code] <> ''

)

-- 4.3 Add ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE day

--ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA add ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE = RepairGap
FROM B01_04_IT_WARRANTY_FINAL_DATA A1
INNER JOIN (
  SELECT DISTINCT [Job Number],RepairGap,[Repair Completed Date] FROM (
SELECT 
        
        [Job Number],
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], ZF_ASC_NAME_GROUP  ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,[Repair Completed Date]
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],ZF_ASC_NAME_GROUP,
        [Sony Needs To Pay] from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
	and ZF_PRODUCT_REPAIR_AGAIN_IN_SHORT_TERM_FLAG = 'Yes'
    --AND ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
	) as c
) AS TEMP
) AS B
ON A1.[Job Number] = B.[Job Number]
and A1.[Repair Completed Date] = B.[Repair Completed Date]

-------------------------- 5/ Analysis of Re-repair and days gap less than 90 days with the same Serial No, and Model code and different ASC code------------------------------


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
        LAG(ZF_ASC_CODE_NAME_COMBINE) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]) AS PreviousASCName,
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,ZF_ASC_CODE_NAME_COMBINE,[Serial No],[Model Code]
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],
         ZF_ASC_CODE_NAME_COMBINE from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
    --and  ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
    ) as c
) AS TEMP
WHERE RepairGap<90
and ZF_ASC_CODE_NAME_COMBINE <> PreviousASCName

)

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
        LAG(ZF_ASC_CODE_NAME_COMBINE) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]) AS PreviousASCName,
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,ZF_ASC_CODE_NAME_COMBINE,[Serial No],[Model Code]
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],
        ZF_ASC_CODE_NAME_COMBINE from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
    --AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
    ) as c
) AS TEMP
WHERE RepairGap<90
and ZF_ASC_CODE_NAME_COMBINE <> PreviousASCName

)
--and ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')


ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DAY_GAP_BETWEEN_REPAIR_COMPLETED_DATE_DIFF_ASC INT

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
        [Job Number],ZF_ASC_CODE_NAME_COMBINE
         from B01_04_IT_WARRANTY_FINAL_DATA
    where [Serial No] <> ''
    and [Model Code] <> ''
    and Seq = 1
    --and  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
	) as c
) AS TEMP
) AS B
ON A1.[Job Number] = B.[Job Number]



--------------------- 6 / Analysis of Re-repair same product and part code (start and end with A)-------------------

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
		--AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
		--AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
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
	--AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
	--AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
	 

)
AND [Serial No] <> ''
and [Model Code] <> ''
and LEFT( [Part Code],1) = 'A' AND  RIGHT( [Part Code],1) = 'A'
and [Part Unit Price] > 0
--AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
--AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'


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



---------------------------Analysis of Re-Repair--------------------------
---------------------------Analysis of Re-Repair same ASC--------------------------
---------------------------Analysis of Re-Repair same Part code--------------------------



-- Step 1 /  Re-repair full  
-- 1.1 



ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_RELATED_RE_REPAIR NVARCHAR(3)



UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR = 'Yes'
WHERE [Model Code]+[Serial No] IN
(
	
	SELECT [Model Code]+[Serial No] FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE --ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') AND 
		[Serial No] <> ''
		and [Model Code] <> ''
	GROUP BY [Model Code],[Serial No]
	HAVING COUNT(DISTINCT [Job Number]) >1
)
--AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
AND [Serial No] <> ''
AND [Model Code] <> ''


-- 1.2 / Update the date gap

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DAY_GAP_BETWEEN_RE_REPAIR INT


UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_DAY_GAP_BETWEEN_RE_REPAIR = RepairGap
FROM B01_04_IT_WARRANTY_FINAL_DATA A1
INNER JOIN (
  SELECT DISTINCT [Job Number],RepairGap FROM (
SELECT 
        
        [Job Number],
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code]  ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap
    FROM (
		SELECT 
			[Serial No],
			[Model Code],
			[Repair Completed Date],
			[Job Number]
        FROM B01_04_IT_WARRANTY_FINAL_DATA
    where 
	 ZF_JOB_RELATED_RE_REPAIR = 'Yes'
	 and seq =1
) as c
) AS TEMP
) AS B
ON A1.[Job Number] = B.[Job Number]

-- 1.3

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA DROP COLUMN ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS
ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS NVARCHAR(3)


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS = 'Yes'
WHERE  ZF_DAY_GAP_BETWEEN_RE_REPAIR <= 90
AND ZF_JOB_RELATED_RE_REPAIR = 'Yes'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS = 'Yes'
WHERE  CONCAT([Model Code], [Serial No]) IN 
(
	SELECT DISTINCT CONCAT([Model Code], [Serial No])
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS = 'Yes'

)
AND ZF_DAY_GAP_BETWEEN_RE_REPAIR IS NULL


---------------- same asc ------------------------------

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_RELATED_RE_REPAIR_SAME_ASC NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_SAME_ASC = 'No'



UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_SAME_ASC = 'Yes'
WHERE [Model Code]+[Serial No]+ZF_ASC_CODE_NAME_COMBINE IN
(
	
	SELECT [Model Code]+[Serial No]+ZF_ASC_CODE_NAME_COMBINE FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE --ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') AND 
		[Serial No] <> ''
		and [Model Code] <> ''
	GROUP BY [Model Code],[Serial No],ZF_ASC_CODE_NAME_COMBINE
	HAVING COUNT(DISTINCT [Job Number]) >1
)
--AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
AND [Serial No] <> ''
AND [Model Code] <> ''





ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_ASC INT


UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_ASC = RepairGap
FROM B01_04_IT_WARRANTY_FINAL_DATA A1
INNER JOIN (
  SELECT DISTINCT [Job Number],RepairGap FROM (
SELECT 
        
        [Job Number],
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code],ZF_ASC_CODE_NAME_COMBINE  ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],ZF_ASC_CODE_NAME_COMBINE
         from B01_04_IT_WARRANTY_FINAL_DATA
    where 
	 ZF_JOB_RELATED_RE_REPAIR_SAME_ASC = 'Yes'
	 and seq =1
) as c
) AS TEMP
) AS B
ON A1.[Job Number] = B.[Job Number]


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_ASC = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_ASC = 'Yes'
WHERE  ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_ASC <= 90
AND ZF_JOB_RELATED_RE_REPAIR_SAME_ASC = 'Yes'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_ASC = 'Yes'
WHERE  CONCAT([Model Code], [Serial No], ZF_ASC_CODE_NAME_COMBINE) IN 
(
	SELECT DISTINCT CONCAT([Model Code], [Serial No],ZF_ASC_CODE_NAME_COMBINE)
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_ASC = 'Yes'

)
AND ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_ASC IS NULL



------------------------- PART CODE

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_RELATED_RE_REPAIR_SAME_PART_CODE NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_SAME_PART_CODE = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_SAME_PART_CODE = 'Yes'
WHERE [Model Code]+[Serial No]+[Part Code] IN
(
	
	SELECT [Model Code]+[Serial No]+[Part Code] FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE -- ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') AND 
		[Serial No] <> ''
		and [Model Code] <> ''
		AND LEN([Part Code])>1
		--AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
	GROUP BY [Model Code],[Serial No],[Part Code]
	HAVING COUNT(DISTINCT [Job Number]) >1
)
--AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
AND [Serial No] <> ''
AND [Model Code] <> ''
AND LEN([Part Code])>1
--AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'



ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_PART_CODE INT


UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_PART_CODE = RepairGap
FROM B01_04_IT_WARRANTY_FINAL_DATA A1
INNER JOIN (
  SELECT DISTINCT [Job Number],RepairGap,Seq FROM (
SELECT 
        
        [Job Number],
        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code],[Part Code]  ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,
		LAG([Job Number]) OVER (PARTITION BY [Serial No],[Model Code],[Part Code]  ORDER BY [Repair Completed Date]) as previous_job,[Serial No],[Model Code],[Part Code],Seq
    FROM (SELECT 
        [Serial No],
        [Model Code],
        [Begin Repair Date],
        [Repair Completed Date],
        [Job Number],ZF_ASC_CODE_NAME_COMBINE,[Part Code],seq
         from B01_04_IT_WARRANTY_FINAL_DATA
    where 
     ZF_JOB_RELATED_RE_REPAIR_SAME_PART_CODE = 'Yes'

) as c
) AS TEMP
where ([Job Number] <> previous_job or previous_job is null)
) AS B
ON A1.[Job Number] = B.[Job Number]
and A1.Seq = B.Seq




UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_PART_CODE = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_PART_CODE = 'Yes'
WHERE  ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_PART_CODE <= 90
AND ZF_JOB_RELATED_RE_REPAIR_SAME_PART_CODE = 'Yes'




UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_PART_CODE = 'Yes'
where [Serial No]+[Model Code]+[Part Code] in
(
	select a.[Serial No]+a.[Model Code]+a.[Part Code] from (select distinct [Serial No],[Model Code],[Part Code] from B01_04_IT_WARRANTY_FINAL_DATA a
	where ZF_JOB_RELATED_RE_REPAIR_SAME_PART_CODE = 'Yes'
	and  ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_PART_CODE is null) as a
	inner join (select distinct [Serial No],[Model Code],[Part Code] from B01_04_IT_WARRANTY_FINAL_DATA
	where ZF_JOB_RELATED_RE_REPAIR_SAME_PART_CODE = 'Yes'
	and  ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_PART_CODE <90) as b
	on a.[Model Code] = b.[Model Code]
	and b.[Serial No] = a.[Serial No]
	AND a.[Part Code] = b.[Part Code]

)
and (ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_PART_CODE is null or ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_PART_CODE<90)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_PART_CODE = 'Yes'
WHERE  CONCAT([Model Code], [Serial No], [Part Code]) IN 
(
	SELECT DISTINCT CONCAT([Model Code], [Serial No],[Part Code])
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE ZF_JOB_RELATED_RE_REPAIR_LESS_THAN_90_DAYS_SAME_PART_CODE = 'Yes'

)
AND ZF_DAY_GAP_BETWEEN_RE_REPAIR_SAME_PART_CODE IS NULL


---------------------Product is not TV but use Home service-----------------------

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
    --AND  ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
)


--------------------Product is not TV

---------?????????????????????????????????????????????????????????????

-----------Trend Analysis of Product Exchanges: High-Risk Warranty Centers based on Sony need to pay by ASC--------------------

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA
ADD ZF_PRODUCT_RELATED_TV_EXCHANGE VARCHAR(3)

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
    AND [Sony Needs To Pay] > 0

)


------------Trend Analysis of Product Exchanges: High-Risk Warranty Centers based on Part fee---------------------------

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
    --AND ZF_CLAIM_STATUS_FLAG IN ('Pending','Submit and Rejected/Canceled','Submit')
	and [Part Fee] > 0--AND ZF_PART_FEE_CLAIM > 0

)


---------------Analysis of Gaps Between Repair Completed Date and Claim Status Date (= 33 Days)-----------------------

-- Step 1/ Get Claim status date from Claim data
--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_CLAIM_STATUS_DATE DATE
--UPDATE A
--SET ZF_CLAIM_STATUS_DATE = MAX_CLAIM_DATE
--FROM B01_04_IT_WARRANTY_FINAL_DATA A
--INNER JOIN 
--		(
--			SELECT 
--				DISTINCT [Job No], MAX(CONVERT(DATE, [Claim Status Date], 102)) AS MAX_CLAIM_DATE
--			FROM 	CLAIM_FULL_DATA_REMOVED_DUP_LIMIT
--			WHERE [Claim Status] = 'RC Submit'
--			GROUP BY [Job No]

--		)B
--	ON A.[Job Number] = B.[Job No]

---- Step 2 / Add filter calculated day gaps


--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED INT

--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED = DATEDIFF(DAY, CONVERT(DATE, [Repair Completed Date], 102), ZF_CLAIM_STATUS_DATE)

-- Step 3 / Add filter if gap >= 33 days
--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 NVARCHAR(3)


--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'No'


--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'Yes'
--WHERE ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 33

---- Step 4 / Add day gap bucket

--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_BUCKET NVARCHAR(20);

--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_BUCKET = 

--	CASE
--			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 33
--				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 59 THEN '1.33 -> 59 days'
--			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 60
--				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 89 THEN '2.60 -> 89 days'
--			WHEN ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED >= 90
--				AND ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED <= 119 THEN '3.90 -> 119 days'
--			ELSE '4.>= 120 days'
--		END
--WHERE ZF_DATE_GAP_MAX_CLAIM_REPAIR_COMPLETED_GREATER_33 = 'Yes'

---------------Products with =4 warranty repairs and Sony Paid > 500 USD at the Same Service Center--------------------



--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_REPAIR_4_TIME_SONY_PAID_GREATER_500 NVARCHAR(3)

--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_REPAIR_4_TIME_SONY_PAID_GREATER_500 = 'No'

--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_REPAIR_4_TIME_SONY_PAID_GREATER_500 = 'Yes'
--FROM B01_04_IT_WARRANTY_FINAL_DATA
--WHERE [Serial No]+[Model Code]+ZF_ASC_CODE_NAME_COMBINE IN 
--(
--	SELECT [Serial No]+[Model Code]+ZF_ASC_CODE_NAME_COMBINE
--	FROM B01_04_IT_WARRANTY_FINAL_DATA
--	WHERE [Serial No] <> ''
--	AND [Model Code] <> ''
--	--AND  ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
--	GROUP BY [Serial No], [Model Code], ZF_ASC_CODE_NAME_COMBINE
--	HAVING COUNT(DISTINCT [Job Number]) > 3 -- Same product same ASC code repair >= 4 time
--	AND SUM(ZF_TOTAL_SONY_NEEDS_TO_PAY * ZF_EXCHANGE) > 500
	   
--)


--AND  ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')

-----------Analysis of Re-repair same product and part code (End with Z or L)----------------------


-- 5.1 Add flag to calculated value in Qlik KPI flag based on Job, model, serial and part code.

--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_FLAG NVARCHAR(3)

--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'No'

---- 2273 records.
--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'Yes'
--WHERE [Job Number]+[Serial No]+[Model Code]+[PART CODE] IN (

--SELECT DISTINCT [Job Number]+[Serial No]+[Model Code]+[PART CODE]
--FROM (
--SELECT 
--    [Job Number],
--    LAG([Job Number]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]) AS PreviousJob,
--    DATEDIFF(DAY, 
--		LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]), 
--		[Repair Completed Date]
--		) AS RepairGap,
--		[Serial No],
--		[Model Code],
--		[PART CODE],
--		[Part Unit Price]
--FROM (
--SELECT 
--    [Serial No],
--    [Model Code],
--    [Repair Completed Date],
--    [Job Number],
--	[PART CODE],
--	[Part Unit Price]
--FROM B01_04_IT_WARRANTY_FINAL_DATA
--WHERE [Serial No] <> ''
--and [Model Code] <> ''
--and ZF_PART_NO_END_WITH_FLAG = 'Ends with Z/L'
--and [Part Unit Price] > 0
----AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
----AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
--)A
--)A
--WHERE A.[RepairGap] IS NOT NULL AND A.[RepairGap] >0
--)

---- Step 5.2 Add full line with Product and Part code re-repair

--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PRODUCT_PART_CODE_RE_REPAIR_FLAG NVARCHAR(3)

--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'No'

--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
--SET ZF_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'Yes'
--WHERE [Serial No]+[Model Code]+[PART CODE] IN
--(
--	SELECT 
--		DISTINCT [Serial No]+[Model Code]+[PART CODE]
--	FROM B01_04_IT_WARRANTY_FINAL_DATA
--	WHERE 
--	 ZF_JOB_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'Yes'
--	AND [Serial No] <> ''
--	and [Model Code] <> ''
--	and ZF_PART_NO_END_WITH_FLAG = 'Ends with Z/L'
--	and [Part Unit Price] > 0
--	--AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
--	--AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'
	 

--)
--AND [Serial No] <> ''
--and [Model Code] <> ''
--and ZF_PART_NO_END_WITH_FLAG = 'Ends with Z/L'
--and [Part Unit Price] > 0
----AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit')
----AND  ZF_PART_FEE_CLAIM_STATUS LIKE '%Submit%'


-- Step 5.3 Add day gap between current and prevoiues

--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_DAY_GAP_PRODUCT_PART_CODE_RE_REPAIR INT

--UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
--SET ZF_DAY_GAP_PRODUCT_PART_CODE_RE_REPAIR = RepairGap
--FROM B01_04_IT_WARRANTY_FINAL_DATA A1
--INNER JOIN (
--  SELECT DISTINCT [Job Number],RepairGap FROM (
--SELECT 
        
--        [Job Number],
--        DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code], [PART CODE] ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap
--    FROM (
--		SELECT 
--        [Serial No],
--		[Model Code], 
--		[PART CODE],
--        [Repair Completed Date],
--        [Job Number]
--        FROM B01_04_IT_WARRANTY_FINAL_DATA
--		WHERE 	 ZF_PRODUCT_PART_CODE_RE_REPAIR_FLAG = 'Yes'
	
	
--	) as c
--) AS TEMP
--) AS B
--ON A1.[Job Number] = B.[Job Number]





----------------------Product's Warranty Type ( OW --> IW)  & Region Reclassifications----------------
----------------------Product have Power issue but replace Panel-----------------------------


	-- Flag products that were repaired multiple times, moved between North and South

	ALTER TABLE  B01_04_IT_WARRANTY_FINAL_DATA ADD  ZF_SAME_PRODUCT_TRAVEL_FAR_DISTANCE NVARCHAR(3) 

	UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	SET ZF_SAME_PRODUCT_TRAVEL_FAR_DISTANCE = 'No'

	UPDATE A
	SET ZF_SAME_PRODUCT_TRAVEL_FAR_DISTANCE = 'Yes'
	FROM B01_04_IT_WARRANTY_FINAL_DATA A 
	INNER JOIN
	(
			SELECT 
		[Model Code],
		[Serial No],
		COUNT (DISTINCT [Job Number]) AS ZF_JOB_COUNT,
		COUNT (DISTINCT Region) AS ZF_REGION_COUNT
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	--WHERE   ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
	GROUP BY [Model Code],
		[Serial No]
	HAVING COUNT (DISTINCT [Job Number]) > 1 AND COUNT (DISTINCT Region) > 1
	) B ON A.[Model Code] = B.[Model Code] 
	AND A.[Serial No] = B.[Serial No]
	--WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 

	-- Add the movements of items based on Region and Repair Completed Date
	ALTER TABLE  B01_04_IT_WARRANTY_FINAL_DATA ADD  ZF_PRODUCT_MOVEMENT_BY_REGION NVARCHAR(max)
	
	UPDATE A
	SET A.ZF_PRODUCT_MOVEMENT_BY_REGION = B.ZF_PRODUCT_MOVEMENT_BY_REGION
	FROM B01_04_IT_WARRANTY_FINAL_DATA A 
	INNER JOIN
	(
		SELECT 
			[Model Code], 
			[Serial No],
			STRING_AGG(RegionName, ' -> ') WITHIN GROUP (ORDER BY [Repair Completed Date] ASC) AS ZF_PRODUCT_MOVEMENT_BY_REGION
		FROM 
			B01_04_IT_WARRANTY_FINAL_DATA
		WHERE ZF_SAME_PRODUCT_TRAVEL_FAR_DISTANCE = 'Yes' AND Seq = 1
		GROUP BY 
			[Model Code], 
			[Serial No]
	) B ON A.[Model Code] = B.[Model Code] 
	AND A.[Serial No] = B.[Serial No]
	--WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 



	-- Flag for repair jobs same product but reclassified from OW -> IW

	ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_SAME_PRODUCT_OW_2_IW NVARCHAR(3)

	UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	SET ZF_SAME_PRODUCT_OW_2_IW = 'No'

	UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	SET ZF_SAME_PRODUCT_OW_2_IW = 'Yes'
	FROM B01_04_IT_WARRANTY_FINAL_DATA AS A
	WHERE EXISTS (
		SELECT 1
		FROM (
			SELECT 
				*,
				LAG([Warranty Type]) OVER (
					PARTITION BY [Model Code], [Serial No]
					ORDER BY [Repair Completed Date]
				) AS [Previous Warranty Type]
			FROM 
			B01_04_IT_WARRANTY_FINAL_DATA AS B
			WHERE 
			--ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') AND 
			EXISTS ( 
						SELECT 1
						FROM B01_04_IT_WARRANTY_FINAL_DATA AS C
						WHERE --ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') AND 
						B.[Model Code] = C.[Model Code]
						AND B.[Serial No] = C.[Serial No]
						GROUP BY [Model Code], [Serial No]
						HAVING COUNT(DISTINCT [Warranty Type]) > 1 AND COUNT( [Job Number]) > 1
					) 
		) AS D
		WHERE [Previous Warranty Type] = 'OW'
		AND [Warranty Type] = 'IW'
		AND A.[Model Code] = D.[Model Code]
		AND A.[Serial No] = D.[Serial No] 
	) 

-- Step 2/ Need to remove when serial no contain NA.

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_SAME_PRODUCT_OW_2_IW = 'No'
WHERE ZF_SAME_PRODUCT_OW_2_IW = 'Yes'
AND 
(
	[Model Code] = ''
	OR 
	ZF_SERIAL_EMPTY_CONTAINT_NA = 'Yes'

)

-- Add IW and Previous is OW

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB = 'Yes'
WHERE CONCAT([Job Number], [Repair Completed Date]) IN (
	SELECT CONCAT([Job Number], [Repair Completed Date])
	FROM (
		SELECT 
			LAG([Warranty Type]) OVER (
							PARTITION BY [Model Code], [Serial No]
							ORDER BY [Repair Completed Date]
						) AS [Previous Warranty Type],
		[Model Code], [Serial No], [Repair Completed Date],	ZF_ROW_NUMBER_ID,
		[Warranty Type],ZF_SERIAL_EMPTY_CONTAINT_NA,ZF_SAME_PRODUCT_OW_2_IW, [Job Number]
		FROM B01_04_IT_WARRANTY_FINAL_DATA
		WHERE CONCAT([Serial No], [Model Code]) IN (
			SELECT 
				CONCAT([Serial No], [Model Code])
			FROM B01_04_IT_WARRANTY_FINAL_DATA
			GROUP BY [Serial No], [Model Code]
			HAVING COUNT(DISTINCT [Warranty Type]) > 1

		)
	)A
	WHERE A.[Warranty Type] = 'IW'
	AND [Previous Warranty Type] = 'OW' 
	AND ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'

)

-- 91 Line. Step 2 / Add yes in case if OW-> IW -> IW
UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB = 'Yes'
WHERE CONCAT([Serial No], [Model Code], ZF_ROW_NUMBER_ID ) IN (

SELECT 
	DISTINCT CONCAT([Serial No], [Model Code], max(ZF_ROW_NUMBER_ID) + 1)
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB = 'Yes'
group by [Serial No], [Model Code]

)
AND ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'
AND ZF_SAME_PRODUCT_OW_2_IW = 'Yes'
AND [Warranty Type] = 'IW'
AND ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB = 'No'



UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_SAME_PRODUCT_OW_2_IW = 'Yes'
WHERE ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB = 'Yes'
AND ZF_SAME_PRODUCT_OW_2_IW = 'No'



SELECT distinct [Service Type]
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] = '3800875'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB = 'Yes'
WHERE CONCAT([Serial No], [Model Code], ZF_ROW_NUMBER_ID ) IN (

SELECT 
	DISTINCT CONCAT( [Serial No], [Model Code], max(ZF_ROW_NUMBER_ID)+1)
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB = 'Yes'
group by [Serial No], [Model Code]

)
AND ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'
AND ZF_SAME_PRODUCT_OW_2_IW = 'Yes'
AND [Warranty Type] = 'IW'




SELECT 
	DISTINCT SUM([Sony Needs To Pay] * ZF_EXCHANGE)
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Warranty Type] = 'OW'
AND [Sony Needs To Pay] >0



select *
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Model Code] = ''




SELECT DISTINCT [Sony Needs To Pay]*ZF_EXCHANGE

FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_SAME_PRODUCT_OW_2_IW = 'YES'
and [Warranty Type] = 'OW'

--12516602
-- 4000551

select ZF_SAME_PRODUCT_OW_2_IW, ZF_SAME_PRODUCT_OW_2_IW_BASED_ON_JOB, [Warranty Type], [Repair Completed Date], [Job Number], [Sony Needs To Pay], [Account Payable By Customer]
from B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Serial No] = '3800776' AND [Model Code] = '18991702'



-- Flag for adjacent repair jobs same product but reclassified from OW -> IW

	ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_SAME_PRODUCT_OW_2_IW_FLAG NVARCHAR(3)

	UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	SET ZF_SAME_PRODUCT_OW_2_IW_FLAG = 'No'

	UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	SET ZF_SAME_PRODUCT_OW_2_IW_FLAG = 'Yes'
	FROM B01_04_IT_WARRANTY_FINAL_DATA AS A
	JOIN ( 
			SELECT *, 
					LAG([Warranty Type]) OVER (
							PARTITION BY [Model Code], [Serial No]
							ORDER BY [Repair Completed Date], [Job Number]
						) AS [Previous Warranty Type],
					LEAD([Warranty Type]) OVER (
							PARTITION BY [Model Code], [Serial No]
							ORDER BY [Repair Completed Date], [Job Number]
						) AS [Next Warranty Type]
			FROM B01_04_IT_WARRANTY_FINAL_DATA
			--WHERE ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
		) AS B
	ON A.[Model Code] = B.[Model Code]
	AND A.[Serial No] = B.[Serial No] 
	AND A.[Job Number] = B.[Job Number]
	AND A.[Warranty Type] = B.[Warranty Type]
	WHERE B.ZF_SAME_PRODUCT_OW_2_IW = 'Yes' 
		AND 
		(([Previous Warranty Type] = 'OW' AND B.[Warranty Type] = 'IW') OR
			([Next Warranty Type] = 'IW' AND B.[Warranty Type] = 'OW'))


	-- Add flag for jobs repair product have power issue but replace panel


	ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_POWER_ISSUE_BUT_REPLACE_PANEL NVARCHAR(3)

	UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
	SET ZF_POWER_ISSUE_BUT_REPLACE_PANEL = 'No'

	UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
	SET ZF_POWER_ISSUE_BUT_REPLACE_PANEL = 'Yes'
	WHERE ((dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE '%khong nguon%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%ko nguon%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%ko ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%không ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%k nguon%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%k ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%m?t nguon%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%mat ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%m?t ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%t?t ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%tat nguon%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%ko lên ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%không lên ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%khong len nguon%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%nguon khong hoat dong%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%ngu?n không ho?t d?ng%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%hong nguon%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%h?ng ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%không có ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%không vô ngu?n%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%nguon chap chon%' OR
			dbo.ReplaceMultipleSpaces(LOWER([Symptom_Confirmed_By_Technician])) LIKE N'%ngu?n ch?p ch?n%' ) 
			AND ([Repair Action/Technician Remarks] LIKE '%pannel%' OR [Repair Action/Technician Remarks] LIKE '%panel%')) 
			--AND ZF_CLAIM_STATUS_FLAG IN ('Submit and Rejected/Canceled','Submit') 
			AND [Repair Code] = '60 - REPLACEMENT'

	-- Create table
	CREATE TABLE ProductWarrantyDuration (
		ProductCategory VARCHAR(50),
		Duration INT
	);

	-- Insert data
	INSERT INTO ProductWarrantyDuration (ProductCategory, Duration)
	VALUES
	('', 24),
	('13PSSOFTACCY', 12),
	('07LCDTV', 24),
	('08DAV', 12),
	('BI', 12),
	('10PRINTER', 12),
	('10PVCACCY', 12),
	('08SEPCOMPO', 12),
	('08MICROHIFI', 12),
	('PROFESSIONAL MONITOR', 24),
	('09PA', 12),
	('07LCDTVACCY', 24),
	('11DVD', 12),
	('06BPJ', 12),
	('10CAM', 24),
	('BRC', 12),
	('10DSLR', 24),
	('06VAIO', 12),
	('08MIDIHIFI', 12),
	('08HTIB', 12),
	('11BDP', 12),
	('CREATIVE PRO', 24),
	('10DIOTHERS', 12),
	('05MEACCY', 12),
	('CC', 24),
	('06BPP', 24),
	('10DSC', 24),
	('PJ', 12),
	('03MSTK', 12),
	('06VAIOACCY', 12),
	('13PSHARDWARE', 12),
	('04EN', 12),
	('12MOBILEPHONE', 12);


	--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD [Warranty Expried Date] DATE;
	--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_WRONG_WARRANTY_TYPE NVARCHAR(30);
	--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_BLANK_PURCHASE_DATE NVARCHAR(3);
	--ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_NORMAL_CUSTOMER_FLAG NVARCHAR(3);

	--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	--SET [Warranty Expried Date] = DATEADD(month, Duration, [Purchased Date])
	--FROM B01_04_IT_WARRANTY_FINAL_DATA
	--LEFT JOIN ProductWarrantyDuration
	--ON [Product Category] = ProductCategory

	
	--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	--SET ZF_WRONG_WARRANTY_TYPE = 'Other'

	--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	--SET ZF_WRONG_WARRANTY_TYPE = 'OW: Expried Date < Begin Date'
	--FROM B01_04_IT_WARRANTY_FINAL_DATA
	--WHERE CONCAT([Model Code], [Serial No]) IN (

	--	SELECT CONCAT([Model Code], [Serial No])
	--	FROM B01_04_IT_WARRANTY_FINAL_DATA
	--	WHERE [Warranty Expried Date] < [Begin Repair Date] 
	--			AND [Purchased Date] <> '' 
	--			AND [Begin Repair Date] <> ''
	--			AND [Warranty Type] = 'OW'
	--			AND ZF_SAME_PRODUCT_OW_2_IW = 'Yes' 
	--	)


	--UPDATE B01_04_IT_WARRANTY_FINAL_DATA
	--SET ZF_WRONG_WARRANTY_TYPE = 'OW: Expried Date > Begin Date'
	--FROM B01_04_IT_WARRANTY_FINAL_DATA
	--WHERE CONCAT([Model Code], [Serial No]) IN (

	--	SELECT CONCAT([Model Code], [Serial No])
	--	FROM B01_04_IT_WARRANTY_FINAL_DATA
	--	WHERE [Warranty Expried Date] > [Begin Repair Date] 
	--			AND [Purchased Date] <> '' 
	--			AND [Begin Repair Date] <> ''
	--			AND [Warranty Type] = 'OW'
	--			AND ZF_SAME_PRODUCT_OW_2_IW = 'Yes' 
	--	)

	--UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
	--SET ZF_BLANK_PURCHASE_DATE = 'No'

	--UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
	--SET ZF_BLANK_PURCHASE_DATE = 'Yes' 
	--WHERE [Purchased Date] = ''

	--UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
	--SET ZF_NORMAL_CUSTOMER_FLAG = 'No'

	--UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
	--SET ZF_NORMAL_CUSTOMER_FLAG = 'Yes'
	--FROM B01_04_IT_WARRANTY_FINAL_DATA
	--WHERE CONCAT([Model Code], [Serial No]) IN (

	--	SELECT CONCAT([Model Code], [Serial No]) 
	--	FROM B01_04_IT_WARRANTY_FINAL_DATA
	--	WHERE ZF_SAME_PRODUCT_TRAVEL_FAR_DISTANCE = 'Yes'
	--	GROUP BY CONCAT([Model Code], [Serial No])
	--	HAVING COUNT(DISTINCT [Customer Group]) = 1 AND COUNT(DISTINCT [Job number]) > 1
	--)
	--AND [Customer Group] = 'Normal customer'











-- Question 1 / Related to ASC group 

SELECT *
FROM AM_ASC_CODE_MAPPING

SELECT 
	DISTINCT 
		[ASC CODE],
		[ASC Name],
		Z_Repair_Centre_Group

FROM B01_04_IT_WARRANTY_FINAL_DATA




-- WHERE Z_Repair_Centre_Group = 'SSC - Sony New Petchburin Service Center'

-- In all dashboard will show ASC group : Z_Repair_Centre_Group

-- Question 2 : 
SELECT 
	DISTINCT Z_Key, [Model Name], [Serial No]
FROM B01_04_IT_WARRANTY_FINAL_DATA

-- Question 3 : OW and sony still needs to pay

-- Show dashboard


-- Question 4 : SOTHAI dont have home service fee
-- Home Service

SELECT DISTINCT [Home Service Fee]
FROM B01_04_IT_WARRANTY_FINAL_DATA

-- Question 5 / Related to Strange of serial number.
-- SEV
-- Case 1 : Serial numbers contain only alphabetic characters, with no numeric digits.
-- Case 2 : Serial numbers are empty
-- Case 3 : Serial number values are the same as the model codes
-- Case 4 : Serial number values same PHONE/MOBIL
-- Case 5 : Serial numbers starting with VN or SVN.
-- Case 6 : Serial numbers have 3 to 5 characters


--- FOR SOTHAI

SELECT 
	[Serial No],
	SUM([Sony Needs To Pay] * ZF_EXCHANGE) AS 'Sony needs to pay USD'
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE 	
(
		[Serial No] = ''  -- Empty
		OR LEN([Serial No]) = 0 -- Len = 0
		OR [Serial No] IS NULL -- IS NULL
		OR REPLACE([Serial No],' ','') LIKE '%NA%'
		OR REPLACE([Serial No],' ','')  LIKE '%N/A%'
)
AND [Sony Needs To Pay] > 0

GROUP BY [Serial No]

SELECT 
	DISTINCT LEN([Serial No]), COUNT(DISTINCT [Serial No]) '# Jobs', SUM([Sony Needs To Pay] * ZF_EXCHANGE) as 'Sony needs to pay USD'
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Sony Needs To Pay] > 0
GROUP BY LEN([Serial No])
ORDER BY  SUM([Sony Needs To Pay] * ZF_EXCHANGE) DESC


SELECT 
	DISTINCT LEN([Serial No]), [Product Category] ,COUNT(DISTINCT [Serial No]) '# Jobs', SUM([Sony Needs To Pay] * ZF_EXCHANGE) as 'Sony needs to pay USD'
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE [Sony Needs To Pay] > 0
GROUP BY LEN([Serial No]), [Product Category]
ORDER BY LEN([Serial No]) DESC, SUM([Sony Needs To Pay] * ZF_EXCHANGE) DESC


SELECT DISTINCT [Serial No], [Job Number], [Model Name], *
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE LEN([Serial No]) = 17
and [Sony Needs To Pay] > 0


-- Question 5 / Related to re-repair



-- Update 2 field from raw data.


 ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD Z_Key NVARCHAR(1000)
 ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD Z_Repair_Centre_Group  NVARCHAR(1000)

  UPDATE A
  SET Z_Key = B.Z_Key,
	Z_Repair_Centre_Group = B.[Z_Repair Centre Group]
FROM B01_04_IT_WARRANTY_FINAL_DATA A
	INNER JOIN (

		SELECT DISTINCT  Z_Key, [Job Number], [Month], [Z_Repair Centre Group],[Repair Completed Date]
		FROM SOTHAI_WARRANTY_RAW

	)B
	ON A.[Job Number] = B.[Job Number]
	AND A.[Repair Completed Date] = B.[Repair Completed Date]



-- New dashboard from Lian,


ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_REPAIR_MOVED_DEALER_OTHER_DEALER NVARCHAR(3)


UPDATE A
SET ZF_REPAIR_MOVED_DEALER_OTHER_DEALER = 'Yes'
FROM B01_04_IT_WARRANTY_FINAL_DATA A 
WHERE CONCAT( [Serial No], [Model Code]) IN 

(
	SELECT DISTINCT  CONCAT( [Serial No], [Model Code])
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE
		[Customer Group] = 'Dealer'
		AND [Serial No] <> ''
		AND [Model Code] <> ''
		AND ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'
		AND COALESCE(NULLIF(MOBIL, ''), PHONE) <> ''  
	GROUP BY [Serial No], [Model Code]
	HAVING COUNT(DISTINCT UPPER(COALESCE(NULLIF(MOBIL, ''), PHONE))) > 1
		AND  COUNT(DISTINCT [Job Number]) > 1
)
AND [Customer Group] = 'Dealer'
AND [Serial No] <> ''
AND [Model Code] <> ''
AND COALESCE(NULLIF(MOBIL, ''), PHONE) <> ''
AND ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'

--- 


ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_CUSTOMER_NAME_IS_ASC_NAME NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_CUSTOMER_NAME_IS_ASC_NAME ='No'




SELECT DISTINCT CUSTOMER_NAME,
	CASE 
		WHEN CUSTOMER_NAME LIKE '%ASC%' OR
			CUSTOMER_NAME LIKE '%SSC%' OR 
			CUSTOMER_NAME LIKE '%supply%' OR
			CUSTOMER_NAME LIKE '%SMARTFIXED%' OR 
			CUSTOMER_NAME LIKE '%Fubiz Digital%'
	THEN 'YES'
	END

FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_REPAIR_MOVED_DEALER_OTHER_DEALER = 'YES'


------------------------------- Request from Jesper --- 2025-03-17 ------------------------------------------

-- Step 1 / Add flag gap between 

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_RE_REPAIR_GAP INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_RE_REPAIR_GAP = B.RepairGap

FROM B01_04_IT_WARRANTY_FINAL_DATA A
INNER JOIN 
(

	SELECT  [Model Code], [Serial No],
			DATEDIFF(DAY, LAG([Repair Completed Date]) OVER (PARTITION BY [Serial No],[Model Code]  
				ORDER BY [Repair Completed Date]), [Repair Completed Date]) AS RepairGap,
				[Repair Completed Date],
				[Job Number]
	FROM B01_04_IT_WARRANTY_FINAL_DATA

)B
ON A.[Job Number] = B.[Job Number]
AND A.[Repair Completed Date] = B.[Repair Completed Date]

-- Step 2 / Get line when day gap < 90 and warranty type = OW

SELECT ZF_RE_REPAIR_GAP, [Sony Needs To Pay], [ASC pay], [Total Amount Of Account Payable], [Account Payable By Customer],*
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE 
 [Warranty Type] = 'OW'
AND ZF_RE_REPAIR_GAP <= 90
AND 
(
	[Sony Needs To Pay] > 0
	OR [Account Payable By Customer] > 0

)

-- Add flag for case like that.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_RE_REPAIR_SONY_CUSTO_OW_PAY NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_RE_REPAIR_SONY_CUSTO_OW_PAY = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_RE_REPAIR_SONY_CUSTO_OW_PAY = 'Yes'
WHERE 
[Warranty Type] = 'OW'
AND ZF_RE_REPAIR_GAP <= 90
AND 
(
	[Sony Needs To Pay] > 0
	OR [Account Payable By Customer] > 0

)
and  ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'


-- Add flag to show all cases related to product.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_RE_REPAIR_SONY_CUSTO_OW_PAY_ALL_PRODUCT NVARCHAR(3)


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_RE_REPAIR_SONY_CUSTO_OW_PAY_ALL_PRODUCT = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_RE_REPAIR_SONY_CUSTO_OW_PAY_ALL_PRODUCT = 'Yes'
WHERE CONCAT([Serial No], [Model Code]) IN 
(
	SELECT DISTINCT CONCAT([Serial No], [Model Code])
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE ZF_RE_REPAIR_SONY_CUSTO_OW_PAY = 'Yes'

)

-- Add row number for each product

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_ROW_NUMBER_ID INT

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_ROW_NUMBER_ID = B.ROWID

FROM B01_04_IT_WARRANTY_FINAL_DATA A
INNER JOIN 
(

	SELECT  [Model Code], [Serial No],
			ROW_NUMBER() OVER(PARTITION BY [Serial No] , [Model Code] ORDER BY [Repair Completed Date] ASC)  as ROWID ,
				[Repair Completed Date],
				[Job Number]
	FROM B01_04_IT_WARRANTY_FINAL_DATA

)B
ON A.[Job Number] = B.[Job Number]
AND A.[Repair Completed Date] = B.[Repair Completed Date]


ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_RE_REPAIR_IW_OW_FLAG NVARCHAR(30)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA
SET ZF_RE_REPAIR_IW_OW_FLAG = 'IW --> OW'
WHERE CONCAT([Serial No], [Model Code]) IN (

SELECT 
	DISTINCT CONCAT([Serial No], [Model Code])
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE CONCAT([Serial No], [Model Code], ZF_ROW_NUMBER_ID) IN (

SELECT 
	CONCAT([Serial No], [Model Code], ZF_ROW_NUMBER_ID-1)
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_RE_REPAIR_SONY_CUSTO_OW_PAY = 'Yes'

)
)







SELECT 
	DISTINCT [Serial No], [Model Code], COUNT(DISTINCT [Purchased Date]) A
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'
GROUP BY [Serial No], [Model Code]
HAVING COUNT(DISTINCT [Purchased Date]) > 1
ORDER BY A DESC


-- Step 1 / Add flag to show same product but have mul purchased date.

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_SAME_PRODUCT_MUL_PURCHASE_DATE NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_SAME_PRODUCT_MUL_PURCHASE_DATE = 'No'


UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_SAME_PRODUCT_MUL_PURCHASE_DATE = 'Yes'
WHERE CONCAT([Serial No], [Model Code]) IN (


	SELECT 
		DISTINCT CONCAT([Serial No], [Model Code])
	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE ZF_SERIAL_EMPTY_CONTAINT_NA = 'No'
	GROUP BY [Serial No], [Model Code]
	HAVING COUNT(DISTINCT [Purchased Date]) > 1

)

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_PRODUCT_PURCHASE_DATE_EMPTY NVARCHAR(3)

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_PRODUCT_PURCHASE_DATE_EMPTY = 'No'

UPDATE B01_04_IT_WARRANTY_FINAL_DATA 
SET ZF_PRODUCT_PURCHASE_DATE_EMPTY = 'Yes'
WHERE ZF_SAME_PRODUCT_MUL_PURCHASE_DATE = 'Yes'
AND CONCAT([Serial No], [Model Code]) IN (

	SELECT DISTINCT CONCAT([Serial No], [Model Code])

	FROM B01_04_IT_WARRANTY_FINAL_DATA
	WHERE YEAR([Purchased Date]) = 1900
)


-- 405

SELECT 
	DISTINCT [Serial No], [Model Code], count(DISTINCT [Purchased Date]) A
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_PRODUCT_PURCHASE_DATE_EMPTY = 'yES'
AND ZF_SAME_PRODUCT_MUL_PURCHASE_DATE = 'Yes'
GROUP BY  [Serial No], [Model Code]
ORDER BY A DESC

ALTER TABLE B01_04_IT_WARRANTY_FINAL_DATA ADD ZF_NUMBER_OF_PURCHASE_DATE INT

SELECT [Serial No], [Model Code], COUNT(DISTINCT [Purchased Date]) A
FROM B01_04_IT_WARRANTY_FINAL_DATA
WHERE ZF_SAME_PRODUCT_MUL_PURCHASE_DATE = 'yES'
GROUP BY  [Serial No], [Model Code]
order by A DESC










GO
