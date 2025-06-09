USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vinh Le
-- Create date: 17-12-2020
-- Description:	Check and Create the AM_EXCHNG tables if it do not exist. The script also update new currency unit have been use to BKPF, EKPO, VBAK, . . . if they are not in the AM_CHNG
-- 22-06-2022	Khoa	Replace A_ACDOCA to B00_ACDOCA
-- =============================================
CREATE   PROCEDURE [dbo].[script_B00_SS02_GENERATE_AM_EXCHNG_TABLES]
AS
--DYNAMIC_SCRIPT_START
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*
		Step 1: Create the AM_EXCHNG table if the AM_EXCHNG table do not exist.
	*/
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'AM_EXCHNG')
		BEGIN
			CREATE TABLE [dbo].[AM_EXCHNG](
				[EXCHNG_FROM] VARCHAR(3) NOT NULL,
				[EXCHNG_TO] NVARCHAR(3) NOT NULL,
				[EXCHNG_RATIO] FLOAT NULL,
				[EXCHNG_SOURCE] NVARCHAR(MAX) NULL
				CONSTRAINT PK_AM_EXCHANGE PRIMARY KEY ([EXCHNG_FROM], [EXCHNG_TO])
			)
		END

		/*
			Step 2: List all currency units have been use in transaction table like BKPF/BSEG, VBAK/VBAP and EKKO/EKPO and have not been AM_EXCHNG table yet to a temparary table before we import them to AM_EXCHNG.
		*/
		EXEC SP_REMOVE_TABLES 'B00_01_TT_ALL_CURRENCY_UNITS'
		SELECT ACDOCA_RWCUR AS CURRENCY_UNIT
		INTO B00_01_TT_ALL_CURRENCY_UNITS
		FROM B00_ACDOCA
		WHERE NOT EXISTS (SELECT TOP 1 1 FROM AM_EXCHNG WHERE ACDOCA_RWCUR = EXCHNG_FROM)
		UNION
		SELECT EKKO_WAERS
		FROM A_EKKO
		WHERE NOT EXISTS (SELECT TOP 1 1 FROM AM_EXCHNG WHERE EKKO_WAERS = EXCHNG_FROM)
		UNION
		SELECT VBAK_WAERK
		FROM A_VBAK
		WHERE NOT EXISTS (SELECT TOP 1 1 FROM AM_EXCHNG WHERE VBAK_WAERK = EXCHNG_FROM)


		/*
			Step 3: Insert new currency unit to AM_EXCHNG tables
		*/
		INSERT INTO AM_EXCHNG
		SELECT CURRENCY_UNIT, 'USD', NULL, NULL
		FROM B00_01_TT_ALL_CURRENCY_UNITS
		WHERE CURRENCY_UNIT <> ''


END
GO
