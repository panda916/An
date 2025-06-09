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
-- =============================================
CREATE   PROCEDURE [dbo].[A_002A_SS04_INCREMENTAL_DATA_PROCESS]
	@SALE_MODE NVARCHAR(1) = 'Y'
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @TABLE_NAME NVARCHAR(MAX) --Full table name with prefix 'A_' and suffix '_INCREMENTAL_DATA'
			,@TABLE_NAME_MAIN NVARCHAR(MAX) -- Table name with only prefix 'A_'
			,@TABLE_NAME_WITHOUT_PREFIX NVARCHAR(MAX)
			,@APPEND_WITH_NEW_DATA NVARCHAR(1)
			,@REPLACE_BY_NEW_DATA NVARCHAR(1)
			,@KEYFIELD NVARCHAR(MAX)
			,@MSSG NVARCHAR(MAX)
			,@CURRENT_TIME NVARCHAR(MAX)
			,@TABLE_BCK NVARCHAR(MAX)
			,@INDEX_NAME NVARCHAR(MAX)
			,@WHERE_CONDITION NVARCHAR(MAX)
			,@SQL_CMD NVARCHAR(MAX)
			,@ROW_COUNT BIGINT

	SET @TABLE_NAME = ''
	SET @TABLE_NAME_MAIN = ''
	SET @TABLE_NAME_WITHOUT_PREFIX = ''
	SET @APPEND_WITH_NEW_DATA = ''
	SET @REPLACE_BY_NEW_DATA = ''
	SET @INDEX_NAME = ''
	
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A002_IMCREMENTAL_LOG')
		BEGIN
			CREATE TABLE A002_IMCREMENTAL_LOG (DATE_TIME NVARCHAR(20), MAIN_TABLE NVARCHAR(100), INCREMENTAL_TABLE NVARCHAR(100), CONTENT NVARCHAR(MAX))
		END

	/*Step 0: Clean incremental data before combine to main table*/
	EXEC A_002A_SS03_CLEAN_INCREMENTAL_DATA
			
	/*
		Step 1: Get a list tables of incremental data to loop through and append or replace incremental data to main table base on AM_INCREMENTAL_MAPPING
	*/
    BEGIN TRY
        CLOSE TABLE_CURSOR
        DEALLOCATE TABLE_CURSOR
        PRINT 'TABLE_CURSOR have been already close !'
    END TRY
    BEGIN CATCH
        PRINT 'TABLE_CURSOR is already close !'
    END CATCH

	DECLARE TABLE_CURSOR CURSOR FOR SELECT DISTINCT A.TABLE_NAME, B.APPEND_UPDATE_WITH_NEW_DATA, B.REPLACE_BY_NEW_DATA
									FROM INFORMATION_SCHEMA.TABLES AS A
									LEFT JOIN AM_INCREMENTAL_MAPPING AS B
									ON REPLACE(A.TABLE_NAME, '_INCREMENTAL_DATA', '') = B.TABLE_NAME
									WHERE A.TABLE_NAME LIKE '%_INCREMENTAL_DATA'
									ORDER BY A.TABLE_NAME, B.APPEND_UPDATE_WITH_NEW_DATA, B.REPLACE_BY_NEW_DATA
	OPEN TABLE_CURSOR
	FETCH NEXT FROM TABLE_CURSOR INTO @TABLE_NAME, @APPEND_WITH_NEW_DATA, @REPLACE_BY_NEW_DATA

	/*
		Step 2: Loop through each incremental data table the append/replace data to main table base on AM_INCREMENTAL_MAPPING
	*/
	WHILE @@FETCH_STATUS = 0
		BEGIN
				
				SET @MSSG = '-----------------------------------------------Processing '+ @TABLE_NAME + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @KEYFIELD = ''
				SET @TABLE_NAME_MAIN = REPLACE(@TABLE_NAME ,'_INCREMENTAL_DATA', '')
				SET @TABLE_NAME_WITHOUT_PREFIX = RIGHT(@TABLE_NAME_MAIN, LEN(@TABLE_NAME_MAIN) - 2)
				SET @CURRENT_TIME = REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(19) ,GETDATE(), 120),'-',''),' ',''), ':', '')
				SET @TABLE_BCK = @TABLE_NAME_MAIN + '_BCK'
				SET @WHERE_CONDITION = ''
				SET @SQL_CMD = ''
				SET @ROW_COUNT = 0
			

			/*
				Step 2.1: Get key fields of current table from DD03L
			*/
				SET @KEYFIELD = ''

				SELECT 
						@KEYFIELD = CONCAT(@KEYFIELD , ', ', @TABLE_NAME_WITHOUT_PREFIX, '_',  FIELDNAME),
						@WHERE_CONDITION = CONCAT(@WHERE_CONDITION, ' AND ', CONCAT(@TABLE_NAME, '.', @TABLE_NAME_WITHOUT_PREFIX, '_', FIELDNAME, ' = ', @TABLE_NAME_MAIN, '.', @TABLE_NAME_WITHOUT_PREFIX, '_', FIELDNAME, '
	'))

				FROM A_DD03L
				INNER JOIN INFORMATION_SCHEMA.COLUMNS
				ON TABLE_NAME = CONCAT('A_', TABNAME) AND COLUMN_NAME = CONCAT(@TABLE_NAME_WITHOUT_PREFIX, '_', FIELDNAME)
				WHERE TABNAME = @TABLE_NAME_WITHOUT_PREFIX AND KEYFLAG = 'X'
				ORDER BY POSITION
				
				SET @KEYFIELD = RIGHT(@KEYFIELD, LEN(@KEYFIELD) - 2)
				SET @WHERE_CONDITION = RIGHT(@WHERE_CONDITION, LEN(@WHERE_CONDITION) - 5) + ')'

				/*Back up main table if safe mode is 'Y'*/
				IF(@SALE_MODE = 'Y') AND EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TABLE_NAME_MAIN)
				BEGIN
					EXEC SP_REMOVE_TABLES @TABLE_BCK
					SET @SQL_CMD = CONCAT('SELECT *', ' INTO ', @TABLE_NAME_MAIN, '_BCK FROM ', @TABLE_NAME_MAIN)
					SET @MSSG = 'Backing up the ' + @TABLE_NAME_MAIN + ' table . . . '
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
					EXEC sp_executesql @SQL_CMD
					SET @MSSG = @TABLE_NAME_MAIN + ' have been backed up in the ' + @TABLE_NAME_MAIN + '_BCK'
					RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				END
				
				IF @REPLACE_BY_NEW_DATA = 'X'
					BEGIN
						SET @MSSG = CONCAT('Relace data process is running for ', @TABLE_NAME_MAIN, ' table . . .')
						RAISERROR(@MSSG, 0, 1) WITH NOWAIT
						BEGIN TRAN
							BEGIN TRY
								/*
									Step 1: Drop main table if it exist
								*/
									SET @MSSG = CONCAT('Dropping the ', @TABLE_NAME_MAIN, ' . . .')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
									EXEC SP_REMOVE_TABLES @TABLE_NAME_MAIN
									SET @MSSG = CONCAT(@TABLE_NAME_MAIN, ' have been dropped !')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT

								/*
									Step 2: Replace main table by incremental table
								*/
									SET @MSSG = CONCAT('Replacing the ', @TABLE_NAME_MAIN, ' by ', @TABLE_NAME, ' . . .')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
									SET @SQL_CMD = CONCAT('SELECT * INTO ', @TABLE_NAME_MAIN + ' FROM ', @TABLE_NAME)
									EXEC sp_executesql @SQL_CMD
									SET @MSSG = CONCAT(@TABLE_NAME_MAIN, ' have been replaced !')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
					
								/*
									Step 3: Remove duplication from main table
								*/
									SET @MSSG = CONCAT('Removing dupplicates from ', @TABLE_NAME_MAIN, ' . . .')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
									EXEC A_002B_REMOVE_DUPLICATES @TABLE_NAME_WITHOUT_PREFIX
									SET @MSSG = CONCAT(@TABLE_NAME_MAIN, ' duplications have been removed  !')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT

								/*
									Step 4: Create index for main table again
								*/	
									SET @MSSG = CONCAT('Creating index for ', @TABLE_NAME_MAIN, ' . . .')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
									SET @SQL_CMD = CONCAT('CREATE UNIQUE CLUSTERED INDEX ', @TABLE_NAME_MAIN, '_', @CURRENT_TIME, ' ON ', @TABLE_NAME_MAIN, '(',@KEYFIELD,')')
									SET @MSSG = CONCAT('Creating index on ', @KEYFIELD, ' . . .')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
									EXEC sp_executesql @SQL_CMD
									SET @MSSG = CONCAT(@TABLE_NAME_MAIN, ' index have been created !')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT

								/*
									Step 5: Delete incremental table if safe mode is 'N'
								*/
									IF @SALE_MODE = 'N'
										BEGIN
											EXEC SP_REMOVE_TABLES @TABLE_NAME
										END
								/*
									Step 6: Log process to A002_IMCREMENTAL_LOG
								*/
									DELETE A002_IMCREMENTAL_LOG WHERE MAIN_TABLE = @TABLE_NAME_MAIN AND INCREMENTAL_TABLE = @TABLE_NAME
									INSERT INTO A002_IMCREMENTAL_LOG VALUES (@CURRENT_TIME, @TABLE_NAME_MAIN, @TABLE_NAME, CONCAT('Replacing ',@TABLE_NAME_MAIN, ' by ', @TABLE_NAME, ' completed !'))
									
									SET @MSSG = CONCAT('Replace data process is running for ', @TABLE_NAME_MAIN, ' completed . . .')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
									COMMIT TRAN
							END TRY
							BEGIN CATCH
								SET @MSSG = CONCAT('Some error occurs with processing incremental data for ', @TABLE_NAME_MAIN, ' !. Process has been rollback.')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
								INSERT INTO A002_IMCREMENTAL_LOG VALUES (@CURRENT_TIME, @TABLE_NAME_MAIN, @TABLE_NAME, CONCAT('Some error occurs with processing incremental data for ', @TABLE_NAME_MAIN, ' !. Process has been rollback.'))
								ROLLBACK TRAN
							END CATCH
					



					END
				ELSE IF @APPEND_WITH_NEW_DATA = 'X'
					BEGIN
						SET @MSSG = CONCAT('Append data process is running for ', @TABLE_NAME_MAIN, ' table . . .')
						RAISERROR(@MSSG, 0, 1) WITH NOWAIT
						BEGIN TRAN
							BEGIN TRY
								/*
									Step 1: Drop index of current main table if it exists.
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
									AND t.name = @TABLE_NAME_MAIN

									SET @MSSG = CONCAT('Removing index ', @INDEX_NAME, ' out ', @TABLE_NAME_MAIN, ' before importing new records . . .')
									RAISERROR(@MSSG, 0, 1) WITH NOWAIT
									IF @INDEX_NAME <> ''
										BEGIN
											PRINT 'Dropping index started!....'
											EXEC( 'DROP INDEX [' + @INDEX_NAME + '] ON ' + @TABLE_NAME_MAIN)
											PRINT 'DROP INDEX ' + @INDEX_NAME + ' ON ' + @TABLE_NAME_MAIN
											PRINT 'Dropping index completed!....'
										END

								/*
									Step 2: Instead of updating new value for main table, we will delete all old records found in main table and insert them again from incremental table.
										Step 2.1: Delete all records from main table which also exits in the incremental table.
										Step 2.3: Insert new records from incremental table to main table.
								*/
									
									/*
										Step 2.1: Deleting all old records from main table which also found in main and incremental table. 
										Because data from next extract include new data and some records have been updated in this periods
									*/
										SET @MSSG = CONCAT('Removing old records from ', @TABLE_NAME_MAIN, ' . . .')
										RAISERROR(@MSSG, 0, 1) WITH NOWAIT
										SET @SQL_CMD = CONCAT('DELETE FROM ', @TABLE_NAME_MAIN, ' WHERE EXISTS(
                                            SELECT TOP 1 1 FROM ', @TABLE_NAME, ' WHERE ', @WHERE_CONDITION);
                                        EXEC sp_executesql @SQL_CMD
                                        SET @MSSG = CONCAT(@@ROWCOUNT,'  have been removed!')
										RAISERROR(@MSSG, 0, 1) WITH NOWAIT
										SET @MSSG = CONCAT('All old ', @TABLE_NAME_MAIN,' records have been removed!')
										RAISERROR(@MSSG, 0, 1) WITH NOWAIT

									/*
										Step 2.2: Insert new records from [TABLE_NAME]_INCRMENTAL_DATA to main table.
									*/
                                        SET @MSSG = CONCAT('Appending new records from ', @TABLE_NAME, ' to ', @TABLE_NAME_MAIN, ' . . .')
                                        RAISERROR(@MSSG, 0, 1) WITH NOWAIT

                                        SET @SQL_CMD = CONCAT('INSERT INTO ', @TABLE_NAME_MAIN, '
                                            SELECT * FROM ', @TABLE_NAME, ' WHERE NOT EXISTS(
                                                SELECT TOP 1 1 FROM ', @TABLE_NAME_MAIN, ' WHERE ', @WHERE_CONDITION)
                                        EXEC sp_executesql @SQL_CMD
                                        SET @MSSG = CONCAT(@@ROWCOUNT, ' records have been appended !')
                                        RAISERROR(@MSSG, 0, 1) WITH NOWAIT
                                        SET @MSSG = 'Appending process have been comleted !'
                                        RAISERROR(@MSSG, 0, 1) WITH NOWAIT

                                    /*
                                        Step 3: Remove dupplication for main table.
                                    */
                                        SET @MSSG = CONCAT('Removing dupplicates from ', @TABLE_NAME_MAIN, ' . . .')
                                        RAISERROR(@MSSG, 0, 1) WITH NOWAIT
                                        EXEC A_002B_REMOVE_DUPLICATES @TABLE_NAME_WITHOUT_PREFIX
                                        SET @MSSG = CONCAT(@TABLE_NAME_MAIN, ' duplications have been removed  !')
                                        RAISERROR(@MSSG, 0, 1) WITH NOWAIT
													
									
									/*
										Step 8: Create index for main table again
									*/
										SET @MSSG = CONCAT('Creating index for ', @TABLE_NAME_MAIN, ' . . .')
										RAISERROR(@MSSG, 0, 1) WITH NOWAIT
										SET @SQL_CMD = CONCAT('CREATE UNIQUE CLUSTERED INDEX ', @TABLE_NAME_MAIN, '_', @CURRENT_TIME, ' ON ', @TABLE_NAME_MAIN, '(',@KEYFIELD,')')
										SET @MSSG = CONCAT('Creating index on ', @KEYFIELD, ' . . .')
										RAISERROR(@MSSG, 0, 1) WITH NOWAIT
										PRINT @SQL_CMD 
										EXEC sp_executesql @SQL_CMD
										SET @MSSG = CONCAT(@TABLE_NAME_MAIN, ' index created !')
										RAISERROR(@MSSG, 0, 1) WITH NOWAIT

									/*
										Step 9: Delete incremental table if safe mode is 'N'
									*/
										IF @SALE_MODE = 'N'
											BEGIN
												EXEC SP_REMOVE_TABLES @TABLE_NAME
											END
									/*
										Step 10: Log process to A002_IMCREMENTAL_LOG
									*/
										DELETE A002_IMCREMENTAL_LOG WHERE MAIN_TABLE = @TABLE_NAME_MAIN AND INCREMENTAL_TABLE = @TABLE_NAME
										INSERT INTO A002_IMCREMENTAL_LOG VALUES (@CURRENT_TIME, @TABLE_NAME_MAIN, @TABLE_NAME, CONCAT('Append ',@TABLE_NAME_MAIN, ' by ', @TABLE_NAME, ' is completed !'))
									
										SET @MSSG = CONCAT('Append data process is running for ', @TABLE_NAME_MAIN, ' is completed . . .')
										RAISERROR(@MSSG, 0, 1) WITH NOWAIT
									COMMIT TRAN
							END TRY
							BEGIN CATCH
								SET @MSSG = CONCAT('Append data process for ', @TABLE_NAME_MAIN, ' table occur error. All process have been rollback . . .')
								RAISERROR(@MSSG, 0, 1) WITH NOWAIT
								PRINT @SQL_CMD
								ROLLBACK TRAN
							END CATCH


					END
				ELSE 
					PRINT @TABLE_NAME_MAIN + ' have not been mapped in the AM_CREMENTTAL_MAPPING'

				FETCH NEXT FROM TABLE_CURSOR INTO @TABLE_NAME, @APPEND_WITH_NEW_DATA, @REPLACE_BY_NEW_DATA
			END

	CLOSE TABLE_CURSOR
	DEALLOCATE TABLE_CURSOR

END

GO
