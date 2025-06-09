USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [dbo].[SP_EXEC_DYNAMIC](@DB_NAME AS NVARCHAR(MAX), 
							@SP_NAME AS NVARCHAR(MAX), 
							@param as NVARCHAR(MAX) = '',
							@START_FROM AS NVARCHAR(MAX) = '--DYNAMIC_SCRIPT_START')
AS

DECLARE @SQL_STR nvarchar(max)
IF @param = ''
BEGIN
	SET @SQL_STR =  'USE ' + @DB_NAME + ' ' 
									+ (SELECT RIGHT(definition, LEN(definition) - CHARINDEX(@START_FROM,definition,1) + 1)  
									FROM sys.sql_modules  
									WHERE object_id = (OBJECT_ID(@SP_NAME)))
	EXEC SP_EXECUTESQL @SQL_STR
END
ELSE
BEGIN
	SET @SQL_STR =  'USE ' + @DB_NAME + ' ' 
									+ REPLACE((SELECT RIGHT(definition, LEN(definition) - CHARINDEX(@START_FROM, definition,1) + 1)  
									FROM sys.sql_modules  
									WHERE object_id = (OBJECT_ID(@SP_NAME))), '@param', @param)
	EXEC SP_EXECUTESQL @SQL_STR
END
GO
