USE [DIVA_TEST_PROGRESS]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[TEST_PROGRESS_3]
AS
BEGIN
--Step 1 Create a list of table, include only FY20 year
--And start with A_02( which means they are Template sheet)

	EXEC SP_DROPTABLE TT_TABLE_LIST
	SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
	TABLE_NAME
	INTO TT_TABLE_LIST
	FROM INFORMATION_SCHEMA.TABLES 
	WHERE TABLE_NAME LIKE 'A_03_FY20%'

--Step 2 Append all the table togerther to create a table that contains all the A_02 fields and data
--Step 2.1 Create a list of variable 
	EXEC SP_REMOVE_TABLES 'B_11_IT_%'


	DECLARE @tableVar1 NVARCHAR(MAX)
	DECLARE @tableVar2 NVARCHAR(MAX)
	DECLARE @quarter NVARCHAR(MAX)
	DECLARE @quarter1 NVARCHAR(MAX)
	DECLARE @FY NVARCHAR(MAX)
	DECLARE @vTableNum int
	SET @vTableNum = (SELECT COUNT(*) FROM TT_TABLE_LIST)

 --Step 2.2 Set the format from the raw excel data, then extract the data to new tables with new format

	DECLARE @NUM INT=1
-- DO the loop for each table from the list
	WHILE @NUM<=@vTableNum
	BEGIN 
	EXEC SP_DROPTABLE TEMP 

	SET @tableVar1=(SELECT TABLE_NAME FROM TT_TABLE_LIST WHERE number=@NUM)
	SET @tableVar2=(SELECT REPLACE(@tableVar1,'A_03_','')  FROM TT_TABLE_LIST WHERE number=@NUM)
	SET @quarter=(SELECT SUBSTRING(REPLACE(TABLE_NAME,'A_03_',''),1,CHARINDEX('_',REPLACE(TABLE_NAME,'A_03_',''))-1) FROM TT_TABLE_LIST WHERE number=@NUM)
	SET @quarter1=(SELECT CONCAT(SUBSTRING(TABLE_NAME,6,4),'_',SUBSTRING(TABLE_NAME,10,3))FROM TT_TABLE_LIST WHERE number=@NUM)
	SET @FY=(SELECT SUBSTRING(REPLACE(TABLE_NAME,'A_03_',''),1,4) FROM TT_TABLE_LIST WHERE number=@NUM)

	EXEC (
	'SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
	* INTO TEMP FROM [' + @tableVar1 +']'
	)


	EXEC 
	(' SELECT '''+
			@tableVar1 + ''' AS ''Origi'',
			F1 AS ''SOX Region/ Business'',
			F2 AS ''SOX Operating Company'',
			F3 AS ''Business Unit Name'',
			F4 AS ''Finding ID'',
			F5 AS ''Finding Name'',
			F6 AS ''Finding Description'',
			F7 AS ''SOX Process Type'',
			F8 AS ''SOX Finding Classification'',
			F9 AS ''Application Name(Optional)'',
			CAST(F10 AS NVARCHAR(MAX)) AS ''Created Date (DD/MM/Year)'',
			CAST(F11 AS NVARCHAR(MAX))  AS ''Risk Name'',
			F12 AS ''Risk Description'',
			F13 AS ''Local Control Name'',
			F14 AS ''Control Number'',
			F15 AS ''Control Description'',
			F16 AS ''Control Risk Rating'',
			F17 AS ''Business Process Name'',
			F18 AS ''Deficiency Type'',
			F19 AS ''Testing Phase'',
			F20 AS ''SOX Finding Status'',
			CAST(F21 AS NVARCHAR(MAX)) AS ''Date Deficiency Closed (after retest) (DD/MM/Year)'',
			CAST(F22 AS NVARCHAR(MAX)) ''Gross Impact (Local Amt)'',
			CAST(F23 AS NVARCHAR(MAX)) AS ''Target Completion Date (DD/MM/Year)'',
			CAST(F24 AS NVARCHAR(MAX))''Actual Completion Date (DD/MM/Year)'',
			F25 AS ''Action Plan'',
			F26 AS ''Action Owner'',
			'''+@quarter+''' AS Quarter_checking,
			'''+@quarter1+''' AS Quarter,
			'''+@FY+''' AS Fiscal_year,
			(SELECT F5 FROM TEMP WHERE F4=''Status Date'' ) AS ''Status_date''
	INTO B_11_IT_'+ @tableVar2 +' FROM TEMP 
	WHERE number >2 AND F1 IS NOT NULL AND F4 IS NOT NULL
	'
	)


	PRINT(@NUM)
	  EXEC SP_DROPTABLE TEMP 
	  EXEC SP_DROPTABLE TEMP1
	  EXEC SP_DROPTABLE TEMP2

	 SET @NUM=@NUM+1
	END
	

--Step 2.3 Get the new table name list
	EXEC SP_DROPTABLE TT_TABLE_LIST_1
	SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
	TABLE_NAME
	INTO TT_TABLE_LIST_1
	FROM INFORMATION_SCHEMA.TABLES 
	WHERE TABLE_NAME LIKE 'B_11_IT_%'
-- STep 2.4 Append the table together, base on the list of tables
	EXEC SP_DROPTABLE B_12_TT_SOX_TEST_FINAL
	Declare @SQL varchar(max) =''
	Select @SQL = @SQL +'Union All Select * From '+Table_Name+' ' 
	FROM TT_TABLE_LIST_1
	ORDER BY TABLE_NAME
	Set @SQL = Stuff(@SQL,1,10,'')

	SET @SQL=STUFF( @SQL,8,1,'* INTO B_12_TT_SOX_TEST_FINAL ')

	Exec(@SQL)

--FY21
--Do the same logic from step 2 to create another table which contains FY21 year

--Step 4 Create a list of table, include only FY21 year
--And start with A_02( which means they are Template sheet)
	EXEC SP_DROPTABLE TT_TABLE_LIST
	SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
	TABLE_NAME
	INTO TT_TABLE_LIST
	FROM INFORMATION_SCHEMA.TABLES 
	WHERE TABLE_NAME LIKE 'A_03_FY21%' OR   TABLE_NAME LIKE 'A_03_FY22%'
--Step 5 Append all the table togerther to create a table that contains all the A_02 fields and data
--Step 5.1 Create a list of variable 

	EXEC SP_REMOVE_TABLES 'B_13_IT_%'

	 set @vTableNum = (SELECT COUNT(*) FROM TT_TABLE_LIST)
	 SET @NUM=1

	WHILE @NUM<=@vTableNum
	BEGIN 
	EXEC SP_DROPTABLE TEMP 

	SET @tableVar1=(SELECT TABLE_NAME FROM TT_TABLE_LIST WHERE number=@NUM)
	SET @tableVar2=(SELECT REPLACE(@tableVar1,'A_03_','')  FROM TT_TABLE_LIST WHERE number=@NUM)
	SET @quarter=(SELECT SUBSTRING(REPLACE(TABLE_NAME,'A_03_',''),1,CHARINDEX('_',REPLACE(TABLE_NAME,'A_03_',''))-1) FROM TT_TABLE_LIST WHERE number=@NUM)
	SET @quarter1=(SELECT CONCAT(SUBSTRING(TABLE_NAME,6,4),'_',SUBSTRING(TABLE_NAME,10,3))FROM TT_TABLE_LIST WHERE number=@NUM)
	SET @FY=(SELECT SUBSTRING(REPLACE(TABLE_NAME,'A_03_',''),1,4) FROM TT_TABLE_LIST WHERE number=@NUM)


	EXEC (
	'SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
	* INTO TEMP FROM [' + @tableVar1 +']'
	)



	EXEC 
	(' SELECT '''+
			@tableVar1 + ''' AS ''Origi'',
			F1 AS ''SOX Region/ Business'',
			F2 AS ''SOX Operating Company'',
			F3 AS ''Business Unit Name'',
			F4 AS ''Finding ID'',
			F5 AS ''Finding Name'',
			F6 AS ''Finding Description'',
			F7 AS ''SOX Process Type'',
			F8 AS ''SOX Finding Classification'',
			F9 AS ''Application Name(Optional)'',
			CAST(F10 AS NVARCHAR(MAX)) AS ''Created Date (DD/MM/Year)'',
			CAST(F11 AS NVARCHAR(MAX))  AS ''Risk Name'',
			F12 AS ''Risk Description'',
			F13 AS ''Local Control Name'',
			F14 AS ''Control Number'',
			F15 AS ''Control Description'',
			F16 AS ''Control Risk Rating'',
			F17 AS ''Business Process Name'',
			F18 AS ''Deficiency Type'',
			F19 AS ''Testing Phase'',
			F20 AS ''SOX Finding Status'',
			CAST(F21 AS NVARCHAR(MAX)) AS ''Date Deficiency Closed (after retest) (DD/MM/Year)'',
			CAST(F22 AS NVARCHAR(MAX)) ''Gross Impact (Local Amt)'',
			CAST(F23 AS NVARCHAR(MAX)) AS ''Target Completion Date (DD/MM/Year)'',
			CAST(F24 AS NVARCHAR(MAX))''Actual Completion Date (DD/MM/Year)'',
			F25 AS ''Action Plan'',
			F26 AS ''Action Owner'',
			'''+@quarter+''' AS Quarter_checking,
			'''+@quarter1+''' AS Quarter,
			'''+@FY+''' AS Fiscal_year,
			(SELECT F5 FROM TEMP WHERE F4=''Status Date'' ) AS ''Status_date''
	INTO B_13_IT_'+ @tableVar2 +' FROM TEMP 
	WHERE number >2 AND F1 IS NOT NULL AND F4 IS NOT NULL
	'
	)

	PRINT(@NUM)
	  EXEC SP_DROPTABLE TEMP 
	  EXEC SP_DROPTABLE TEMP1
	  EXEC SP_DROPTABLE TEMP2

	 SET @NUM=@NUM+1
	END
	
--Step 5.2 Get the new table name list
	EXEC SP_DROPTABLE TT_TABLE_LIST_1
	SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
	TABLE_NAME
	INTO TT_TABLE_LIST_1
	FROM INFORMATION_SCHEMA.TABLES 
	WHERE TABLE_NAME LIKE 'B_13_IT_%'
--Step 5.3 Append the table together, base on the list of tables
	EXEC SP_DROPTABLE B_14_TT_SOX_TEST_FINAL

	SET @SQL=''

	Select @SQL = @SQL +'Union All Select * From '+Table_Name+' ' 
	  FROM TT_TABLE_LIST_1
	  ORDER BY TABLE_NAME
	Set @SQL = Stuff(@SQL,1,10,'')

	SET @SQL=STUFF( @SQL,8,1,'* INTO B_14_TT_SOX_TEST_FINAL ')
	Exec(@SQL)

--Update the text in SOX Operating Company to make sure it match with the mapping file (sometimes raw data dont match with the mapping)

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='SMP'
	WHERE [SOX Operating Company]='SATV/EMI'

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='Corp'
	WHERE [SOX Operating Company]='Sony Corp'

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='Bank'
	WHERE [SOX Operating Company]='Sony Bank'

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='Life'
	WHERE [SOX Operating Company]='Sony Life'

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='GDC-W'
	WHERE [SOX Operating Company]='GDC-W(GIS-AM)'

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='SIE Inc'
	WHERE [SOX Operating Company]='SIEInc'

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='SIELLC'
	WHERE [SOX Operating Company]='SIE LLC'

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Region/ Business]='GTO'
	WHERE [SOX Operating Company]='GTO'

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Region/ Business]='GDC-W'
	WHERE [SOX Operating Company]='GDC-W'
	--

	UPDATE B_12_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='SES(GISC AP)'
	WHERE [SOX Operating Company]='SES (GIS/HQ)'

	--
	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='SGC'
	WHERE [SOX Operating Company]='Sony Corp'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='SGC'
	WHERE [SOX Operating Company]='Corp'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='Bank'
	WHERE [SOX Operating Company]='Sony Bank'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='Life'
	WHERE [SOX Operating Company]='Sony Life'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Region/ Business]='SGC'
	WHERE [SOX Operating Company]='SGS'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Region/ Business]='SGC'
	WHERE [SOX Operating Company]='GISC AM'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Region/ Business]='SGC'
	WHERE [SOX Operating Company]='GTO'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='GISC AM'
	WHERE [SOX Operating Company]='GDC-W(GIS-AM)'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Region/ Business]='SGC'
	WHERE [SOX Operating Company]='GISC AM'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Region/ Business]='SGC'
	WHERE [SOX Operating Company]='SGC'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='SES(GISC/AP)'
	WHERE [SOX Operating Company]='SES (GIS/HQ)'

	UPDATE B_14_TT_SOX_TEST_FINAL
	SET [SOX Operating Company]='SEC'
	WHERE [SOX Operating Company]='SHES'

--

--Step 7 Join FY21 and FY20 together
	EXEC SP_DROPTABLE B_15_IT_PY_CARRYOVER_TEST_FINAL

	SELECT *
	INTO B_15_IT_PY_CARRYOVER_TEST_FINAL
	FROM
	(
		SELECT A.*,Business,
		CASE WHEN [Testing Phase] IN ('1. Walkthrough' , '2. Management testing' , '4. Others') THEN 'Sony'
			WHEN [Testing Phase]='3. PwC' THEN 'PwC'
			END AS 'Testing Phase_Group',-- Rename the text
		CASE WHEN Quarter_checking='FY20January08' THEN 'FY20_Jan/1st'
			 WHEN Quarter_checking='FY20January15' THEN 'FY20_Jan/2nd'
			 WHEN Quarter_checking='FY20January22' THEN 'FY20_Jan/3rd'
			 WHEN Quarter_checking='FY20January29' THEN 'FY20_Jan/4th'
			 WHEN Quarter_checking='FY20February05' THEN 'FY20_Feb/1st'
			 WHEN Quarter_checking='FY20February12' THEN 'FY20_Feb/2nd'
			 WHEN Quarter_checking='FY20February19' THEN 'FY20_Feb/3rd'
			 WHEN Quarter_checking='FY20February26' THEN 'FY20_Feb/4th'
			WHEN (Origi LIKE '%4032022' OR Origi LIKE '%05032022') AND Origi LIKE '%FY21%' THEN 'FY21_March/1st'
			WHEN (Origi LIKE '%11032022' OR Origi LIKE '%12032022') AND Origi LIKE '%FY21%' THEN 'FY21_March/2nd'
			WHEN (Origi LIKE '%18032022' OR Origi LIKE '%19032022') AND Origi LIKE '%FY21%' THEN 'FY21_March/3rd'
			WHEN (Origi LIKE '%25032022' OR Origi LIKE '%26032022') AND Origi LIKE '%FY21%'THEN 'FY21_March/4th'
			WHEN (Origi LIKE '%27032022%') AND Origi LIKE '%FY21%'THEN 'FY21_March/4th'

			WHEN (Origi LIKE '%4032022' OR Origi LIKE '%05032022') AND Origi LIKE '%FY20%' THEN 'FY20_March/1st'
			WHEN (Origi LIKE '%11032022' OR Origi LIKE '%12032022') AND Origi LIKE '%FY20%' THEN 'FY20_March/2nd'
			WHEN (Origi LIKE '%18032022' OR Origi LIKE '%19032022') AND Origi LIKE '%FY20%' THEN 'FY20_March/3rd'
			WHEN (Origi LIKE '%25032022' OR Origi LIKE '%26032022') AND Origi LIKE '%FY20%'THEN 'FY20_March/4th'
			WHEN (Origi LIKE '%27032022%') AND Origi LIKE '%FY20%'THEN 'FY20_March/4th'
			WHEN (Origi LIKE '%2042021' ) AND Origi LIKE '%FY20%' THEN 'FY20_April/1st'
			WHEN (Origi LIKE '%9042021' ) AND Origi LIKE '%FY20%' THEN 'FY20_April/2nd'
			WHEN (Origi LIKE '%16042021' ) AND Origi LIKE '%FY20%' THEN 'FY20_April/3rd'
			WHEN (Origi LIKE '%23042021' ) AND Origi LIKE '%FY20%'THEN 'FY20_April/4th'
			WHEN (Origi LIKE '%30042021' ) AND Origi LIKE '%FY20%'THEN 'FY20_April/5th'

			WHEN (Origi LIKE '%1042022' ) AND Origi LIKE '%FY21%' THEN 'FY21_April/1st'
			WHEN (Origi LIKE '%8042022' ) AND Origi LIKE '%FY21%' THEN 'FY21_April/2nd'
			WHEN (Origi LIKE '%15042022' ) AND Origi LIKE '%FY21%' THEN 'FY21_April/3rd'
			WHEN (Origi LIKE '%22042022' ) AND Origi LIKE '%FY21%'THEN 'FY21_April/4th'
			WHEN (Origi LIKE '%29042022' ) AND Origi LIKE '%FY21%'THEN 'FY21_April/5th'

			-- May2020
			WHEN (Origi LIKE '%7052021' ) AND Origi LIKE '%FY20%' THEN 'FY20_May/1st'
			WHEN (Origi LIKE '%14052021' ) AND Origi LIKE '%FY20%' THEN 'FY20_May/2nd'
			WHEN (Origi LIKE '%21052021' ) AND Origi LIKE '%FY20%' THEN 'FY20_May/3rd'
			WHEN (Origi LIKE '%28052021' ) AND Origi LIKE '%FY20%'THEN 'FY20_May/4th'
			-- May2021
			WHEN (Origi LIKE '%6052022' ) AND Origi LIKE '%FY21%' THEN 'FY21_May/1st'
			WHEN (Origi LIKE '%13052022' ) AND Origi LIKE '%FY21%' THEN 'FY21_May/2nd'
			WHEN (Origi LIKE '%20052022' ) AND Origi LIKE '%FY21%' THEN 'FY21_May/3rd'
			WHEN (Origi LIKE '%27052022' ) AND Origi LIKE '%FY21%'THEN 'FY21_May/4th'
			-- June 2020
			WHEN (Origi LIKE '%4062021' ) AND Origi LIKE '%FY20%' THEN 'FY20_June/1st'
			WHEN (Origi LIKE '%11062021' ) AND Origi LIKE '%FY20%' THEN 'FY20_June/2nd'
			WHEN (Origi LIKE '%18062021FY20Final' ) AND Origi LIKE '%FY20%' THEN 'FY20_June/Final'
			-- June 2021
			WHEN (Origi LIKE '%3062022' ) AND Origi LIKE '%FY21%' THEN 'FY21_June/1st'
			WHEN (Origi LIKE '%10062022' ) AND Origi LIKE '%FY21%' THEN 'FY21_June/2nd'
			WHEN (Origi LIKE '%21062022' ) AND Origi LIKE '%FY21%' THEN 'FY21_June/Final'
			 ELSE Quarter END as 'Month_Week'-- Add the month-week
		FROM  B_12_TT_SOX_TEST_FINAL AS A
		LEFT JOIN AM_FY20_MAPPING 
		ON [SOX Region/ Business]=[Office / Segment] AND [SOX Operating Company]=[SOX Entity]
	--WHERE 	(LEFT([Finding ID],5)= 'FND-1' OR LEFT([Finding ID],5)='FND-2') 
			-- AND	LEN([Finding ID])-9>=2
		
		) AS B
	UNION 
	SELECT * FROM
	(
	SELECT B_14_TT_SOX_TEST_FINAL.*,Business,
	CASE WHEN [Testing Phase] IN ('1. Walkthrough' , '2. Management testing' , '4. Others') THEN 'Sony'
			WHEN [Testing Phase]='3. PwC' THEN 'PwC'
			END AS 'Testing Phase_Group',-- Rename the text
		CASE WHEN Quarter_checking='FY21January07' THEN 'FY21_Jan/1st'
			 WHEN Quarter_checking='FY21January14' THEN 'FY21_Jan/2nd'
			 WHEN Quarter_checking='FY21January21' THEN 'FY21_Jan/3rd'
			 WHEN Quarter_checking='FY21January28' THEN 'FY21_Jan/4th'
			 WHEN Quarter_checking='FY21February04' THEN 'FY21_Feb/1st'
			 WHEN Quarter_checking='FY21February11' THEN 'FY21_Feb/2nd'
			 WHEN Quarter_checking='FY21February18' THEN 'FY21_Feb/3rd'
			 WHEN Quarter_checking='FY21February25' THEN 'FY21_Feb/4th'
			WHEN (Origi LIKE '%4032022' OR Origi LIKE '%05032022') AND Origi LIKE '%FY21%' THEN 'FY21_March/1st'
			WHEN (Origi LIKE '%11032022' OR Origi LIKE '%12032022') AND Origi LIKE '%FY21%' THEN 'FY21_March/2nd'
			WHEN (Origi LIKE '%18032022' OR Origi LIKE '%19032022') AND Origi LIKE '%FY21%' THEN 'FY21_March/3rd'
			WHEN (Origi LIKE '%25032022' OR Origi LIKE '%26032022') AND Origi LIKE '%FY21%'THEN 'FY21_March/4th'
			WHEN (Origi LIKE '%27032022%') AND Origi LIKE '%FY21%'THEN 'FY21_March/4th'

			WHEN (Origi LIKE '%4032022' OR Origi LIKE '%05032022') AND Origi LIKE '%FY20%' THEN 'FY20_March/1st'
			WHEN (Origi LIKE '%11032022' OR Origi LIKE '%12032022') AND Origi LIKE '%FY20%' THEN 'FY20_March/2nd'
			WHEN (Origi LIKE '%18032022' OR Origi LIKE '%19032022') AND Origi LIKE '%FY20%' THEN 'FY20_March/3rd'
			WHEN (Origi LIKE '%25032022' OR Origi LIKE '%26032022') AND Origi LIKE '%FY20%'THEN 'FY21_March/4th'
			WHEN (Origi LIKE '%27032022%') AND Origi LIKE '%FY20%'THEN 'FY20_March/4th'
			WHEN (Origi LIKE '%2042021' ) AND Origi LIKE '%FY20%' THEN 'FY20_April/1st'
			WHEN (Origi LIKE '%9042021' ) AND Origi LIKE '%FY20%' THEN 'FY20_April/2nd'
			WHEN (Origi LIKE '%16042021' ) AND Origi LIKE '%FY20%' THEN 'FY20_April/3rd'
			WHEN (Origi LIKE '%23042021' ) AND Origi LIKE '%FY20%'THEN 'FY20_April/4th'
			WHEN (Origi LIKE '%30042021' ) AND Origi LIKE '%FY20%'THEN 'FY20_April/5th'

			WHEN (Origi LIKE '%1042022' ) AND Origi LIKE '%FY21%' THEN 'FY21_April/1st'
			WHEN (Origi LIKE '%8042022' ) AND Origi LIKE '%FY21%' THEN 'FY21_April/2nd'
			WHEN (Origi LIKE '%15042022' ) AND Origi LIKE '%FY21%' THEN 'FY21_April/3rd'
			WHEN (Origi LIKE '%22042022' ) AND Origi LIKE '%FY21%'THEN 'FY21_April/4th'
			WHEN (Origi LIKE '%29042022' ) AND Origi LIKE '%FY21%'THEN 'FY21_April/5th'
			-- May2020
			WHEN (Origi LIKE '%7052021' ) AND Origi LIKE '%FY20%' THEN 'FY20_May/1st'
			WHEN (Origi LIKE '%14052021' ) AND Origi LIKE '%FY20%' THEN 'FY20_May/2nd'
			WHEN (Origi LIKE '%21052021' ) AND Origi LIKE '%FY20%' THEN 'FY20_May/3rd'
			WHEN (Origi LIKE '%28052021' ) AND Origi LIKE '%FY20%'THEN 'FY20_May/4th'
			-- May2021
			WHEN (Origi LIKE '%6052022' ) AND Origi LIKE '%FY21%' THEN 'FY21_May/1st'
			WHEN (Origi LIKE '%13052022' ) AND Origi LIKE '%FY21%' THEN 'FY21_May/2nd'
			WHEN (Origi LIKE '%20052022' ) AND Origi LIKE '%FY21%' THEN 'FY21_May/3rd'
			WHEN (Origi LIKE '%27052022' ) AND Origi LIKE '%FY21%'THEN 'FY21_May/4th'
			-- June 2020
			WHEN (Origi LIKE '%4062021' ) AND Origi LIKE '%FY20%' THEN 'FY20_June/1st'
			WHEN (Origi LIKE '%11062021' ) AND Origi LIKE '%FY20%' THEN 'FY20_June/2nd'
			WHEN (Origi LIKE '%18062021FY20Final' ) AND Origi LIKE '%FY20%' THEN 'FY20_June/Final'
			-- June 2021
			WHEN (Origi LIKE '%3062022' ) AND Origi LIKE '%FY21%' THEN 'FY21_June/1st'
			WHEN (Origi LIKE '%10062022' ) AND Origi LIKE '%FY21%' THEN 'FY21_June/2nd'
			WHEN (Origi LIKE '%21062022' ) AND Origi LIKE '%FY21%' THEN 'FY21_June/Final'

			 ELSE Quarter END as 'Month_Week'-- Add the month-week
	FROM B_14_TT_SOX_TEST_FINAL
	LEFT JOIN AM_FY21_MAPPING 
		ON [SOX Region/ Business]=[Office / Segment] AND [SOX Operating Company]=[SOX Entity]
	--WHERE  
	--(LEFT([Finding ID],5)= 'FND-1' OR LEFT([Finding ID],5)='FND-2') 
	--AND LEN([Finding ID])-9>=2
		
	) AS C
--Step 8
--Update the text to make sure it's the same with the FY21 mapping file
--FY20 and FY21 are diffrent text
--FY21 has some entity and text rename
	UPDATE B_15_IT_PY_CARRYOVER_TEST_FINAL
	SET [SOX Process Type]='3.ITGC'
	WHERE [SOX Process Type]='ITGC'

	--
	UPDATE B_15_IT_PY_CARRYOVER_TEST_FINAL
	SET 
	[SOX Operating Company]='GISC-AP'
	WHERE [SOX Operating Company]='SES(GISC AP)' OR [SOX Operating Company]='SES(GISC/AP)'
	--

	UPDATE B_15_IT_PY_CARRYOVER_TEST_FINAL
	SET 
	[SOX Operating Company]='GISC AM'
	WHERE [SOX Operating Company]='GDC-W'
	--

	UPDATE B_15_IT_PY_CARRYOVER_TEST_FINAL
	SET 
	[SOX Operating Company]='SGC'
	WHERE [SOX Operating Company]='Corp'

	--
	UPDATE B_15_IT_PY_CARRYOVER_TEST_FINAL
	SET 
	[SOX Operating Company]='SGC'
	WHERE [SOX Operating Company] IN ('SHES','SIPS','SOMC')

END
GO
