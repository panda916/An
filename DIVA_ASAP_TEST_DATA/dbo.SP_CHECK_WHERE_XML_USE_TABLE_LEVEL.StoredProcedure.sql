USE [DIVA_ASAP_TEST_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHECK_WHERE_XML_USE_TABLE_LEVEL]
	@SearchXMLName VARCHAR(128) = 'ALL'
AS
BEGIN
	DECLARE @XML_NAME VARCHAR(128)
	DECLARE @TABLE_NAME VARCHAR(128)
	DECLARE @SEARCH_TEXT VARCHAR(128)
	EXECUTE dbo.SP_CREATE_RESULT_TAB
	EXECUTE dbo.SP_PREPARE_XML_DATA_TABLE

	/*Delete table before use*/
	DELETE dbo.B_WHERE_XML_USE_RESULT_TEMP
	DELETE dbo.B_WHERE_XML_USE_TABLE_LEVEL_RESULT
	DELETE dbo.A_WHERE_XML_USE_TEMP

	IF (@SearchXMLName = 'ALL')
		BEGIN
			DECLARE XML_TABNAME_CURSOR CURSOR LOCAL FOR 
				SELECT DISTINCT XML_NAME, TABLE_NAME, FIELD_NAME
					FROM dbo.A_XML_TABLE_FIELD_DATA
					ORDER BY XML_NAME, TABLE_NAME
		END

	ELSE
		BEGIN
			DECLARE XML_TABNAME_CURSOR CURSOR LOCAL FOR 
				SELECT DISTINCT XML_NAME, TABLE_NAME
					FROM dbo.A_XML_TABLE_FIELD_DATA
					WHERE XML_NAME = @SearchXMLName
					ORDER BY XML_NAME, TABLE_NAME
		END


	OPEN XML_TABNAME_CURSOR;
	FETCH NEXT FROM XML_TABNAME_CURSOR INTO @XML_NAME, @TABLE_NAME
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @SEARCH_TEXT = @TABLE_NAME
		PRINT 'Extracting: '+ @SEARCH_TEXT
		DELETE dbo.A_WHERE_XML_USE_TEMP
		INSERT INTO dbo.A_WHERE_XML_USE_TEMP(SP_NAME)
		EXEC dbo.SP_WHERE_USED @SEARCH_TEXT

		INSERT INTO dbo.B_WHERE_XML_USE_RESULT_TEMP(XML_NAME, TABLE_NAME, SEARCH_TEXT, SP_NAME)
			SELECT @XML_NAME AS XML_NAME, @TABLE_NAME AS TABLE_NAME, @SEARCH_TEXT AS SEARCH_TEXT, SP_NAME 
			FROM dbo.A_WHERE_XML_USE_TEMP
			WHERE SP_NAME <> 'SP_PREPARE_XML_DATA_TABLE'
			ORDER BY XML_NAME, TABLE_NAME, SEARCH_TEXT

		FETCH NEXT FROM XML_TABNAME_CURSOR INTO @XML_NAME, @TABLE_NAME
	END

	IF (@SearchXMLName = 'ALL')
		INSERT INTO dbo.B_WHERE_XML_USE_TABLE_LEVEL_RESULT( XML_NAME, TABLE_NAME, SEARCH_TEXT, SP_NAME)
			SELECT DISTINCT A.XML_NAME, A.TABLE_NAME, A.TABLE_NAME AS SEARCH_TEXT, B.SP_NAME
			FROM dbo.A_XML_TABLE_FIELD_DATA AS A LEFT JOIN dbo.B_WHERE_XML_USE_RESULT_TEMP AS B
			ON A.XML_NAME = B.XML_NAME AND A.TABLE_NAME = B.TABLE_NAME
			ORDER BY A.XML_NAME, A.TABLE_NAME
	ELSE
		INSERT INTO dbo.B_WHERE_XML_USE_TABLE_LEVEL_RESULT( XML_NAME, TABLE_NAME, SEARCH_TEXT, SP_NAME)
			SELECT DISTINCT A.XML_NAME, A.TABLE_NAME, A.TABLE_NAME AS SEARCH_TEXT, B.SP_NAME
			FROM dbo.A_XML_TABLE_FIELD_DATA AS A LEFT JOIN dbo.B_WHERE_XML_USE_RESULT_TEMP AS B
			ON A.XML_NAME = B.XML_NAME AND A.TABLE_NAME = B.TABLE_NAME
			WHERE A.XML_NAME = @SearchXMLName
			ORDER BY A.XML_NAME, A.TABLE_NAME


	CLOSE XML_TABNAME_CURSOR
	DEALLOCATE XML_TABNAME_CURSOR

	DELETE dbo.A_WHERE_XML_USE_TEMP
	DELETE dbo.B_WHERE_XML_USE_RESULT_TEMP

	SELECT * FROM dbo.B_WHERE_XML_USE_TABLE_LEVEL_RESULT
	ORDER BY XML_NAME, TABLE_NAME, SP_NAME

END






GO
