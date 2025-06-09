USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<vinh.le@aufinia.com>
-- Create date: <April 14, 2021>
-- Description:	<This script use to append data from incremental data to main table>
--Note: This script still missing a part for updating BSAD/BSAK base on BKPF
-- =============================================
CREATE     PROCEDURE [dbo].[A_002A_SS05_UPDATE_INCREMENTAL_DATA]
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @TABLE_NAME NVARCHAR(MAX)
			,@MSSG NVARCHAR(MAX)
			,@KEYFIELD NVARCHAR(MAX)
			,@WHERE_CONDITION NVARCHAR(MAX)
			,@TABLE_NAME_WITHOUT_PREFIX NVARCHAR(MAX)
			,@INDEX_NAME NVARCHAR(MAX)
			,@SQL_CMD NVARCHAR(MAX)
			,@ROW_COUNT NVARCHAR(MAX)
			,@CURRENT_TIME NVARCHAR(MAX)
	SET @TABLE_NAME = ''

	/*
		Step 1: Create a temporary table from CDHDR/CDPOS tables to contain all changes of incremental tables.
				We use this table to update table which have incremental type is 'Append' -- Check in AM_INCRMENTAL_MAPPING
				Only keep changes relate to incremental tables which have type is append
				Summary to only keep the lastest changes of certain records.

	*/
		EXEC SP_REMOVE_TABLES 'A003_01_TT_INCREMENTAL_CHANGES_SUMMARY'
		;WITH INCREMENTAL_CHANGES_TEMP AS (
			SELECT AM_INCREMENTAL_MAPPING.TABLE_NAME 
				  ,CDPOS_TABNAME
				  ,CDPOS_FNAME
				  ,CDPOS_TABKEY
				  ,CDPOS_VALUE_OLD
				  ,CDPOS_VALUE_NEW
				  ,CDHDR_UDATE
				  ,CDHDR_UTIME
				  ,INFORMATION_SCHEMA.COLUMNS.DATA_TYPE
				  ,ROW_NUMBER() OVER(PARTITION BY CDPOS_TABNAME, CDPOS_FNAME, CDPOS_TABKEY ORDER BY CDHDR_UDATE DESC, CDHDR_UTIME DESC) ROW_ID
			FROM A_CDPOS
			INNER JOIN A_CDHDR
			ON A_CDPOS.CDPOS_MANDANT = A_CDHDR.CDHDR_MANDANT AND
			   A_CDPOS.CDPOS_OBJECTCLAS = A_CDHDR.CDHDR_OBJECTCLAS AND
			   A_CDPOS.CDPOS_OBJECTID = A_CDHDR.CDHDR_OBJECTID AND
			   A_CDPOS.CDPOS_CHANGENR = A_CDHDR.CDHDR_CHANGENR
			INNER JOIN INFORMATION_SCHEMA.COLUMNS
			ON INFORMATION_SCHEMA.COLUMNS.TABLE_NAME = CONCAT('A_', CDPOS_TABNAME) AND
			   INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME = CONCAT(CDPOS_TABNAME, '_', CDPOS_FNAME)
			INNER JOIN AM_INCREMENTAL_MAPPING
			ON AM_INCREMENTAL_MAPPING.TABLE_NAME = INFORMATION_SCHEMA.COLUMNS.TABLE_NAME
			WHERE AM_INCREMENTAL_MAPPING.APPEND_UPDATE_WITH_NEW_DATA = 'X' 
				  AND A_CDHDR.CDHDR_CHANGE_IND = 'U'
				  AND A_CDPOS.CDPOS_CHNGIND = 'U'
			UNION
			SELECT 'A_BSAK'
				  ,'BSAK'
				  ,CDPOS_FNAME
				  ,CDPOS_TABKEY
				  ,CDPOS_VALUE_OLD
				  ,CDPOS_VALUE_NEW
				  ,CDHDR_UDATE
				  ,CDHDR_UTIME
				  ,INFORMATION_SCHEMA.COLUMNS.DATA_TYPE
				  ,ROW_NUMBER() OVER(PARTITION BY CDPOS_TABNAME, CDPOS_FNAME, CDPOS_TABKEY ORDER BY CDHDR_UDATE DESC, CDHDR_UTIME DESC) ROW_ID
			FROM A_CDPOS
			INNER JOIN A_CDHDR
			ON A_CDPOS.CDPOS_MANDANT = A_CDHDR.CDHDR_MANDANT AND
			   A_CDPOS.CDPOS_OBJECTCLAS = A_CDHDR.CDHDR_OBJECTCLAS AND
			   A_CDPOS.CDPOS_OBJECTID = A_CDHDR.CDHDR_OBJECTID AND
			   A_CDPOS.CDPOS_CHANGENR = A_CDHDR.CDHDR_CHANGENR
			INNER JOIN INFORMATION_SCHEMA.COLUMNS
			ON INFORMATION_SCHEMA.COLUMNS.TABLE_NAME = CONCAT('A_', 'BSAK') AND
			   INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME = CONCAT('BSAK', '_', CDPOS_FNAME)
			INNER JOIN AM_INCREMENTAL_MAPPING
			ON AM_INCREMENTAL_MAPPING.TABLE_NAME = 'A_BSAK'
			WHERE AM_INCREMENTAL_MAPPING.APPEND_UPDATE_WITH_NEW_DATA = 'X' 
				  AND A_CDHDR.CDHDR_CHANGE_IND = 'U'
				  AND A_CDPOS.CDPOS_CHNGIND = 'U'
				  AND A_CDPOS.CDPOS_TABNAME IN ('BSEG')
			UNION
			SELECT 'A_BSAD'
				  ,'BSAD'
				  ,CDPOS_FNAME
				  ,CDPOS_TABKEY
				  ,CDPOS_VALUE_OLD
				  ,CDPOS_VALUE_NEW
				  ,CDHDR_UDATE
				  ,CDHDR_UTIME
				  ,INFORMATION_SCHEMA.COLUMNS.DATA_TYPE
				  ,ROW_NUMBER() OVER(PARTITION BY CDPOS_TABNAME, CDPOS_FNAME, CDPOS_TABKEY ORDER BY CDHDR_UDATE DESC, CDHDR_UTIME DESC) ROW_ID
			FROM A_CDPOS
			INNER JOIN A_CDHDR
			ON A_CDPOS.CDPOS_MANDANT = A_CDHDR.CDHDR_MANDANT AND
			   A_CDPOS.CDPOS_OBJECTCLAS = A_CDHDR.CDHDR_OBJECTCLAS AND
			   A_CDPOS.CDPOS_OBJECTID = A_CDHDR.CDHDR_OBJECTID AND
			   A_CDPOS.CDPOS_CHANGENR = A_CDHDR.CDHDR_CHANGENR
			INNER JOIN INFORMATION_SCHEMA.COLUMNS
			ON INFORMATION_SCHEMA.COLUMNS.TABLE_NAME = CONCAT('A_', 'BSAD') AND
			   INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME = CONCAT('BSAD', '_', CDPOS_FNAME)
			INNER JOIN AM_INCREMENTAL_MAPPING
			ON AM_INCREMENTAL_MAPPING.TABLE_NAME = 'A_BSAD'
			WHERE AM_INCREMENTAL_MAPPING.APPEND_UPDATE_WITH_NEW_DATA = 'X' 
				  AND A_CDHDR.CDHDR_CHANGE_IND = 'U'
				  AND A_CDPOS.CDPOS_CHNGIND = 'U'
				  AND A_CDPOS.CDPOS_TABNAME IN ('BSEG')
		)
		SELECT TABLE_NAME
		       ,CDPOS_TABNAME
			   ,CDPOS_FNAME
			   ,TRIM(REPLACE(CDPOS_TABKEY, ' ', '')) CDPOS_TABKEY
			   ,CDPOS_VALUE_OLD
			   ,CDPOS_VALUE_NEW
			   ,CDHDR_UDATE
			   ,CDHDR_UTIME
			   ,DATA_TYPE
		INTO A003_01_TT_INCREMENTAL_CHANGES_SUMMARY
		FROM INCREMENTAL_CHANGES_TEMP
		WHERE ROW_ID = 1


		BEGIN TRY
			CLOSE TABLE_CURSOR
			DEALLOCATE TABLE_CURSOR
			PRINT 'TABLE_CURSOR have been already close !'
		END TRY
		BEGIN CATCH
			PRINT 'TABLE_CURSOR is already close !'
		END CATCH

		DECLARE TABLE_CURSOR CURSOR FOR SELECT DISTINCT TABLE_NAME
										FROM A003_01_TT_INCREMENTAL_CHANGES_SUMMARY
										WHERE TABLE_NAME = 'A_EKKO'
										ORDER BY TABLE_NAME
		OPEN TABLE_CURSOR
		FETCH NEXT FROM TABLE_CURSOR INTO @TABLE_NAME
		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ @TABLE_NAME + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				
				SET @KEYFIELD = ''
				SET @WHERE_CONDITION = ''
				SET @TABLE_NAME_WITHOUT_PREFIX = RIGHT(@TABLE_NAME, LEN(@TABLE_NAME) - 2)
				SET @INDEX_NAME = ''
				SET @SQL_CMD = ''
				SET @ROW_COUNT = 0
				SET @CURRENT_TIME = REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(19) ,GETDATE(), 120),'-',''),' ',''), ':', '')

				/*
					Step 1: Get key fields for current table.
				*/

					IF @TABLE_NAME <> 'A_BSAD' AND @TABLE_NAME <> 'A_BSAK'
						BEGIN
							SELECT @KEYFIELD = STUFF((
								SELECT CONCAT(', ', INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME)
								FROM A_DD03L
								INNER JOIN INFORMATION_SCHEMA.COLUMNS
								ON INFORMATION_SCHEMA.COLUMNS.TABLE_NAME = CONCAT('A_', A_DD03L.TABNAME) AND COLUMN_NAME = CONCAT(@TABLE_NAME_WITHOUT_PREFIX, '_', A_DD03L.FIELDNAME)
								WHERE TABNAME = @TABLE_NAME_WITHOUT_PREFIX AND KEYFLAG = 'X'
								ORDER BY POSITION
								FOR XML PATH(''), TYPE
								).value('(./text())[1]','VARCHAR(MAX)') ,1, 2, '')
							SET @MSSG = CONCAT('Table: ', @TABLE_NAME, ' Key fields: ', @KEYFIELD)
							RAISERROR(@MSSG, 0, 1) WITH NOWAIT
						END
					ELSE
						BEGIN
							SELECT @KEYFIELD = STUFF((
								SELECT CONCAT(', ', REPLACE(INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME, 'BSEG', @TABLE_NAME_WITHOUT_PREFIX))
								FROM A_DD03L
								INNER JOIN INFORMATION_SCHEMA.COLUMNS
								ON INFORMATION_SCHEMA.COLUMNS.TABLE_NAME = CONCAT('A_', A_DD03L.TABNAME) AND COLUMN_NAME = CONCAT('BSEG', '_', A_DD03L.FIELDNAME)
								WHERE TABNAME = 'BSEG' AND KEYFLAG = 'X'
								ORDER BY POSITION
								FOR XML PATH(''), TYPE
								).value('(./text())[1]','VARCHAR(MAX)') ,1, 2, '')
							SET @MSSG = CONCAT('Table: ', @TABLE_NAME, ' Key fields: ', @KEYFIELD)
							RAISERROR(@MSSG, 0, 1) WITH NOWAIT
						END

				/*
					Step 2: Drop index of current table.
				*/
					SET @INDEX_NAME =''
					SELECT DISTINCT @INDEX_NAME = ind.name
					FROM 
     				sys.indexes ind 
					INNER JOIN 
     				sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
					INNER JOIN 
     				sys.tables t ON ind.object_id = t.object_id 
					WHERE 
     				ind.is_primary_key = 0 
     				AND ind.is_unique_constraint = 0 
     				AND t.is_ms_shipped = 0 
					AND t.name = @TABLE_NAME

				
					IF @INDEX_NAME <> ''
						BEGIN
							SET @MSSG = CONCAT('Removing index ', @INDEX_NAME, ' out ', @TABLE_NAME, ' before importing new records . . .')
							RAISERROR(@MSSG, 0, 1) WITH NOWAIT
							PRINT 'Dropping index started!....'
							EXEC( 'DROP INDEX [' + @INDEX_NAME + '] ON ' + @TABLE_NAME)
							PRINT 'DROP INDEX ' + @INDEX_NAME + ' ON ' + @TABLE_NAME
							PRINT 'Dropping index completed!....'
						END

				/*
					Step 3: Create temporary table to contain all changes relate to current main table
				*/
					SET @MSSG = CONCAT('Updating ', @TABLE_NAME, ' table base on CDHDR/CDPOS table')
                    RAISERROR(@MSSG, 0, 1) WITH NOWAIT
                    EXEC SP_REMOVE_TABLES 'A003_02_TT_CDHDR_CDPOS_CHANGES'
                    SET @SQL_CMD = CONCAT('SELECT * 
											INTO A003_02_TT_CDHDR_CDPOS_CHANGES
											FROM A003_01_TT_INCREMENTAL_CHANGES_SUMMARY
											WHERE TABLE_NAME = ''',@TABLE_NAME,''' AND 
												  EXISTS(
														SELECT TOP 1 1
														FROM ',@TABLE_NAME,'
														WHERE CONCAT(',@KEYFIELD,') = CDPOS_TABKEY
												  )'
										  )

                    EXEC sp_executesql @SQL_CMD
					SET @ROW_COUNT = @@ROWCOUNT
                    SET @MSSG = CONCAT('A003_02_TT_CDHDR_CDPOS_CHANGES has been created with ', @ROW_COUNT, ' records !')
                    RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				
				/*
					Step 4: Add update statements to A003_02_TT_CDHDR_CDPOS_CHANGES tables
				*/
					EXEC SP_REMOVE_TABLES 'A003_03_TT_CDHDR_CDPOS_CHANGES'
					SELECT A003_02_TT_CDHDR_CDPOS_CHANGES.*,
					CASE LOWER(DATA_TYPE)
					WHEN 'date' THEN
						  CONCAT('UPDATE A003_03_TT_CHANGE_RECORDS
								SET	', CDPOS_TABNAME, '_', CDPOS_FNAME, '=''',CONVERT(date, CDPOS_VALUE_NEW, 112),'''
								WHERE CONCAT(', @KEYFIELD,') = ''', CDPOS_TABKEY, ''''
							   )
					WHEN 'decimal' THEN
						  CONCAT('UPDATE A003_03_TT_CHANGE_RECORDS
								SET	', CDPOS_TABNAME, '_', CDPOS_FNAME, '=''',IIF(LEN(TRIM(CDPOS_VALUE_NEW)) > 0, CONVERT(float, dbo.STRING_TO_NUMBER(CDPOS_VALUE_NEW)),'0') ,'''
								WHERE CONCAT(', @KEYFIELD,') = ''', CDPOS_TABKEY, ''''
							   )
					WHEN 'int' THEN
						  CONCAT('UPDATE A003_03_TT_CHANGE_RECORDS
								SET	', CDPOS_TABNAME, '_', CDPOS_FNAME, '=''',IIF(LEN(TRIM(CDPOS_VALUE_NEW)) > 0, CONVERT(int, dbo.STRING_TO_NUMBER(CDPOS_VALUE_NEW)),'0'),'''
								WHERE CONCAT(', @KEYFIELD,') = ''', CDPOS_TABKEY, ''''
		
							   )
					WHEN 'money' THEN
						  CONCAT('UPDATE A003_03_TT_CHANGE_RECORDS
								SET	', CDPOS_TABNAME, '_', CDPOS_FNAME, '=''',IIF(LEN(TRIM(CDPOS_VALUE_NEW)) > 0,
								-- Convert 100.35- to -100.35
								CONVERT(money, dbo.STRING_TO_NUMBER(CDPOS_VALUE_NEW))
								,'0'),'''
								WHERE CONCAT(', @KEYFIELD,') = ''', CDPOS_TABKEY, ''''
							   )
					ELSE
						CONCAT('UPDATE A003_03_TT_CHANGE_RECORDS
								SET	', CDPOS_TABNAME, '_', CDPOS_FNAME, '=''',IIF(LEN(TRIM(CDPOS_VALUE_NEW)) > 0, REPLACE(CDPOS_VALUE_NEW,'''',''),''),'''
								WHERE CONCAT(', @KEYFIELD,') = ''', CDPOS_TABKEY, ''''
							   )
					END AS SQL_UPDATE_CMD

					INTO A003_03_TT_CDHDR_CDPOS_CHANGES
					FROM A003_02_TT_CDHDR_CDPOS_CHANGES
					
						
				/*
					Step 5: Create temporary table to contain all records of current table need to update by CDHDR/CDPOS
				*/

					EXEC SP_REMOVE_TABLES 'A003_03_TT_CHANGE_RECORDS'
					SET @MSSG = 'Creating A003_03_TT_CHANGE_RECORDS . . .'
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
					SET @SQL_CMD = CONCAT('SELECT *
					INTO A003_03_TT_CHANGE_RECORDS
					FROM ', @TABLE_NAME, '
					WHERE EXISTS(
						SELECT TOP 1 1
						FROM A003_02_TT_CDHDR_CDPOS_CHANGES
						WHERE CDPOS_TABKEY = CONCAT(', @KEYFIELD,')
					)')                     
					EXEC sp_executesql @SQL_CMD
					SET @ROW_COUNT = @@ROWCOUNT
					SET @MSSG =CONCAT('A003_03_TT_CHANGE_RECORDS has been created with ', @ROW_COUNT,' completed . . .')
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
					SET @MSSG = 'Creating A003_03_TT_CHANGE_RECORDS completed . . .'
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT


				/*
                    Step 6: Delete all records need to change out current main table
                */
					SET @MSSG = CONCAT('Delete all records need to update out ', @TABLE_NAME,' . . .')
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
					SET @SQL_CMD = CONCAT('DELETE ', @TABLE_NAME, '
					WHERE EXISTS(
						SELECT TOP 1 1
						FROM A003_02_TT_CDHDR_CDPOS_CHANGES
						WHERE CDPOS_TABKEY = CONCAT(', @KEYFIELD,')
					)')
					EXEC sp_executesql @SQL_CMD
					SET @ROW_COUNT = @@ROWCOUNT
					SET @MSSG =CONCAT(@ROW_COUNT,' have been deleted . . .')
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT

				/*
					Step 7: Update A003_03_TT_CHANGE_RECORDS (table contain all records of current main table need to update) table base on A003_03_TT_CDHDR_CDPOS_CHANGES
				*/
					SET @MSSG = 'Start updating . . .'
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
                    SET @ROW_COUNT = 0                         
					IF (SELECT COUNT(*) FROM A003_03_TT_CHANGE_RECORDS) > 0
						BEGIN
							DECLARE UPDATE_CURSOR CURSOR FOR SELECT DISTINCT SQL_UPDATE_CMD FROM A003_03_TT_CDHDR_CDPOS_CHANGES
							OPEN UPDATE_CURSOR
							FETCH NEXT FROM UPDATE_CURSOR INTO @SQL_CMD
							WHILE @@FETCH_STATUS = 0
									BEGIN
									EXEC sp_executesql @SQL_CMD
									--RAISERROR(@SQL_CMD, 0, 1) WITH NOWAIT
									SET @ROW_COUNT = @ROW_COUNT + @@ROWCOUNT
									FETCH NEXT FROM UPDATE_CURSOR INTO @SQL_CMD
								END
							CLOSE UPDATE_CURSOR
							DEALLOCATE UPDATE_CURSOR
						END
					SET @MSSG = CONCAT(@ROW_COUNT,' records have been updated !')
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
					SET @MSSG = CONCAT('Updating ', 'A003_03_TT_CHANGE_RECORDS', ' table base on CDHDR/CDPOS table completed !')
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT

				/*
					Step 8: Insert all updated records back to current main table.
				*/
					SET @MSSG = CONCAT('Insert records which have been updated back to ', @TABLE_NAME, ' . . .')
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
					SET @SQL_CMD = CONCAT('INSERT INTO ', @TABLE_NAME, '
						SELECT * FROM A003_03_TT_CHANGE_RECORDS')
					EXEC sp_executesql @SQL_CMD
					SET @ROW_COUNT = @@ROWCOUNT
					SET @MSSG = CONCAT(@ROW_COUNT, ' records have been inserted !')
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
					SET @MSSG = CONCAT('Insert records which have been updated back to ', @TABLE_NAME, ' completed . . .')
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT

				/*
                    Step 9: Remove dupplication for main table.
                */
                    SET @MSSG = CONCAT('Removing dupplicates from ', @TABLE_NAME, ' . . .')
                    RAISERROR(@MSSG, 0, 1) WITH NOWAIT
                    EXEC A_002B_REMOVE_DUPLICATES @TABLE_NAME_WITHOUT_PREFIX
                    SET @MSSG = CONCAT(@TABLE_NAME, ' duplications have been removed  !')
                    RAISERROR(@MSSG, 0, 1) WITH NOWAIT

				/*
					Step 10: Create index again for current main table
				*/
					SET @MSSG = CONCAT('Creating index for ', @TABLE_NAME, ' . . .')
                    RAISERROR(@MSSG, 0, 1) WITH NOWAIT
                    SET @SQL_CMD = CONCAT('CREATE UNIQUE CLUSTERED INDEX ', @TABLE_NAME, '_', @CURRENT_TIME, ' ON ', @TABLE_NAME, '(',@KEYFIELD,')')
                    SET @MSSG = CONCAT('Creating index on ', @KEYFIELD, ' . . .')
                    RAISERROR(@MSSG, 0, 1) WITH NOWAIT
                    PRINT @SQL_CMD 
                    EXEC sp_executesql @SQL_CMD
                    SET @MSSG = CONCAT(@TABLE_NAME, ' index created !')
                    RAISERROR(@MSSG, 0, 1) WITH NOWAIT

				FETCH NEXT FROM TABLE_CURSOR INTO @TABLE_NAME
			END
			CLOSE TABLE_CURSOR
			DEALLOCATE TABLE_CURSOR

		
END



GO
