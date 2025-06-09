USE [DIVA_MASTER_SCRIPT]
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
CREATE PROCEDURE [dbo].[TEST_PROGRESS]
AS
BEGIN


EXEC SP_DROPTABLE TT_TABLE_LIST
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
TABLE_NAME
INTO TT_TABLE_LIST
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE 'FY20%'

EXEC SP_REMOVE_TABLES 'B_01_IT_FY20%'

DECLARE @tableVar1 NVARCHAR(MAX)
DECLARE @quarter NVARCHAR(MAX)
DECLARE @vTableNum int
 set @vTableNum = (SELECT COUNT(*) FROM TT_TABLE_LIST)
DECLARE @NUM INT=1

WHILE @NUM<=@vTableNum
BEGIN 
EXEC SP_DROPTABLE TEMP 


SET @tableVar1=(SELECT TABLE_NAME FROM TT_TABLE_LIST WHERE number=@NUM)
SET @quarter=(
	SELECT SUBSTRING(TABLE_NAME,1,CHARINDEX('_',TABLE_NAME)-1) FROM TT_TABLE_LIST WHERE number=@NUM
	)
EXEC (
'SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
* INTO TEMP FROM [' + @tableVar1 +']'
)



EXEC 
('
SELECT (SELECT TOP 1 F4 FROM TEMP ) AS ''Entity'',
	(SELECT TOP 1 F4 FROM TEMP ) AS ''Entity_new_mapping'',
(SELECT F4 FROM TEMP WHERE number=2) AS ''Update Date ( DD-MM-YY )'',
'''+@quarter +''' AS''FY_Week'',CAST(
'''+@quarter +''' AS NVARCHAR(MAX)) AS''FY_Week_new'',
CAST('''' AS NVARCHAR(MAX)) AS ''Significant Account ( 20F Basis ) with number'',
''FY20'' AS ''Fiscal year'',
F3 AS ''Significant Account ( 20F Basis )'',
F4 AS ''Global Risk Rating'',
CAST(REPLACE(ISNULL(F5,''0''),''-'',''0'') AS FLOAT) AS ''No. of Controls  to be Tested (FY20)'',
CAST(REPLACE(ISNULL(F6,''0''),''-'',''0'') AS FLOAT)  AS ''# of Controls Tested by 12/31 (Test Planning_Before year end)'',
CAST(REPLACE(ISNULL(F7,''0''),''-'',''0'') AS FLOAT)  AS ''# of  Controls Tested by 3/31 (Test Planning_Before year end)'',
CAST(REPLACE(ISNULL(F8,''0''),''-'',''0'') AS FLOAT)  AS ''# of Controls Tested during   4/1-30 (Test Planning_After year end)'',
CAST(REPLACE(ISNULL(F9,''0''),''-'',''0'') AS FLOAT)  AS ''# of Controls Tested by 12/31 (Test Actual_Before year end)'',
CAST(REPLACE(ISNULL(F10,''0''),''-'',''0'') AS FLOAT)  AS ''# of  Controls Tested by 3/31 (Test Actual_Before year end)'',
CAST(REPLACE(ISNULL(F11,''0''),''-'',''0'') AS FLOAT)  AS ''# of Controls Tested during   4/1-30 (Test Actual_After year end)''
INTO TEMP1 FROM TEMP 
WHERE number BETWEEN 7 AND 28
'
)


EXEC SP_DROPTABLE TEMP2
SELECT *,
 ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number
 INTO TEMP2
 FROM TEMP1

UPDATE TEMP1
SET [No. of Controls  to be Tested (FY20)]=(SELECT SUM([No. of Controls  to be Tested (FY20)]) FROM TEMP2 WHERE number between 1 and 18  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of Controls Tested by 12/31 (Test Planning_Before year end)]=(SELECT SUM([# of Controls Tested by 12/31 (Test Planning_Before year end)]) FROM TEMP2 WHERE number between 1 and 18  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of  Controls Tested by 3/31 (Test Planning_Before year end)]=(SELECT SUM([# of  Controls Tested by 3/31 (Test Planning_Before year end)]) FROM TEMP2 WHERE number between 1 and 18  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of Controls Tested during   4/1-30 (Test Planning_After year end)]=(SELECT SUM([# of Controls Tested during   4/1-30 (Test Planning_After year end)]) FROM TEMP2 WHERE number between 1 and 18  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of Controls Tested by 12/31 (Test Actual_Before year end)]=(SELECT SUM([# of Controls Tested by 12/31 (Test Actual_Before year end)]) FROM TEMP2 WHERE number between 1 and 18  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of  Controls Tested by 3/31 (Test Actual_Before year end)]=(SELECT SUM([# of  Controls Tested by 3/31 (Test Actual_Before year end)]) FROM TEMP2 WHERE number between 1 and 18  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of Controls Tested during   4/1-30 (Test Actual_After year end)]=(SELECT SUM([# of Controls Tested during   4/1-30 (Test Actual_After year end)]) FROM TEMP2 WHERE number between 1 and 18  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'


--Update grand total

UPDATE TEMP1
SET [No. of Controls  to be Tested (FY20)]=(SELECT SUM([No. of Controls  to be Tested (FY20)]) FROM TEMP2 WHERE number between 19 and 21  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of Controls Tested by 12/31 (Test Planning_Before year end)]=(SELECT SUM([# of Controls Tested by 12/31 (Test Planning_Before year end)]) FROM TEMP2 WHERE number between 19 and 21  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of  Controls Tested by 3/31 (Test Planning_Before year end)]=(SELECT SUM([# of  Controls Tested by 3/31 (Test Planning_Before year end)]) FROM TEMP2 WHERE number between 19 and 21  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of Controls Tested during   4/1-30 (Test Planning_After year end)]=(SELECT SUM([# of Controls Tested during   4/1-30 (Test Planning_After year end)]) FROM TEMP2 WHERE number between 19 and 21  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of Controls Tested by 12/31 (Test Actual_Before year end)]=(SELECT SUM([# of Controls Tested by 12/31 (Test Actual_Before year end)]) FROM TEMP2 WHERE number between 19 and 21  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of  Controls Tested by 3/31 (Test Actual_Before year end)]=(SELECT SUM([# of  Controls Tested by 3/31 (Test Actual_Before year end)]) FROM TEMP2 WHERE number between 19 and 21  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of Controls Tested during   4/1-30 (Test Actual_After year end)]=(SELECT SUM([# of Controls Tested during   4/1-30 (Test Actual_After year end)]) FROM TEMP2 WHERE number between 19 and 21  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'


EXEC 
(
'
SELECT TEMP1.* ,
	AM_FY20_MAPPING.Business,
	AM_FY20_MAPPING.[Office / Segment]
	INTO B_01_IT_' +@tableVar1 +
	' FROM TEMP1
	LEFT JOIN AM_FY20_MAPPING ON TEMP1.Entity=AM_FY20_MAPPING.[SOX Entity]
'
)

 SET @NUM=@NUM+1

 EXEC SP_DROPTABLE TEMP 
  EXEC SP_DROPTABLE TEMP1
  EXEC SP_DROPTABLE TEMP2
 END 

EXEC SP_DROPTABLE TT_TABLE_LIST

SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
TABLE_NAME
INTO TT_TABLE_LIST
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE 'B_01_IT_FY20%'


EXEC SP_DROPTABLE  B01_IT_SOX_TEST_FINAL
--DECLARE @tableVar1 NVARCHAR(MAX)


select 'select * from  into B_02_TT_SOX_TEST_FINAL '+TABLE_NAME +' union all'
FROM TT_TABLE_LIST
ORDER BY TABLE_NAME


EXEC SP_DROPTABLE B_02_TT_SOX_TEST_FINAL
Declare @SQL varchar(max) =''
Select @SQL = @SQL +'Union All Select * From '+Table_Name+' ' 
  FROM TT_TABLE_LIST
  ORDER BY TABLE_NAME
Set @SQL = Stuff(@SQL,1,10,'')

SET @SQL=STUFF( @SQL,8,1,'* INTO B_02_TT_SOX_TEST_FINAL ')
Exec(@SQL)





EXEC SP_DROPTABLE TT_TABLE_LIST
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
TABLE_NAME
INTO TT_TABLE_LIST
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE 'FY21%'

EXEC SP_REMOVE_TABLES 'B_03_IT_FY21%'

 set @vTableNum = (SELECT COUNT(*) FROM TT_TABLE_LIST)
SET @NUM =1

WHILE @NUM<=@vTableNum
BEGIN 
EXEC SP_DROPTABLE TEMP 

SET @tableVar1=(SELECT TABLE_NAME FROM TT_TABLE_LIST WHERE number=@NUM)
SET @quarter=(
	SELECT SUBSTRING(TABLE_NAME,1,CHARINDEX('_',TABLE_NAME)-1) FROM TT_TABLE_LIST WHERE number=@NUM
	)
EXEC (
'SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
* INTO TEMP FROM [' + @tableVar1 +']'
)

EXEC 
('
SELECT (SELECT TOP 1 F4 FROM TEMP ) AS ''Entity'',
	(SELECT TOP 1 F4 FROM TEMP ) AS ''Entity_new_mapping'',

(SELECT F4 FROM TEMP WHERE number=2) AS ''Update Date ( DD-MM-YY )'',
'''+@quarter +''' AS''FY_Week'',CAST(
'''+@quarter +''' AS NVARCHAR(MAX)) AS''FY_Week_new'',
CAST('''' AS NVARCHAR(MAX)) AS ''Significant Account ( 20F Basis ) with number'',
''FY21'' AS ''Fiscal year'',
F3 AS ''Significant Account ( 20F Basis )'',
F4 AS ''Global Risk Rating'',
CAST(REPLACE(ISNULL(F5,''0''),''-'',''0'') AS FLOAT) AS ''No. of Controls  to be Tested (FY20)'',
CAST(REPLACE(ISNULL(F6,''0''),''-'',''0'') AS FLOAT)  AS ''# of Controls Tested by 12/31 (Test Planning_Before year end)'',
CAST(REPLACE(ISNULL(F7,''0''),''-'',''0'') AS FLOAT)  AS ''# of  Controls Tested by 3/31 (Test Planning_Before year end)'',
CAST(REPLACE(ISNULL(F8,''0''),''-'',''0'') AS FLOAT)  AS ''# of Controls Tested during   4/1-30 (Test Planning_After year end)'',
CAST(REPLACE(ISNULL(F9,''0''),''-'',''0'') AS FLOAT)  AS ''# of Controls Tested by 12/31 (Test Actual_Before year end)'',
CAST(REPLACE(ISNULL(F10,''0''),''-'',''0'') AS FLOAT)  AS ''# of  Controls Tested by 3/31 (Test Actual_Before year end)'',
CAST(REPLACE(ISNULL(F11,''0''),''-'',''0'') AS FLOAT)  AS ''# of Controls Tested during   4/1-30 (Test Actual_After year end)''
INTO TEMP1 FROM TEMP 
WHERE number BETWEEN 7 AND 29
'
)



EXEC SP_DROPTABLE TEMP2
SELECT *,
 ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number
 INTO TEMP2
 FROM TEMP1

UPDATE TEMP1
SET [No. of Controls  to be Tested (FY20)]=(SELECT SUM([No. of Controls  to be Tested (FY20)]) FROM TEMP2 WHERE number between 1 and 19  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of Controls Tested by 12/31 (Test Planning_Before year end)]=(SELECT SUM([# of Controls Tested by 12/31 (Test Planning_Before year end)]) FROM TEMP2 WHERE number between 1 and 19  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of  Controls Tested by 3/31 (Test Planning_Before year end)]=(SELECT SUM([# of  Controls Tested by 3/31 (Test Planning_Before year end)]) FROM TEMP2 WHERE number between 1 and 19  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of Controls Tested during   4/1-30 (Test Planning_After year end)]=(SELECT SUM([# of Controls Tested during   4/1-30 (Test Planning_After year end)]) FROM TEMP2 WHERE number between 1 and 19  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of Controls Tested by 12/31 (Test Actual_Before year end)]=(SELECT SUM([# of Controls Tested by 12/31 (Test Actual_Before year end)]) FROM TEMP2 WHERE number between 1 and 19  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of  Controls Tested by 3/31 (Test Actual_Before year end)]=(SELECT SUM([# of  Controls Tested by 3/31 (Test Actual_Before year end)]) FROM TEMP2 WHERE number between 1 and 19  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'

UPDATE TEMP1
SET [# of Controls Tested during   4/1-30 (Test Actual_After year end)]=(SELECT SUM([# of Controls Tested during   4/1-30 (Test Actual_After year end)]) FROM TEMP2 WHERE number between 1 and 19  )
WHERE 
[Significant Account ( 20F Basis )]='BPC Total'


--Update grand total

UPDATE TEMP1
SET [No. of Controls  to be Tested (FY20)]=(SELECT SUM([No. of Controls  to be Tested (FY20)]) FROM TEMP2 WHERE number between 20 and 22  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of Controls Tested by 12/31 (Test Planning_Before year end)]=(SELECT SUM([# of Controls Tested by 12/31 (Test Planning_Before year end)]) FROM TEMP2 WHERE number between 20 and 22  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of  Controls Tested by 3/31 (Test Planning_Before year end)]=(SELECT SUM([# of  Controls Tested by 3/31 (Test Planning_Before year end)]) FROM TEMP2 WHERE number between 20 and 22  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of Controls Tested during   4/1-30 (Test Planning_After year end)]=(SELECT SUM([# of Controls Tested during   4/1-30 (Test Planning_After year end)]) FROM TEMP2 WHERE number between 20 and 22  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of Controls Tested by 12/31 (Test Actual_Before year end)]=(SELECT SUM([# of Controls Tested by 12/31 (Test Actual_Before year end)]) FROM TEMP2 WHERE number between 20 and 22  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of  Controls Tested by 3/31 (Test Actual_Before year end)]=(SELECT SUM([# of  Controls Tested by 3/31 (Test Actual_Before year end)]) FROM TEMP2 WHERE number between 20 and 22  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

UPDATE TEMP1
SET [# of Controls Tested during   4/1-30 (Test Actual_After year end)]=(SELECT SUM([# of Controls Tested during   4/1-30 (Test Actual_After year end)]) FROM TEMP2 WHERE number between 20 and 22  )
WHERE 
[Significant Account ( 20F Basis )]='Grand Total'

EXEC 
(
'
SELECT TEMP1.* ,
	AM_FY21_MAPPING.Business,
	AM_FY21_MAPPING.[Office / Segment]
	INTO B_03_IT_' +@tableVar1 +
	' FROM TEMP1
	LEFT JOIN AM_FY21_MAPPING ON TEMP1.Entity=AM_FY21_MAPPING.[SOX Entity]
'
)

 SET @NUM=@NUM+1

 EXEC SP_DROPTABLE TEMP 
  EXEC SP_DROPTABLE TEMP1
  EXEC SP_DROPTABLE TEMP2
 END 

EXEC SP_DROPTABLE TT_TABLE_LIST


SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS number,
TABLE_NAME
INTO TT_TABLE_LIST
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE 'B_03_IT_FY21%'


--DECLARE @tableVar1 NVARCHAR(MAX)


EXEC SP_DROPTABLE B_03_IT_SOX_TEST_FINAL
SET @SQL =''
Select @SQL = @SQL +'Union All Select * From '+Table_Name+' ' 
  FROM TT_TABLE_LIST
  ORDER BY TABLE_NAME
Set @SQL = Stuff(@SQL,1,10,'')

SET @SQL=STUFF( @SQL,8,1,'* INTO B_03_IT_SOX_TEST_FINAL ')
Exec(@SQL)

EXEC SP_DROPTABLE B_04_IT_SOX_TEST_FINAL

SELECT * 
INTO B_04_IT_SOX_TEST_FINAL
FROM B_02_TT_SOX_TEST_FINAL
UNION
SELECT * 
FROM B_03_IT_SOX_TEST_FINAL

UPDATE B_04_IT_SOX_TEST_FINAL
SET [Significant Account ( 20F Basis )] ='Others'
WHERE [Significant Account ( 20F Basis )] = 'Other'
OR [Significant Account ( 20F Basis )] = 'Others (IFRS)'

UPDATE B_04_IT_SOX_TEST_FINAL
SET [Significant Account ( 20F Basis )]= 'Revenue ( including financial service )'
WHERE [Significant Account ( 20F Basis )] = 'Revenue (including financial service)'

UPDATE B_04_IT_SOX_TEST_FINAL
SET [Significant Account ( 20F Basis )]= 'SGA and Financial Service Expenses'
WHERE [Significant Account ( 20F Basis )] = 'SGA abd Financial Service Expenses'

UPDATE B_04_IT_SOX_TEST_FINAL
SET [Significant Account ( 20F Basis )]= 'Tax ( including deferred tax )'
WHERE [Significant Account ( 20F Basis )] = 'Tax (including deferred tax)'


UPDATE B_04_IT_SOX_TEST_FINAL
SET [Significant Account ( 20F Basis )]= 'Content Assets'
WHERE [Significant Account ( 20F Basis )] = 'Film Costs'


--
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='1. FSCP' WHERE [Significant Account ( 20F Basis )]='FSCP'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='2. Cash' WHERE [Significant Account ( 20F Basis )]='Cash'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='3. Marketable Securities' WHERE [Significant Account ( 20F Basis )]='Marketable Securities'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='4. AR Trade' WHERE [Significant Account ( 20F Basis )]='AR Trade'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='5. Inventories' WHERE [Significant Account ( 20F Basis )]='Inventories'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='6. Content Assets' WHERE [Significant Account ( 20F Basis )]='Content Assets'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='7. Investments' WHERE [Significant Account ( 20F Basis )]='Investments'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='8. PP&E, net' WHERE [Significant Account ( 20F Basis )]='PP&E, net'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='9. Intangibles, net' WHERE [Significant Account ( 20F Basis )]='Intangibles, net'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='10.Goodwill' WHERE [Significant Account ( 20F Basis )]='Goodwill'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='11.Deferred Insurance Acquisition Costs' WHERE [Significant Account ( 20F Basis )]='Deferred Insurance Acquisition Costs'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='12.AP Trade and Accruals' WHERE [Significant Account ( 20F Basis )]='AP Trade and Accruals'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='13.Deposits in  Banking Business' WHERE [Significant Account ( 20F Basis )]='Deposits in  Banking Business'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='14.Future Insurance Policy Benefits' WHERE [Significant Account ( 20F Basis )]='Future Insurance Policy Benefits'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='15.Revenue ( including financial service )' WHERE [Significant Account ( 20F Basis )]='Revenue ( including financial service )'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='16.Cost of Sales' WHERE [Significant Account ( 20F Basis )]='Cost of Sales'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='17.SGA and Financial Service Expenses' WHERE [Significant Account ( 20F Basis )]='SGA and Financial Service Expenses'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='18.Tax ( including deferred tax )' WHERE [Significant Account ( 20F Basis )]='Tax ( including deferred tax )'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='19.Others' WHERE [Significant Account ( 20F Basis )]='Others'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='20.BPC Total' WHERE [Significant Account ( 20F Basis )]='BPC Total'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='21.CLC' WHERE [Significant Account ( 20F Basis )]='CLC'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='22.ITGC' WHERE [Significant Account ( 20F Basis )]='ITGC'
 UPDATE B_04_IT_SOX_TEST_FINAL SET [Significant Account ( 20F Basis ) with number]='23.Grand Total' WHERE [Significant Account ( 20F Basis )]='Grand Total'



 --Update entity
UPDATE B_04_IT_SOX_TEST_FINAL SET Entity_new_mapping='SGC' WHERE Entity='Corp'
UPDATE B_04_IT_SOX_TEST_FINAL SET Entity_new_mapping='SEC' WHERE Entity='SHES'
UPDATE B_04_IT_SOX_TEST_FINAL SET Entity_new_mapping='SEC' WHERE Entity='SIPS'
UPDATE B_04_IT_SOX_TEST_FINAL SET Entity_new_mapping='SEC' WHERE Entity='SOMC'
UPDATE B_04_IT_SOX_TEST_FINAL SET Entity_new_mapping='GISC AM' WHERE Entity='GDC-W'
UPDATE B_04_IT_SOX_TEST_FINAL SET Entity_new_mapping='GISC-AP' WHERE Entity='SES(GISC AP)'
UPDATE B_04_IT_SOX_TEST_FINAL SET Entity_new_mapping='GISC-AP' WHERE Entity='SES(GISC/AP)'
UPDATE B_04_IT_SOX_TEST_FINAL SET Entity_new_mapping='SFG' WHERE Entity='SFGI' OR  Entity='SFH'

--Update quater 
UPDATE B_04_IT_SOX_TEST_FINAL SET FY_Week_new='1.FY20Jan' WHERE FY_Week_new='FY20Jan'
UPDATE B_04_IT_SOX_TEST_FINAL SET FY_Week_new='1.FY21Jan' WHERE FY_Week_new='FY21Jan'
UPDATE B_04_IT_SOX_TEST_FINAL SET FY_Week_new='2.FY20Mar' WHERE FY_Week_new='FY20Mar'
UPDATE B_04_IT_SOX_TEST_FINAL SET FY_Week_new='3.FY20Apr' WHERE FY_Week_new='FY20Apr'
UPDATE B_04_IT_SOX_TEST_FINAL SET FY_Week_new='4.FY20Sep' WHERE FY_Week_new='FY20Sep'
UPDATE B_04_IT_SOX_TEST_FINAL SET FY_Week_new='4.FY21Sep' WHERE FY_Week_new='FY21Sep'

--Add Compare by Quarter
ALTER TABLE B_04_IT_SOX_TEST_FINAL ADD Quarter_compare NVARCHAR(MAX)

UPDATE B_04_IT_SOX_TEST_FINAL  SET Quarter_compare='FY20Jan_FY21Jan' WHERE FY_Week IN ('FY20Jan','FY21Jan')
UPDATE B_04_IT_SOX_TEST_FINAL  SET Quarter_compare='FY20Mar' WHERE FY_Week IN ('FY20Mar')
UPDATE B_04_IT_SOX_TEST_FINAL  SET Quarter_compare='FY20Apr' WHERE FY_Week IN ('FY20Apr')
UPDATE B_04_IT_SOX_TEST_FINAL  SET Quarter_compare='FY20Sep_FY21Sep' WHERE FY_Week IN ('FY20Sep','FY21Sep')


END
GO
