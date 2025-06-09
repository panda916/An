USE [DIVA_GB00_FY23_24]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ALTER PROCEDURE [dbo].[SP_DELETE_MULTIPLE_TABLE]
CREATE PROCEDURE [dbo].[SP_DROP_MULTIPLE_TABLE](
	@Tablename Nvarchar(MAX)
)
WITH EXECUTE AS OWNER
AS
BEGIN
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += '
DROP TABLE ' 
    + QUOTENAME(s.name)
    + '.' + QUOTENAME(t.name) + ';'
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s
    ON t.[schema_id] = s.[schema_id] 
    WHERE t.name LIKE @Tablename + '%' AND t.name NOT LIKE @Tablename +'M%'
	AND t.name NOT LIKE 'AM_GLOBALS';--'AQLIK_%';

PRINT @sql;
EXECUTE sp_executesql @sql;

END






GO
