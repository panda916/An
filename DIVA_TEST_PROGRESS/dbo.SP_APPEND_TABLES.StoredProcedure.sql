USE [DIVA_TEST_PROGRESS]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_APPEND_TABLES](@prefix NVARCHAR(MAX), @result_table NVARCHAR(MAX))
AS


DECLARE @CURRENT_TABLE varchar(4000)
declare @cmd nvarchar(max) --,@prefix NVARCHAR(MAX), @result_table NVARCHAR(MAX)
declare @cmd_insert nvarchar(max)
--set @prefix = 'xlsx'
--set  @result_table = 'xxxxxtesttttttttttt'
DECLARE TABLE_CURSOR CURSOR FOR
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES
WHERE Table_Name LIKE '%' + @prefix +'%'

OPEN TABLE_CURSOR
FETCH TABLE_CURSOR INTO @CURRENT_TABLE
	set @cmd_insert ='select top 0 * into  [' + @result_table + '] from [' +  @current_table + ']'
	print @cmd_insert
	exec sp_executesql @cmd_insert
WHILE @@fetch_status = 0
BEGIN
    
	set @cmd = N'INSERT INTO [' +  @result_table +  N']  SELECT * FROM [' +  @CURRENT_TABLE + N']' 
	PRINT @cmd
	execute sp_executesql @cmd 
	FETCH NEXT FROM TABLE_CURSOR INTO @CURRENT_TABLE 
END
CLOSE TABLE_CURSOR;
DEALLOCATE TABLE_CURSOR




GO
