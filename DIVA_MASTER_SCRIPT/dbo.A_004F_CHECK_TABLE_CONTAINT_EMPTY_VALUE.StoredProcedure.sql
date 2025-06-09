USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[A_004F_CHECK_TABLE_CONTAINT_EMPTY_VALUE]

AS


DECLARE @tbl NVARCHAR(255), @sql NVARCHAR(MAX);

DECLARE cur CURSOR FOR
SELECT name
FROM sys.tables
WHERE name LIKE 'A[_]%'  -- ch? l?y các b?ng tên b?t d?u A_

OPEN cur;
FETCH NEXT FROM cur INTO @tbl;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = '
    IF EXISTS (
        SELECT 1
        FROM [' + @tbl + '] 
        WHERE ' + (
            SELECT STRING_AGG('TRY_CAST([' + c.name + '] AS FLOAT) < 0', ' OR ')
            FROM sys.columns c
            JOIN sys.types t ON c.user_type_id = t.user_type_id
            WHERE c.object_id = OBJECT_ID(@tbl)
              AND t.name IN ('int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money')
        ) + '
    )
    PRINT ''' + @tbl + ''';';

    IF @sql IS NOT NULL
        EXEC(@sql);

    FETCH NEXT FROM cur INTO @tbl;
END

CLOSE cur;
DEALLOCATE cur;
GO
