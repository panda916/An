USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<vinh.le@aufinia.com>
-- Create date: <April 04, 2021>
-- Description:	<Clean incremental data before replace/append to main table>
-- =============================================
CREATE   PROCEDURE [dbo].[A_002A_SS03_CLEAN_INCREMENTAL_DATA]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
		DECLARE 	 
			 @date1 nvarchar(max)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'date1')
			,@date2 nvarchar(max)				= (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'date2')
			,@MSSG nvarchar(max)
		SET NOCOUNT ON;

   /*
		Step 1: Clean incrental data for A_BKPF_INCREMENTAL_DATA table
   */
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_BKPF_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_BKPF_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_BKPF_INCREMENTAL_DATA
				WHERE BKPF_BUDAT < @date1 OR BKPF_BUDAT > @date2

				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_BKPF_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 2: Clean incrental data for A_BSEG_INCREMENTAL_DATA table
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_BSEG_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_BSEG_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_BSEG_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1
					FROM A_BKPF_INCREMENTAL_DATA
					WHERE BKPF_MANDT = BSEG_MANDT AND BKPF_BUKRS = BSEG_BUKRS AND BKPF_GJAHR = BSEG_GJAHR AND BKPF_BELNR = BSEG_BELNR
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_BSEG_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 3: Clean incrental data for A_BSAD_INCREMENTAL_DATA table
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_BSAD_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_BSAD_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_BSAD_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1
					FROM A_BKPF_INCREMENTAL_DATA
					WHERE BKPF_MANDT = BSAD_MANDT AND BKPF_BUKRS = BSAD_BUKRS AND BKPF_GJAHR = BSAD_GJAHR AND BKPF_BELNR = BSAD_BELNR
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_BSAD_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 4: Clean incrental data for A_BSID_INCREMENTAL_DATA table
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_BSAD_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_BSAD_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_BSAD_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1
					FROM A_BKPF_INCREMENTAL_DATA
					WHERE BKPF_MANDT = BSAD_MANDT AND BKPF_BUKRS = BKPF_BUKRS AND BKPF_GJAHR = BSAD_GJAHR AND BKPF_BELNR = BSAD_BELNR
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_BSAD_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 5: Clean data for A_EKKO_INCREMENTAL_DATA
	*/

		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_EKKO_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_EKKO_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_EKKO_INCREMENTAL_DATA
				WHERE EKKO_AEDAT < @date1 OR EKKO_AEDAT > @date2
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_EKKO_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 6: Clean data for A_EKPO_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_EKPO_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_EKPO_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_EKPO_INCREMENTAL_DATA
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM A_EKKO_INCREMENTAL_DATA
					WHERE EKKO_MANDT= EKPO_MANDT AND EKKO_EBELN = EKPO_EBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_EKPO_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END




	/*
		Step 7: Clean data for A_EKBE_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_EKBE_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_EKBE_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_EKBE_INCREMENTAL_DATA
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM A_EKKO_INCREMENTAL_DATA
					WHERE EKKO_MANDT= EKBE_MANDT AND EKKO_EBELN = EKBE_EBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_EKBE_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END




	/*
		Step 8: Clean data for A_EBAN_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_EBAN_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_EBAN_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_EBAN_INCREMENTAL_DATA
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM A_EKKO_INCREMENTAL_DATA
					WHERE EKKO_MANDT= EBAN_MANDT AND EKKO_EBELN = EBAN_EBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_EBAN_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



		
	/*
		Step 9: Clean data for A_EKKN_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_EKKN_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_EKKN_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_EKKN_INCREMENTAL_DATA
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM A_EKKO_INCREMENTAL_DATA
					WHERE EKKO_MANDT= EKKN_MANDT AND EKKO_EBELN = EKKN_EBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_EKKN_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 10: Clean data for A_RBKP_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_RBKP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_RBKP_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_RBKP_INCREMENTAL_DATA
				WHERE RBKP_CPUDT < @date1 OR RBKP_CPUDT > @date2
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_RBKP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END


	
	/*
		Step 11: Clean data for A_RSEG_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_RSEG_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_RSEG_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_RSEG_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1
					FROM A_RBKP_INCREMENTAL_DATA
					WHERE RBKP_MANDT = RSEG_MANDT AND RBKP_GJAHR = RSEG_GJAHR AND RBKP_BELNR = RSEG_BELNR
				) 
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_RSEG_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 12: Clean data for A_MKPF_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_MKPF_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_MKPF_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_MKPF_INCREMENTAL_DATA
				WHERE MKPF_CPUDT < @date1 OR MKPF_CPUDT > @date2
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_MKPF_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 13: Clean data for A_MSEG_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_MSEG_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_MSEG_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_MSEG_INCREMENTAL_DATA
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM A_MKPF
					WHERE MKPF_MANDT = MSEG_MANDT AND  MKPF_MJAHR = MSEG_MJAHR AND MKPF_MBLNR = MSEG_MBLNR
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_MSEG_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 14: Clean data for A_VBAK_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_VBAK_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_VBAK_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_VBAK_INCREMENTAL_DATA
				WHERE VBAK_ERDAT < @date1 OR VBAK_ERDAT > @date2
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_VBAK_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 15: Clean data for A_VBAP_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_VBAP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_VBAP_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_VBAP_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1 
					FROM A_VBAK_INCREMENTAL_DATA
					WHERE VBAK_MANDT = VBAP_MANDT AND VBAK_VBELN = VBAP_VBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_VBAP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 16: Clean data for A_VBFA_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_VBFA_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_VBFA_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_VBFA_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1 
					FROM A_VBAK_INCREMENTAL_DATA
					WHERE VBAK_MANDT = VBFA_MANDT AND VBAK_VBELN = VBFA_VBELV
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_VBFA_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 17: Clean data for A_VBUK_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_VBUK_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_VBUK_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_VBUK_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1 
					FROM A_VBAK_INCREMENTAL_DATA
					WHERE VBAK_MANDT = VBUK_MANDT AND VBAK_VBELN = VBUK_VBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_VBUK_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 18: Clean data for A_VBUP_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_VBUP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_VBUP_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_VBUP_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1 
					FROM A_VBAK_INCREMENTAL_DATA
					WHERE VBAK_MANDT = VBUP_MANDT AND VBAK_VBELN = VBUP_VBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_VBUP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 19: Clean data for A_VBKD_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_VBKD_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_VBKD_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_VBKD_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1 
					FROM A_VBAK_INCREMENTAL_DATA
					WHERE VBAK_MANDT = VBKD_MANDT AND VBAK_VBELN = VBKD_VBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_VBKD_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END

	/*
		Step 20: Clean data for A_LIKP_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_LIKP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_LIKP_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_LIKP_INCREMENTAL_DATA
				WHERE LIKP_ERDAT < @date1 OR LIKP_ERDAT > @date2
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_LIKP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 21: Clean data for A_LIPS_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_LIPS_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_LIPS_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_LIPS_INCREMENTAL_DATA
				WHERE NOT EXISTS(
						SELECT TOP 1 1
						FROM A_LIKP_INCREMENTAL_DATA
						WHERE LIKP_MANDT = LIPS_MANDT AND LIKP_VBELN = LIPS_VBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_LIPS_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 22: Clean data for A_VBRK_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_VBRK_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_VBRK_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_VBRK_INCREMENTAL_DATA
				WHERE VBRK_ERDAT < @date1 OR VBRK_ERDAT > @date2
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_VBRK_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 23: Clean data for A_VBRP_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_VBRP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_VBRP_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_VBRP_INCREMENTAL_DATA
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM A_VBRK_INCREMENTAL_DATA
					WHERE VBRK_MANDT = VBRP_MANDT AND VBRK_VBELN = VBRP_VBELN
				)
				
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_VBRP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 21: Clean data for A_REGUH_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_REGUH_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_REGUH_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_REGUH_INCREMENTAL_DATA
				WHERE REGUH_LAUFD < @date1 OR REGUH_LAUFD > @date2
				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_REGUH_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 22: Clean data for A_REGUP_INCREMENTAL_DATA
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_REGUP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_REGUP_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_REGUP_INCREMENTAL_DATA
				WHERE REGUP_LAUFD < @date1 OR REGUP_LAUFD > @date2

				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_REGUP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 23: Clean data for COPA table
	*/
		DECLARE @COPA_TABLE NVARCHAR(max)
		SET @COPA_TABLE = (SELECT GLOBALS_VALUE FROM AM_GLOBALS WHERE GLOBALS_PARAMETER = 'COPA_TABLE_NAME')
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_REGUP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ @COPA_TABLE + '_INCREMENTAL_DATA-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @COPA_TABLE = 'DELETE FROM ' + @COPA_TABLE + '_INCREMENTAL_DATA WHERE ' + 
									RIGHT(@COPA_TABLE, LEN(@COPA_TABLE) -2 ) + '_BUDAT < ''' + @date1 + ''' OR ' + RIGHT(@COPA_TABLE, LEN(@COPA_TABLE) -2 )
									+ '_BUDAT > ''' + @date2 + ''''

				EXEC sp_executesql @COPA_TABLE

				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = @COPA_TABLE + '_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 23: Clean data for A_ANEK_INCREMENTAL_DATA table
	*/
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_ANEK_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_ANEK_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_ANEK_INCREMENTAL_DATA
				WHERE ANEK_BUDAT < @date1 OR ANEK_BUDAT > @date2

				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_ANEK_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 24: Clean data for A_ANEP_INCREMENTAL_DATA table
	*/

		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_ANEP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_ANEP_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_ANEP_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1
					FROM A_ANEK
					WHERE ANEK_MANDT = ANEP_MANDT AND ANEK_BUKRS = ANEP_BUKRS AND ANEK_GJAHR = ANEP_GJAHR
						  AND ANEK_ANLN1 = ANEP_ANLN1 AND ANEK_ANLN2 = ANEP_ANLN2 AND ANEK_LNRAN = ANEP_LNRAN
				)

				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_ANEP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 25: Clean data for A_ANEP_INCREMENTAL_DATA table
	*/

		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_ANEP_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_ANEP_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_ANEP_INCREMENTAL_DATA
				WHERE NOT EXISTS (
					SELECT TOP 1 1
					FROM A_ANEK
					WHERE ANEK_MANDT = ANEP_MANDT AND ANEK_BUKRS = ANEP_BUKRS AND ANEK_GJAHR = ANEP_GJAHR
						  AND ANEK_ANLN1 = ANEP_ANLN1 AND ANEK_ANLN2 = ANEP_ANLN2 AND ANEK_LNRAN = ANEP_LNRAN
				)

				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_ANEP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 26: Clean data for A_CDHDR_INCREMENTAL_DATA table
	*/

		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_CDHDR_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_CDHDR_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_CDHDR_INCREMENTAL_DATA
				WHERE CDHDR_UDATE < @date1 OR CDHDR_UDATE > @date2

				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_ANEP_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END



	/*
		Step 27: Clean data for A_CDPOS_INCREMENTAL_DATA table
	*/

		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'A_CDPOS_INCREMENTAL_DATA')
			BEGIN
				SET @MSSG = '-----------------------------------------------Processing '+ 'A_CDPOS_INCREMENTAL_DATA' + '-----------------------------------------------'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				DELETE A_CDPOS_INCREMENTAL_DATA
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM A_CDHDR_INCREMENTAL_DATA
					WHERE CDHDR_MANDANT = CDPOS_MANDANT AND CDHDR_OBJECTCLAS = CDPOS_OBJECTCLAS AND CDHDR_OBJECTID = CDPOS_OBJECTID AND
						  CDHDR_CHANGENR = CDPOS_CHANGENR 
					)

				SET @MSSG = CONCAT(@@ROWCOUNT, ' records out of scope been cleaned.')
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
				SET @MSSG = 'A_CDPOS_INCREMENTAL_DATA data has been cleaned.'
				RAISERROR(@MSSG, 0, 1) WITH NOWAIT
			END


END
GO
