USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Vinh Le>
-- Create date: <05-08-2019>
-- Description:	<Extract trial balance data from ACDOCA script>
-- 24-03-2022	 Thuan	 Remove MANDT field in join
-- 22-06-2022	 Khoa    Replace A_ACDOCA to B00_ACDOCA
-- =============================================
CREATE PROCEDURE [dbo].[script_B00_SS01_EXTRACT_BALANCE_INFO] 
AS
--DYNAMIC_SCRIPT_START
BEGIN
	/* Initiate the log */ 
	--Create database log table if it does not exist
	IF OBJECT_ID('LOG_SP_EXECUTION', 'U') IS NULL BEGIN CREATE TABLE [DBO].[LOG_SP_EXECUTION] ([DATABASE] NVARCHAR(MAX) NULL,[OBJECT] NVARCHAR(MAX) NULL,[OBJECT_TYPE] NVARCHAR(MAX) NULL,[USER] NVARCHAR(MAX) NULL,[DATE] DATE NULL,[TIME] TIME NULL,[DESCRIPTION] NVARCHAR(MAX) NULL,[TABLE] NVARCHAR(MAX),[ROWS] INT) END
 
	--Log start of procedure
	INSERT INTO [DBO].[LOG_SP_EXECUTION] ([DATABASE],[OBJECT],[OBJECT_TYPE],[USER],[DATE],[TIME],[DESCRIPTION],[TABLE],[ROWS])
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(DATE,GETDATE()),CONVERT(TIME,GETDATE()),'Procedure started',NULL,NULL
 
	/* Initialize parameters from globals table */
    DECLARE  
				@CURRENCY NVARCHAR(3)                 = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'currency')
				,@DATE1 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date1')
				,@DATE2 NVARCHAR(MAX)                           = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'date2')
				,@DOWNLOADDATE NVARCHAR(MAX)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'downloaddate')
				,@DATEFORMAT VARCHAR(3)             = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'dateformat')
				,@EXCHANGERATETYPE NVARCHAR(MAX)  = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'exchangeratetype')
				,@LANGUAGE1 NVARCHAR(3)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language1')
				,@LANGUAGE2 NVARCHAR(3)                = (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'language2')
				,@LIMIT_RECORDS INT                    = CAST((SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'LIMIT_RECORDS') AS INT)
				,@FISCAL_YEAR_FROM NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'FISCAL_YEAR_FROM')
				,@FISCAL_YEAR_TO NVARCHAR(MAX)					= (SELECT GLOBALS_VALUE FROM [AM_GLOBALS] WHERE GLOBALS_PARAMETER = 'FISCAL_YEAR_TO')
                 SET DATEFORMAT @DATEFORMAT;
 
	/*Test mode*/
 
	SET ROWCOUNT @LIMIT_RECORDS
 
	/*Change history comments*/
 
	/*
		   Title                : script_B00_SS01_EXTRACT_TB_INFO
		   Description   : 
    
		   --------------------------------------------------------------
		   Update history
		   --------------------------------------------------------------
		   Date                     |  Who                  |      Description
		   DD-MM-YYYY                        Initials             Initial version
		   01-08-2019				| Vinh Le				|		Createion	

	*/
	
			--Step 1: Generate view of G/L entities on ACDOCA table
			EXEC SP_REMOVE_TABLES 'B00_01_TT_TB'
			SELECT 
				ACDOCA_RCLNT
				,ACDOCA_RBUKRS
				,ACDOCA_RACCT
				,ACDOCA_RYEAR
				,ACDOCA_RLDNR
				,ACDOCA_RRCTY
				,ACDOCA_DRCRK
				,ACDOCA_RBUSA
				,ACDOCA_KOKRS
				,ACDOCA_KTOPL
				,ACDOCA_POPER
				,ACDOCA_BSTAT
				,ACDOCA_BLART
				,IIF(ACDOCA_BUZEI = '000', 'X','') ZF_ACDOCA_BUZEI_ZERO_FLAG
				,ACDOCA_UMSKZ
				,ACDOCA_KOART
				,ACDOCA_RHCUR
				,ACDOCA_HSL
				,ACDOCA_RKCUR
				,ACDOCA_KSL
				,ACDOCA_OSL
				,ACDOCA_ROCUR
			INTO B00_01_TT_TB
			FROM B00_ACDOCA
			WHERE ACDOCA_GJAHR >= @FISCAL_YEAR_FROM AND ACDOCA_GJAHR <= @FISCAL_YEAR_TO
			



			--Step 2: Create final trial balance cube (filter the B00_01_TT_TB table base on Trial Balance logic in abap code)
			EXEC SP_REMOVE_TABLES 'B00_TB'
			SELECT 
				ACDOCA_RCLNT
				,ACDOCA_RLDNR
				,ACDOCA_RYEAR
				,ACDOCA_RBUKRS
				,ACDOCA_RRCTY
				,ACDOCA_RACCT
				,ACDOCA_RBUSA
				,ACDOCA_DRCRK
				,ACDOCA_BSTAT
				,ACDOCA_BLART
				,ACDOCA_UMSKZ
				,ACDOCA_KOKRS
				,ACDOCA_KTOPL
				,ZF_ACDOCA_BUZEI_ZERO_FLAG
				,ACDOCA_KOART
				,CONCAT(SUBSTRING('00',1, 2 - LEN(ACDOCA_POPER % 16)),CAST((ACDOCA_POPER % 16) AS NVARCHAR)) AS ACDOCA_MONAT
				,ACDOCA_RHCUR
				,ACDOCA_ROCUR
				,SUM( ACDOCA_HSL ) ACDOCA_HSL
				,ACDOCA_RKCUR
				,SUM( ACDOCA_KSL ) AS ACDOCA_KSL
				,SUM( ACDOCA_OSL) AS ACDOCA_OSL
                ,ROW_NUMBER() OVER (ORDER BY ACDOCA_RCLNT) ZF_TB_JOIN_KEY
			INTO B00_TB
			FROM B00_01_TT_TB
			WHERE ACDOCA_BSTAT IN ('','L','U','J','C','T') --S/4HANA logic
			--WHERE ACDOCA_BSTAT IN ('', 'A', 'B', 'C', 'D', 'J', 'U') --Jesper
			GROUP BY ACDOCA_RCLNT
					,ACDOCA_RYEAR
					,ACDOCA_DRCRK
					,ACDOCA_BSTAT
					,ACDOCA_BLART
					,ACDOCA_KOART
					,ACDOCA_UMSKZ
					,ACDOCA_POPER
					,ACDOCA_RLDNR
					,ACDOCA_RRCTY
					,ACDOCA_RACCT
					,ACDOCA_RBUKRS
					,ACDOCA_RBUSA
					,ACDOCA_KOKRS
					,ZF_ACDOCA_BUZEI_ZERO_FLAG
					,ACDOCA_KTOPL
					,ACDOCA_RHCUR
					,ACDOCA_RKCUR
					,ACDOCA_ROCUR



		--Step 3: Extract Customer balance for ACDOCA table
		EXEC SP_REMOVE_TABLES 'B00_02_TT_CUSTOMER_BALANCE'
		SELECT ACDOCA_RCLNT,
			   ACDOCA_RBUKRS,
			   ACDOCA_GJAHR,
			   ACDOCA_BELNR,
			   ACDOCA_BUZEI,
			   ACDOCA_AUGDT,
			   ACDOCA_AUGBL,
			   ACDOCA_AUGGJ,
			   ACDOCA_KUNNR,
			   ACDOCA_POPER,
			   ACDOCA_UMSKZ,
			   ACDOCA_RHCUR,
			   IIF(SUM(ACDOCA_HSL)>=0,'S', 'H') ACDOCA_DRCRK,
			   SUM(ACDOCA_HSL) ACDOCA_HSL
		INTO B00_02_TT_CUSTOMER_BALANCE
		FROM B00_ACDOCA
		WHERE ACDOCA_BUZEI <> '000' AND ACDOCA_BSTAT = '' AND ACDOCA_KOART = 'D'
		GROUP BY ACDOCA_RCLNT, ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_BELNR, ACDOCA_BUZEI, ACDOCA_AUGDT, ACDOCA_AUGGJ, ACDOCA_AUGBL, ACDOCA_POPER, ACDOCA_UMSKZ,ACDOCA_RHCUR, ACDOCA_KUNNR

		--Get all documents relate to customer include Normal and Special G/L to calculate Debit/Credit amount per MONAT
		EXEC SP_REMOVE_TABLES 'B00_03_TT_CUSTOMER_BALANCE'
		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			RIGHT(ACDOCA_POPER, 2) ACDOCA_MONAT,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			0 ZF_OPENING_BALANCE,
			IIF(ACDOCA_DRCRK = 'S', SUM(ACDOCA_HSL), 0) ACDOCA_HSL_S,
			IIF(ACDOCA_DRCRK = 'H', SUM(ACDOCA_HSL), 0) ACDOCA_HSL_H
		INTO B00_03_TT_CUSTOMER_BALANCE
		FROM B00_02_TT_CUSTOMER_BALANCE
		GROUP BY ACDOCA_RCLNT, ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_KUNNR, ACDOCA_POPER, ACDOCA_UMSKZ, ACDOCA_RHCUR, ACDOCA_DRCRK

		UNION ALL 

		--Get all document still open in the current period to calculate OPENING balance
		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			FINS_BCF_FY_FYEAR ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			'00',
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			SUM(ACDOCA_HSL),
			0,
			0
		FROM B00_02_TT_CUSTOMER_BALANCE 
		INNER JOIN	A_FINS_BCF_FY
			ON ACDOCA_RBUKRS = FINS_BCF_FY_CCODE AND 
			   ACDOCA_GJAHR < FINS_BCF_FY_FYEAR
		WHERE (ACDOCA_AUGDT IS NULL OR ACDOCA_AUGBL = 'ALE-extern' OR ACDOCA_AUGGJ >= FINS_BCF_FY_FYEAR)
		GROUP BY ACDOCA_RCLNT, ACDOCA_RBUKRS, FINS_BCF_FY_FYEAR, ACDOCA_KUNNR, ACDOCA_POPER, ACDOCA_UMSKZ, ACDOCA_RHCUR

		UNION ALL

		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			'00',
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			0,
			0,
			0
		FROM B00_02_TT_CUSTOMER_BALANCE
		GROUP BY ACDOCA_RCLNT, ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_KUNNR, ACDOCA_POPER, ACDOCA_UMSKZ, ACDOCA_RHCUR

		--Step 4: Group customer balance values by client, company, fiscal year, customer, posting period
		EXEC SP_REMOVE_TABLES 'B00_04_TT_CUSTOMER_BALANCE'
		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			ACDOCA_MONAT,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			SUM(ZF_OPENING_BALANCE) ZF_OPENING_BALANCE,
			SUM(ACDOCA_HSL_S) ACDOCA_HSL_S,
			SUM(ACDOCA_HSL_H) ACDOCA_HSL_H
		INTO B00_04_TT_CUSTOMER_BALANCE
		FROM B00_03_TT_CUSTOMER_BALANCE
		WHERE ACDOCA_UMSKZ = '' AND ACDOCA_GJAHR >= @FISCAL_YEAR_FROM AND ACDOCA_GJAHR <= @FISCAL_YEAR_TO
		GROUP BY ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			ACDOCA_MONAT,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR
		HAVING SUM(ACDOCA_HSL_S) <> 0 OR SUM(ACDOCA_HSL_H) <> 0 OR ACDOCA_MONAT = '00'

		--Step 5: Calculate cumulative column and total row.
		EXEC SP_REMOVE_TABLES 'B00_05_TT_CUSTOMER_BALANCE'
		--Calculate cumulative column
		SELECT *,
			CAST(0.00 AS money) ZF_CUMULATIVE_VALUE --This value will be updated later
		INTO B00_05_TT_CUSTOMER_BALANCE
		FROM B00_04_TT_CUSTOMER_BALANCE

		UNION ALL

		--Calculate total row
		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			'Total',
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			SUM(ZF_OPENING_BALANCE) ZF_OPENING_BALANCE,
			SUM(ACDOCA_HSL_S) ACDOCA_HSL_S,
			SUM(ACDOCA_HSL_H) ACDOCA_HSL_H,
			SUM(ZF_OPENING_BALANCE) + SUM(ACDOCA_HSL_S) + SUM(ACDOCA_HSL_H)
		FROM B00_04_TT_CUSTOMER_BALANCE
		GROUP BY ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR
	
		--Step 6: Update missing value
		UPDATE B00_05_TT_CUSTOMER_BALANCE
		SET ZF_CUMULATIVE_VALUE = ZF_OPENING_BALANCE
		WHERE ACDOCA_MONAT = '00'

		UPDATE B00_05_TT_CUSTOMER_BALANCE
		SET ZF_CUMULATIVE_VALUE = GROUPED.ZF_CUMULATIVE_VALUE
		FROM ( SELECT A.ACDOCA_RCLNT, A.ACDOCA_RBUKRS, A.ACDOCA_GJAHR, A.ACDOCA_KUNNR, A.ACDOCA_UMSKZ, A.ACDOCA_RHCUR, A.ACDOCA_MONAT,
					  (SUM(B.ZF_OPENING_BALANCE) + SUM(B.ACDOCA_HSL_S) + SUM(B.ACDOCA_HSL_H)) ZF_CUMULATIVE_VALUE
			FROM B00_05_TT_CUSTOMER_BALANCE  A
			INNER JOIN
			B00_05_TT_CUSTOMER_BALANCE  B
			ON A.ACDOCA_RBUKRS = B.ACDOCA_RBUKRS AND
			   A.ACDOCA_GJAHR = B.ACDOCA_GJAHR AND
			   A.ACDOCA_KUNNR = B.ACDOCA_KUNNR AND
			   A.ACDOCA_UMSKZ = B.ACDOCA_UMSKZ AND
			   A.ACDOCA_RHCUR = B.ACDOCA_RHCUR AND
			   CAST(A.ACDOCA_MONAT AS INT) >=  CAST(B.ACDOCA_MONAT AS INT)
			   WHERE A.ACDOCA_MONAT NOT IN ('00', 'Total') AND B.ACDOCA_MONAT NOT IN ('Total')
			   GROUP BY A.ACDOCA_RCLNT, A.ACDOCA_RBUKRS, A.ACDOCA_GJAHR, A.ACDOCA_KUNNR, A.ACDOCA_UMSKZ, A.ACDOCA_RHCUR, A.ACDOCA_MONAT
		   ) GROUPED
		WHERE  B00_05_TT_CUSTOMER_BALANCE.ACDOCA_RBUKRS = GROUPED.ACDOCA_RBUKRS
		AND B00_05_TT_CUSTOMER_BALANCE.ACDOCA_GJAHR = GROUPED.ACDOCA_GJAHR AND B00_05_TT_CUSTOMER_BALANCE.ACDOCA_KUNNR = GROUPED.ACDOCA_KUNNR
		AND B00_05_TT_CUSTOMER_BALANCE.ACDOCA_UMSKZ = GROUPED.ACDOCA_UMSKZ AND B00_05_TT_CUSTOMER_BALANCE.ACDOCA_RHCUR = GROUPED.ACDOCA_RHCUR
		AND B00_05_TT_CUSTOMER_BALANCE.ACDOCA_MONAT = GROUPED.ACDOCA_MONAT

		ALTER TABLE B00_05_TT_CUSTOMER_BALANCE ALTER COLUMN ACDOCA_MONAT VARCHAR(25)
		UPDATE B00_05_TT_CUSTOMER_BALANCE
		SET ACDOCA_MONAT = '00-Begin period'
		WHERE ACDOCA_MONAT = '00'


		--Step 7: Get description for company, customer and currency factor
		EXEC SP_REMOVE_TABLES 'B00_06_RT_CUSTOMER_BALANCE'
		SELECT ACDOCA_RCLNT,
			   ACDOCA_RBUKRS,
			   T001_BUTXT,
			   ACDOCA_GJAHR,
			   ACDOCA_KUNNR,
			   KNA1_NAME1,
			   KNA1_LAND1,
               T005T_NATIO,
			   ACDOCA_MONAT,
			   CONCAT(ACDOCA_GJAHR,'-',LEFT(ACDOCA_MONAT,2)) ZF_ACDOCA_GJAHR_MONAT,
			   ACDOCA_UMSKZ,
			   ACDOCA_RHCUR,
			   CAST(ZF_OPENING_BALANCE AS money)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_OPENING_BALANCE,
			   CAST(ACDOCA_HSL_S AS money)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_ACDOCA_HSL_S,
			   CAST(ACDOCA_HSL_H AS money)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_ACDOCA_HSL_H,
			   CAST(ZF_CUMULATIVE_VALUE AS money)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_CUMULATIVE_VALUE
		INTO B00_06_RT_CUSTOMER_BALANCE
		FROM B00_05_TT_CUSTOMER_BALANCE
		LEFT JOIN A_T001
			ON ACDOCA_RBUKRS = T001_BUKRS
		LEFT JOIN B00_TCURX
			ON B00_TCURX.TCURX_CURRKEY = ACDOCA_RHCUR
		LEFT JOIN A_KNA1
			ON KNA1_KUNNR = ACDOCA_KUNNR
        LEFT JOIN A_T005T
            ON A_T005T.T005T_SPRAS IN ('E', 'EN') AND
               A_T005T.T005T_LAND1 = A_KNA1.KNA1_LAND1


		--Step 8: Get all customer documents of Special G/L ledger
		EXEC SP_REMOVE_TABLES 'B00_07_TT_CUSTOMER_BALANCE_SPGL'
		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			IIF(ACDOCA_UMSKZ = '','zAccount balance', ACDOCA_UMSKZ) ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			SUM(ZF_OPENING_BALANCE) ZF_BALANCE_CARRIED_FORWARD,
			SUM(ACDOCA_HSL_S) ZF_ACDOCA_HSL_S,
			SUM(ACDOCA_HSL_H) ZF_ACDOCA_HSL_H
		INTO B00_07_TT_CUSTOMER_BALANCE_SPGL
		FROM B00_03_TT_CUSTOMER_BALANCE
		WHERE ACDOCA_GJAHR >= @FISCAL_YEAR_FROM AND ACDOCA_GJAHR <= @FISCAL_YEAR_TO
		GROUP BY ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_KUNNR,
			IIF(ACDOCA_UMSKZ = '','zAccount balance', ACDOCA_UMSKZ),
			ACDOCA_RHCUR
		HAVING SUM(ACDOCA_HSL_H) <> 0 OR SUM(ACDOCA_HSL_S) <> 0 OR SUM(ZF_OPENING_BALANCE) <> 0

		--Step 9: Create total rows for each customer in special g/l
		EXEC SP_REMOVE_TABLES 'B00_08_TT_CUSTOMER_BALANCE_SPGL'

		SELECT *
		INTO B00_08_TT_CUSTOMER_BALANCE_SPGL
		FROM B00_07_TT_CUSTOMER_BALANCE_SPGL

		UNION ALL

		SELECT ACDOCA_RCLNT,
			   ACDOCA_RBUKRS,
			   ACDOCA_GJAHR,
			   ACDOCA_KUNNR,
			   'zTotal',
			   ACDOCA_RHCUR,
			   SUM(ZF_BALANCE_CARRIED_FORWARD),
			   SUM(ZF_ACDOCA_HSL_S),
			   SUM(ZF_ACDOCA_HSL_H)

		FROM B00_07_TT_CUSTOMER_BALANCE_SPGL
		GROUP BY ACDOCA_RCLNT,
				 ACDOCA_RBUKRS,
				 ACDOCA_GJAHR,
				 ACDOCA_KUNNR,
				 ACDOCA_RHCUR

		--Step 10: Get description for company, customer, currency factor
		EXEC SP_REMOVE_TABLES 'B00_09_RT_CUSTOMER_BALANCE_SPGL'
		SELECT ACDOCA_RCLNT,
			   ACDOCA_RBUKRS,
			   T001_BUTXT,
			   ACDOCA_GJAHR,
			   ACDOCA_KUNNR,
			   KNA1_NAME1,
			   KNA1_LAND1,
               T005T_NATIO,
			   ACDOCA_UMSKZ,
			   T074T_LTEXT,
			   ACDOCA_RHCUR,
			   CAST(ZF_BALANCE_CARRIED_FORWARD AS money) * ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_BALANCE_CARRIED_FORWARD,
			   CAST(ZF_ACDOCA_HSL_S AS money) * ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_ACDOCA_HSL_S,
			   CAST(ZF_ACDOCA_HSL_H AS money) * ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_ACDOCA_HSL_H
		INTO B00_09_RT_CUSTOMER_BALANCE_SPGL
		FROM B00_08_TT_CUSTOMER_BALANCE_SPGL
		LEFT JOIN A_T001
			ON ACDOCA_RBUKRS = T001_BUKRS
		LEFT JOIN B00_TCURX
			ON B00_TCURX.TCURX_CURRKEY = ACDOCA_RHCUR
		LEFT JOIN A_KNA1
			ON  KNA1_KUNNR = ACDOCA_KUNNR 
        LEFT JOIN A_T005T
            ON A_T005T.T005T_SPRAS IN ('E', 'EN') AND
               A_T005T.T005T_LAND1 = A_KNA1.KNA1_LAND1
		LEFT JOIN A_T074T
		ON T074T_SHBKZ = ACDOCA_UMSKZ AND
		   T074T_KOART = 'D'
		ORDER BY ACDOCA_RCLNT, ACDOCA_RBUKRS,	ACDOCA_GJAHR, ACDOCA_KUNNR,ACDOCA_UMSKZ

		--Step 11: Extract vendor balance for ACDOCA table
		EXEC SP_REMOVE_TABLES 'B00_09_TT_VENDOR_BALANCE'
		EXEC SP_REMOVE_TABLES ''
		SELECT ACDOCA_RCLNT,
			   ACDOCA_RBUKRS,
			   ACDOCA_GJAHR,
			   ACDOCA_BELNR,
			   ACDOCA_BUZEI,
			   ACDOCA_AUGDT,
			   ACDOCA_AUGBL,
			   ACDOCA_AUGGJ,
			   ACDOCA_LIFNR,
			   ACDOCA_POPER,
			   ACDOCA_UMSKZ,
			   ACDOCA_RHCUR,
			   IIF(SUM(ACDOCA_HSL)>=0,'S', 'H') ACDOCA_DRCRK,
			   SUM(ACDOCA_HSL) ACDOCA_HSL
		INTO B00_09_TT_VENDOR_BALANCE
		FROM B00_ACDOCA
		WHERE ACDOCA_BUZEI <> '000' AND ACDOCA_BSTAT = '' AND ACDOCA_KOART = 'K'
		GROUP BY ACDOCA_RCLNT, ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_BELNR, ACDOCA_BUZEI, ACDOCA_AUGDT, ACDOCA_AUGGJ, ACDOCA_AUGBL, ACDOCA_POPER, ACDOCA_UMSKZ,ACDOCA_RHCUR, ACDOCA_LIFNR

		--Get all documents relate to vendor include Normal and Special G/L to calculate Debit/Credit amount per MONAT
		EXEC SP_REMOVE_TABLES 'B00_10_TT_VENDOR_BALANCE'

		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			RIGHT(ACDOCA_POPER, 2) ACDOCA_MONAT,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			0 ZF_OPENING_BALANCE,
			IIF(ACDOCA_DRCRK = 'S', SUM(ACDOCA_HSL), 0) ACDOCA_HSL_S,
			IIF(ACDOCA_DRCRK = 'H', SUM(ACDOCA_HSL), 0) ACDOCA_HSL_H

		INTO B00_10_TT_VENDOR_BALANCE
		FROM B00_09_TT_VENDOR_BALANCE
		GROUP BY ACDOCA_RCLNT, ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_LIFNR, ACDOCA_POPER, ACDOCA_UMSKZ, ACDOCA_RHCUR, ACDOCA_DRCRK

		UNION ALL 

		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			FINS_BCF_FY_FYEAR ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			'00' ACDOCA_MONAT,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			SUM(ACDOCA_HSL),
			0,
			0
		FROM B00_09_TT_VENDOR_BALANCE 
		INNER JOIN	A_FINS_BCF_FY
			ON ACDOCA_RBUKRS = FINS_BCF_FY_CCODE AND 
			   ACDOCA_GJAHR < FINS_BCF_FY_FYEAR
		WHERE (ACDOCA_AUGDT IS NULL OR ACDOCA_AUGBL = 'ALE-extern' OR ACDOCA_AUGGJ >= FINS_BCF_FY_FYEAR)
		GROUP BY ACDOCA_RCLNT, ACDOCA_RBUKRS, FINS_BCF_FY_FYEAR, ACDOCA_LIFNR, ACDOCA_POPER, ACDOCA_UMSKZ, ACDOCA_RHCUR

		UNION ALL

		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			'00',
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			0,
			0,
			0

		FROM B00_09_TT_VENDOR_BALANCE
		GROUP BY ACDOCA_RCLNT, ACDOCA_RBUKRS, ACDOCA_GJAHR, ACDOCA_LIFNR, ACDOCA_POPER, ACDOCA_UMSKZ, ACDOCA_RHCUR


		--Step 12: Group vendor balance values by client, company, fiscal year, vendor, posting period
		EXEC SP_REMOVE_TABLES 'B00_11_TT_VENDOR_BALANCE'
		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			ACDOCA_MONAT,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			SUM(ZF_OPENING_BALANCE) ZF_OPENING_BALANCE,
			SUM(ACDOCA_HSL_S) ACDOCA_HSL_S,
			SUM(ACDOCA_HSL_H) ACDOCA_HSL_H
		INTO B00_11_TT_VENDOR_BALANCE
		FROM B00_10_TT_VENDOR_BALANCE
		WHERE ACDOCA_UMSKZ = '' AND ACDOCA_GJAHR >= @FISCAL_YEAR_FROM AND ACDOCA_GJAHR <= @FISCAL_YEAR_TO
		GROUP BY ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			ACDOCA_MONAT,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR
		HAVING SUM(ACDOCA_HSL_H) <> 0 OR SUM(ACDOCA_HSL_S) <> 0 OR ACDOCA_MONAT = '00'

		--Step 13: Calculate cumulative column and total row.
		EXEC SP_REMOVE_TABLES 'B00_12_TT_VENDOR_BALANCE'
		--Calculate cumulative column
		SELECT *,
			CAST(0.00 AS money) ZF_CUMULATIVE_VALUE --This value will be updated later
		INTO B00_12_TT_VENDOR_BALANCE
		FROM B00_11_TT_VENDOR_BALANCE

		UNION ALL

		--Calculate total row
		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			'Total',
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			SUM(ZF_OPENING_BALANCE) ZF_OPENING_BALANCE,
			SUM(ACDOCA_HSL_S) ACDOCA_HSL_S,
			SUM(ACDOCA_HSL_H) ACDOCA_HSL_H,
			SUM(ZF_OPENING_BALANCE) + SUM(ACDOCA_HSL_S) + SUM(ACDOCA_HSL_H)
		FROM B00_11_TT_VENDOR_BALANCE
		GROUP BY ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			ACDOCA_UMSKZ,
			ACDOCA_RHCUR

		--Step 14: Update missing value
		UPDATE B00_12_TT_VENDOR_BALANCE
		SET ZF_CUMULATIVE_VALUE = ZF_OPENING_BALANCE
		WHERE ACDOCA_MONAT = '00'

		UPDATE B00_12_TT_VENDOR_BALANCE
		SET ZF_CUMULATIVE_VALUE = GROUPED.ZF_CUMULATIVE_VALUE
		FROM ( SELECT A.ACDOCA_RCLNT, A.ACDOCA_RBUKRS, A.ACDOCA_GJAHR, A.ACDOCA_LIFNR, A.ACDOCA_UMSKZ, A.ACDOCA_RHCUR, A.ACDOCA_MONAT,
					  (SUM(B.ZF_OPENING_BALANCE) + SUM(B.ACDOCA_HSL_S) + SUM(B.ACDOCA_HSL_H)) ZF_CUMULATIVE_VALUE
			FROM B00_12_TT_VENDOR_BALANCE  A
			INNER JOIN
			B00_12_TT_VENDOR_BALANCE  B
			ON A.ACDOCA_RBUKRS = B.ACDOCA_RBUKRS AND
			   A.ACDOCA_GJAHR = B.ACDOCA_GJAHR AND
			   A.ACDOCA_LIFNR = B.ACDOCA_LIFNR AND
			   A.ACDOCA_UMSKZ = B.ACDOCA_UMSKZ AND
			   A.ACDOCA_RHCUR = B.ACDOCA_RHCUR AND
			   CAST(A.ACDOCA_MONAT AS INT) >=  CAST(B.ACDOCA_MONAT AS INT)
			   WHERE A.ACDOCA_MONAT NOT IN ('00', 'Total') AND B.ACDOCA_MONAT NOT IN ('Total')
			   GROUP BY A.ACDOCA_RCLNT, A.ACDOCA_RBUKRS, A.ACDOCA_GJAHR, A.ACDOCA_LIFNR, A.ACDOCA_UMSKZ, A.ACDOCA_RHCUR, A.ACDOCA_MONAT
		   ) GROUPED
		WHERE  B00_12_TT_VENDOR_BALANCE.ACDOCA_RBUKRS = GROUPED.ACDOCA_RBUKRS
		AND B00_12_TT_VENDOR_BALANCE.ACDOCA_GJAHR = GROUPED.ACDOCA_GJAHR AND B00_12_TT_VENDOR_BALANCE.ACDOCA_LIFNR = GROUPED.ACDOCA_LIFNR
		AND B00_12_TT_VENDOR_BALANCE.ACDOCA_UMSKZ = GROUPED.ACDOCA_UMSKZ AND B00_12_TT_VENDOR_BALANCE.ACDOCA_RHCUR = GROUPED.ACDOCA_RHCUR
		AND B00_12_TT_VENDOR_BALANCE.ACDOCA_MONAT = GROUPED.ACDOCA_MONAT


		ALTER TABLE B00_12_TT_VENDOR_BALANCE ALTER COLUMN ACDOCA_MONAT VARCHAR(25)
		UPDATE B00_12_TT_VENDOR_BALANCE
		SET ACDOCA_MONAT = '00-Begin period'
		WHERE ACDOCA_MONAT = '00'

		--Step 15: Get description for company, customer and currency factor
		EXEC SP_REMOVE_TABLES 'B00_13_RT_VENDOR_BALANCE'
		SELECT ACDOCA_RCLNT,
			   ACDOCA_RBUKRS,
			   T001_BUTXT,
			   ACDOCA_GJAHR,
			   ACDOCA_LIFNR,
			   LFA1_NAME1,
			   LFA1_LAND1,
               T005T_NATIO,
			   ACDOCA_MONAT,
			   CONCAT(ACDOCA_GJAHR,'-',LEFT(ACDOCA_MONAT,2)) ZF_ACDOCA_GJAHR_MONAT,
			   ACDOCA_UMSKZ,
			   ACDOCA_RHCUR,
			   CAST(ZF_OPENING_BALANCE AS money)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_OPENING_BALANCE,
			   CAST(ACDOCA_HSL_S AS money)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_ACDOCA_HSL_S,
			   CAST(ACDOCA_HSL_H AS money)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_ACDOCA_HSL_H,
			   CAST(ZF_CUMULATIVE_VALUE AS money)*ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_CUMULATIVE_VALUE
		INTO B00_13_RT_VENDOR_BALANCE
		FROM B00_12_TT_VENDOR_BALANCE
		LEFT JOIN A_T001
			ON ACDOCA_RBUKRS = T001_BUKRS
		LEFT JOIN B00_TCURX
			ON B00_TCURX.TCURX_CURRKEY = ACDOCA_RHCUR
		LEFT JOIN A_LFA1
			ON LFA1_LIFNR = ACDOCA_LIFNR
        LEFT JOIN A_T005T
            ON A_T005T.T005T_SPRAS IN ('E', 'EN') AND
               A_T005T.T005T_LAND1 = A_LFA1.LFA1_LAND1

		--Step 16: Get all customer documents of Special G/L ledger
		EXEC SP_REMOVE_TABLES 'B00_14_TT_VENDOR_BALANCE_SPGL'
		SELECT ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			IIF(ACDOCA_UMSKZ = '','zAccount balance', ACDOCA_UMSKZ) ACDOCA_UMSKZ,
			ACDOCA_RHCUR,
			SUM(ZF_OPENING_BALANCE) ZF_BALANCE_CARRIED_FORWARD,
			SUM(ACDOCA_HSL_S) ZF_ACDOCA_HSL_S,
			SUM(ACDOCA_HSL_H) ZF_ACDOCA_HSL_H
		INTO B00_14_TT_VENDOR_BALANCE_SPGL
		FROM B00_10_TT_VENDOR_BALANCE
		WHERE ACDOCA_GJAHR >= @FISCAL_YEAR_FROM AND ACDOCA_GJAHR <= @FISCAL_YEAR_TO
		GROUP BY ACDOCA_RCLNT,
			ACDOCA_RBUKRS,
			ACDOCA_GJAHR,
			ACDOCA_LIFNR,
			IIF(ACDOCA_UMSKZ = '','zAccount balance', ACDOCA_UMSKZ),
			ACDOCA_RHCUR
		HAVING SUM(ACDOCA_HSL_H) <> 0 OR SUM(ACDOCA_HSL_S) <> 0 OR SUM(ZF_OPENING_BALANCE) <> 0

		--Step 17: Create total rows for each customer in special g/l
		EXEC SP_REMOVE_TABLES 'B00_15_TT_VENDOR_BALANCE_SPGL'

		SELECT *
		INTO B00_15_TT_VENDOR_BALANCE_SPGL
		FROM B00_14_TT_VENDOR_BALANCE_SPGL

		UNION ALL

		SELECT ACDOCA_RCLNT,
			   ACDOCA_RBUKRS,
			   ACDOCA_GJAHR,
			   ACDOCA_LIFNR,
			   'zTotal',
			   ACDOCA_RHCUR,
			   SUM(ZF_BALANCE_CARRIED_FORWARD),
			   SUM(ZF_ACDOCA_HSL_S),
			   SUM(ZF_ACDOCA_HSL_H)

		FROM B00_14_TT_VENDOR_BALANCE_SPGL
		GROUP BY ACDOCA_RCLNT,
				 ACDOCA_RBUKRS,
				 ACDOCA_GJAHR,
				 ACDOCA_LIFNR,
				 ACDOCA_RHCUR

		--Step 10: Get description for company, customer, currency factor
		EXEC SP_REMOVE_TABLES 'B00_16_RT_VENDOR_BALANCE_SPGL'
		SELECT ACDOCA_RCLNT,
			   ACDOCA_RBUKRS,
			   T001_BUTXT,
			   ACDOCA_GJAHR,
			   ACDOCA_LIFNR,
			   LFA1_NAME1,
			   LFA1_LAND1,
               T005T_NATIO,
			   ACDOCA_UMSKZ,
			   T074T_LTEXT,
			   ACDOCA_RHCUR,
			   CAST(ZF_BALANCE_CARRIED_FORWARD AS money) * ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_BALANCE_CARRIED_FORWARD,
			   CAST(ZF_ACDOCA_HSL_S AS money) * ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_ACDOCA_HSL_S,
			   CAST(ZF_ACDOCA_HSL_H AS money) * ISNULL(B00_TCURX.TCURX_FACTOR,1) ZF_ACDOCA_HSL_H
		INTO B00_16_RT_VENDOR_BALANCE_SPGL
		FROM B00_15_TT_VENDOR_BALANCE_SPGL
		LEFT JOIN A_T001
			ON ACDOCA_RBUKRS = T001_BUKRS
		LEFT JOIN B00_TCURX
			ON B00_TCURX.TCURX_CURRKEY = ACDOCA_RHCUR
		LEFT JOIN A_LFA1
			ON LFA1_LIFNR = ACDOCA_LIFNR
        LEFT JOIN A_T005T
            ON A_T005T.T005T_SPRAS IN ('E', 'EN') AND
               A_T005T.T005T_LAND1 = A_LFA1.LFA1_LAND1
		LEFT JOIN A_T074T
		ON T074T_SHBKZ = ACDOCA_UMSKZ AND
		   T074T_KOART = 'K'
		ORDER BY ACDOCA_RCLNT, ACDOCA_RBUKRS,	ACDOCA_GJAHR, ACDOCA_LIFNR,ACDOCA_UMSKZ


	--Rename output table
	EXEC SP_RENAME_FIELD 'B00_CB_' , 'B00_06_RT_CUSTOMER_BALANCE'
	EXEC SP_RENAME_FIELD 'B00_CBSPGL_' , 'B00_09_RT_CUSTOMER_BALANCE_SPGL'
	EXEC SP_RENAME_FIELD 'B00_VB_' , 'B00_13_RT_VENDOR_BALANCE'
	EXEC SP_RENAME_FIELD 'B00_VBSPGL_' , 'B00_16_RT_VENDOR_BALANCE_SPGL'

	--Drop temporary table
	EXEC SP_REMOVE_TABLES '%_TT_%'

	EXEC SP_CREATE_INDEX B00_TB, 'B00_TB', 'ACDOCA_RCLNT, ACDOCA_RACCT, ACDOCA_RBUKRS'
		
	--Immediately following each cube select statement, copy the following to log the cube creation
	--Note: make sure to update the two references to cube name in this code
	INSERT INTO [_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Cube completed','B00_TB',(SELECT COUNT(*) FROM B00_TB)

	--Log end of procedure
	INSERT INTO [_DatabaseLogTable] ([Database],[Object],[Object Type],[User],[Date],[Time],[Description],[Table],[Rows])
	SELECT DB_NAME(),OBJECT_NAME(@@PROCID),'P',SYSTEM_USER,CONVERT(date,GETDATE()),CONVERT(time,GETDATE()),'Procedure finished',NULL,NULL

END
GO
