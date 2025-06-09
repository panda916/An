USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_CONVERT_FIELD_VALUE](@table_name NVARCHAR(MAX), @source_field_type NVARCHAR(MAX), @new_field_type NVARCHAR(MAX))
AS

DECLARE @sql_cmd nvarchar(max) = ''

SELECT 
@sql_cmd = @sql_cmd + '
ALTER TABLE ' + A.name + ' ALTER COLUMN ' + B.name +  ' ' + @new_field_type
FROM SYS.tables A
LEFT JOIN SYS.all_columns B ON B.object_id = A.object_id
LEFT JOIN SYS.types C ON B.user_type_id = C.user_type_id
WHERE A.NAME LIKE @table_name
AND C.NAME = @source_field_type

PRINT @sql_cmd

EXEC SP_EXECUTESQL @sql_cmd
GO
