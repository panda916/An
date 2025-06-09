USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC[dbo].[SP_SHRINK_DB_LOG](@DB NVARCHAR(50))
-- TRUNCATE the log by changing the database recovery model to SIMPLE.
AS

DECLARE @LOG_FILE NVARCHAR(50) = (SELECT TOP 1 mf.name
FROM
    sys.master_files mf
INNER JOIN 
    sys.databases db ON db.database_id = mf.database_id
WHERE type_desc = 'LOG' AND db.name = @DB
ORDER BY mf.size DESC)

SET @LOG_FILE = '[' + @LOG_FILE + ']'

DECLARE @SQL_CMD NVARCHAR(MAX) = '
USE ' + @DB + '
ALTER DATABASE ' + @DB + ' SET RECOVERY SIMPLE;
DBCC SHRINKFILE (' + @LOG_FILE + ', 1);
ALTER DATABASE ' + @DB + ' SET RECOVERY FULL;'

EXEC sp_executesql @SQL_CMD
GO
