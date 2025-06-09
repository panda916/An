USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--alter PROCEDURE [dbo].[sp_TEST_DUP_KEY_FIELDS](@ZV_TEST_FIELDS NVARCHAR(MAX), @ZV_TEST_TABLE NVARCHAR(MAX))
CREATE PROCEDURE [dbo].[SP_TABLE_REC_INFO](@ZV_TEST_TABLE NVARCHAR(MAX))
AS

DECLARE @ZV_CMD NVARCHAR(MAX), @ZV_STR_SQL NVARCHAR(MAX)

IF OBJECT_ID('LOG_TABLE_INFO', 'U') IS NULL 
BEGIN 
CREATE TABLE [DBO].[LOG_TABLE_INFO] ([SP_NAME] NVARCHAR(MAX) NULL, [SP_TABLE] NVARCHAR(MAX) NULL, 
	REC_COUNT MONEY NULL,[SUM_POS] MONEY NULL, [SUM_NEG] MONEY NULL, SUM_FIELD NVARCHAR(MAX), KEY_FIELD NVARCHAR(MAX), QUERY_TIME DATETIME, ID INT IDENTITY(1, 1)) 
END

DECLARE @ZV_REC_COUNT INT = (SELECT TOP 1 ID FROM [LOG_TABLE_INFO] ORDER BY ID DESC)

IF NOT EXISTS(SELECT TOP 1 * FROM    
				sys.columns
			INNER JOIN 
				sys.types
				ON sys.columns.user_type_id = sys.types.user_type_id
			LEFT OUTER JOIN 
				sys.index_columns 
				ON sys.index_columns.object_id = sys.columns.object_id 
				AND sys.index_columns.column_id = sys.columns.column_id
			LEFT OUTER JOIN 
				sys.indexes 
				ON sys.index_columns.object_id = sys.indexes.object_id 
				AND sys.index_columns.index_id = sys.indexes.index_id
			WHERE
				sys.columns.object_id = OBJECT_ID(@ZV_TEST_TABLE) 
				AND sys.columns.PRECISION <> 0
				AND sys.types.name <> 'Date')
BEGIN
	SET @ZV_CMD = (SELECT TOP 1
					   'INSERT INTO [LOG_TABLE_INFO] 
							SELECT ' 
								+ ''''', ' 
								+ '''' + @ZV_TEST_TABLE + ''', ' 
								+ 'COUNT(*), '
								+ '0, '
								+ '0, '
								+ '''no value column found'', ' 
								+ ''''', ' 
								+ '''' + CAST(GETDATE() AS NVARCHAR(MAX)) + ''' '
						+ 'FROM ' + @ZV_TEST_TABLE
					FROM    
						sys.columns
					INNER JOIN 
						sys.types
						ON sys.columns.user_type_id = sys.types.user_type_id
					LEFT OUTER JOIN 
						sys.index_columns 
						ON sys.index_columns.object_id = sys.columns.object_id 
						AND sys.index_columns.column_id = sys.columns.column_id
					LEFT OUTER JOIN 
						sys.indexes 
						ON sys.index_columns.object_id = sys.indexes.object_id 
						AND sys.index_columns.index_id = sys.indexes.index_id
					WHERE
						sys.columns.object_id = OBJECT_ID(@ZV_TEST_TABLE))
	EXEC (@ZV_CMD)
END
ELSE
BEGIN
	DECLARE SUM_CURSOR CURSOR FOR

	SELECT 
	   'INSERT INTO [LOG_TABLE_INFO] 
			SELECT ' 
				+ ''''', ' 
				+ '''' + @ZV_TEST_TABLE + ''', ' 
				+ 'COUNT(*), '
				+ 'SUM(IIF([' + sys.columns.name + '] > 0, [' + sys.columns.name + '], 0)), '
				+ 'SUM(IIF([' + sys.columns.name + '] < 0, [' + sys.columns.name + '], 0)), '
				+ '''' + sys.columns.name + ''', ' 
				+ ''''', ' 
				+ '''' + CAST(GETDATE() AS NVARCHAR(MAX)) + ''' '
		+ 'FROM ' + @ZV_TEST_TABLE
	FROM    
		sys.columns
	INNER JOIN 
		sys.types
		ON sys.columns.user_type_id = sys.types.user_type_id
	LEFT OUTER JOIN 
		sys.index_columns 
		ON sys.index_columns.object_id = sys.columns.object_id 
		AND sys.index_columns.column_id = sys.columns.column_id
	LEFT OUTER JOIN 
		sys.indexes 
		ON sys.index_columns.object_id = sys.indexes.object_id 
		AND sys.index_columns.index_id = sys.indexes.index_id
	WHERE
		sys.columns.object_id = OBJECT_ID(@ZV_TEST_TABLE) 
		AND sys.columns.PRECISION <> 0
		AND sys.types.name <> 'Date'


	OPEN SUM_CURSOR
	WHILE 1 = 1
	BEGIN
		FETCH SUM_CURSOR INTO @ZV_CMD
		IF @@fetch_status != 0 BREAK
		IF @ZV_CMD IS NOT NULL
		BEGIN
			EXEC(@ZV_CMD)
			IF @ZV_REC_COUNT <> (SELECT TOP 1 ID FROM [LOG_TABLE_INFO] ORDER BY ID DESC)
				SET @ZV_STR_SQL = (SELECT TOP 1 'FOUND ' + CAST(ISNULL(REC_COUNT, '0') AS NVARCHAR(MAX)) 
				+ ' record(s) with 
				SUM possitive = ' + CAST(ISNULL(SUM_POS, '0') AS NVARCHAR(MAX)) + ' and 
				SUM negative = '
				+ CAST(ISNULL(SUM_NEG, '0') AS NVARCHAR(MAX))
				+ '
				from FIELD ' + SUM_FIELD + ' 
				TABLE ' +  [SP_TABLE] FROM [LOG_TABLE_INFO] ORDER BY ID DESC)
			ELSE SET @ZV_STR_SQL = 'ERROR FOUND IN STORED PROCEDURE'
			RAISERROR (@ZV_STR_SQL, 0, 1) WITH NOWAIT
		END
	END
	CLOSE SUM_CURSOR;
	DEALLOCATE SUM_CURSOR
END





GO
