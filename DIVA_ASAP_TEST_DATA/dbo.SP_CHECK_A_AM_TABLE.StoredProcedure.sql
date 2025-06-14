USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_CHECK_A_AM_TABLE]
--ALTER PROCEDURE [dbo].[SP_CHECK_A_AM_TABLE] 

AS
BEGIN

EXEC SP_DROPTABLE '#TABLE_NAME'
EXEC SP_DROPTABLE '#LIST_OF_TABLE_COLUMN'
CREATE TABLE #LIST_OF_TABLE_COLUMN (TABLE_NAME VARCHAR(255),TABLE_FIELD VARCHAR(255), DATA_TYPE VARCHAR(255),CHARACTER_MAXIMUM_LENGTH INT)

SELECT TABLE_NAME INTO #TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
		WHERE  LEFT(TABLE_NAME,5) <> 'A_SAP' AND LEFT(TABLE_NAME,6) <> 'A_QLIK' 
			  AND LEFT(TABLE_NAME,2) = 'A_' OR LEFT(TABLE_NAME,3) = 'AM_'  



DECLARE  @TABLE_NAME_VALUE VARCHAR(50);
DECLARE LIST_CURSOR CURSOR FOR

	SELECT TABLE_NAME  
	FROM #TABLE_NAME 
	


OPEN LIST_CURSOR

FETCH NEXT FROM LIST_CURSOR
INTO  @TABLE_NAME_VALUE
WHILE @@FETCH_STATUS = 0
BEGIN

--REPLACE(COLUMNNAME, '\T', '')

	
	PRINT @TABLE_NAME_VALUE
	DECLARE @SQLCMD NVARCHAR(MAX)
	SET @SQLCMD = 'INSERT INTO #LIST_OF_TABLE_COLUMN (TABLE_NAME, TABLE_FIELD, DATA_TYPE,CHARACTER_MAXIMUM_LENGTH) --- USE THIS TO DEBUG 
		 SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE,CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''' + REPLACE(@TABLE_NAME_VALUE,  CHAR(9),'') + ''''
	EXEC SP_EXECUTESQL @SQLCMD
	PRINT @SQLCMD
	FETCH NEXT FROM LIST_CURSOR
	INTO @TABLE_NAME_VALUE -- SIMILAR TO COUNT = COUNT + 1

END
CLOSE LIST_CURSOR
DEALLOCATE LIST_CURSOR



SELECT DISTINCT TABLE_NAME FROM #LIST_OF_TABLE_COLUMN WHERE LEFT(TABLE_NAME,2) = 'A_'
End







GO
