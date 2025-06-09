USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vinh Le
-- Create date: 18-12-2020
-- Description:	Validate the AM tables and raise the error before run the main scipts
-- =============================================
CREATE           PROCEDURE [dbo].[SP_AM_TABLES_VALIDATION] 
AS
--DYNAMIC_SCRIPT_START
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
	/*
		Step 1: Check and raise an error if any currency unit that has not been updated exchange rate yet exists
	*/
	--IF EXISTS(SELECT * FROM AM_EXCHNG WHERE EXCHNG_RATIO IS NULL OR LEN(EXCHNG_RATIO) = 0)
	--BEGIN
	--	RAISERROR('***SOME CURRENCY UNITS HAVE NOT BEEN UPDATED EXCHANGE RATE IN THE AM_EXCHNG***',	20,	1) WITH LOG
	--END

	/*
		Step 2: Check and raise an error if any g/l account appears more than one time in the AM_TANGO table.
	*/
	IF EXISTS (SELECT * FROM AM_TANGO GROUP BY TANGO_GL_ACCT HAVING COUNT(*) > 1)
	BEGIN
		RAISERROR('***G/L ACCOUNTS ARE NOT DISTINCT IN THE AM_TANGO***',	20,	1) WITH LOG
	END

	/*
		Step 3: Check and raise an error if any tango account that has more than one account text.
	*/
	--IF EXISTS (SELECT * FROM AM_TANGO GROUP BY TANGO_ACCT HAVING COUNT (DISTINCT TANGO_ACCT_TXT) > 1)
	--		RAISERROR('Some Tango accounts have more than one Tango account text in the AM_TANGO',	20,	1) WITH LOG

	/*
		Step 4: Check and raise an error if any g/l account has more than one GL1, GL2, GL3 or GL4 in the AM_GL_HIERACHY
	*/
	IF EXISTS (SELECT * FROM AM_GL_HIERARCHY GROUP BY GL_ACCT HAVING COUNT (*) > 1)
	BEGIN
		RAISERROR('***G/L ACCOUNTS ARE NOT DISTINCT IN AM_GL_HIERARCHY***',	20,	1) WITH LOG
	END

	/*
		Step 5: Check and raise an error if any g/l account has more than one spend category in the AM_SPEND_CATEOGY
	*/
	IF EXISTS (SELECT * FROM AM_SPEND_CATEGORY GROUP BY SPCAT_GL_ACCNT HAVING COUNT (*) > 1)
	BEGIN
		RAISERROR('***G/L ACCOUNTS ARE NOT DISTINCT IN AM_SPEND_CATEGORY***',	20,	1) WITH LOG
	END

	/*
		Step 6: Check and raise an error if we get any duplication in AM_COUNTRY_MAPPING
	*/
	IF EXISTS (SELECT * FROM AM_COUNTRY_MAPPING GROUP BY COUNTRY_MAPPING_CODE HAVING COUNT (*) > 1)
	BEGIN
		RAISERROR('***SOME ISO 2-CHARACTER COUNTRY CODES HAVE MORE THAN ONE 3-CHARACTER IN THE AM_COUNTRY_MAPPING***',	20,	1) WITH LOG
	END

	/*
		Step 7: Check and raise an error if we get new value in AM_SCOPE table which have not been updated Business domail L1, System, etc
	*/
	IF EXISTS (SELECT * FROM AM_SCOPE WHERE SCOPE_BUSINESS_DMN_L1 IS NULL OR LEN(SCOPE_BUSINESS_DMN_L1) = 0)
	BEGIN
		RAISERROR('***SOME COMPANYS HAVE NOT BEEN UPDATED IN AM_SCOPE***',	20,	1) WITH LOG
	END

	/*
		Step 8: Check and raise an error if we get new value in AM_GL_HIERARCHY table which have not been updated hierachy
	*/
	IF EXISTS (SELECT * FROM AM_GL_HIERARCHY WHERE GL_L1 IS NULL OR LEN(GL_L1) = 0)
	BEGIN
		RAISERROR('***SOME G/L ACCOUNTS HAVE NOT BEEN UPDATED IN AM_GL_HIERARCHY***',	20,	1) WITH LOG
	END

	-- Thuan update 2024/01/11 . We need to check if GL_L1 to GL_L4 is null then. If we have need to send it to Jesper

	IF EXISTS (SELECT * FROM AM_GL_HIERARCHY WHERE GL_L1 IS NULL OR GL_L2 IS NULL OR GL_L3 IS NULL OR GL_L4 IS NULL)
	BEGIN
		RAISERROR('***Need to check GL1 to GL4 again in AM_GL_HIERARCHY ***',	20,	1) WITH LOG
	END



	/*
		Step 10: Check and raise an error if we get new value in AM_TANGO table which have not been updated hierachy
	*/
	IF EXISTS (SELECT * FROM AM_TANGO WHERE TANGO_ACCT IS NULL OR LEN(TANGO_ACCT) = 0)
	BEGIN
		RAISERROR('***SOME G/L ACCOUNTS HAVE NOT BEEN UPDATED IN AM_TANGO***',	20,	1) WITH LOG
	END

	/*
		Step 11: Check and raise an error if we get new value in AM_SPEND_CATEGORY table which have not been updated hierachy
	*/

	-- Thuan update 2024/01/11 . We need to check if SPCAT_SPEND_CAT_LEVEL_1 to SPCAT_SPEND_CAT_LEVEL_4 is null then. If we have need to send it to Jesper

	IF EXISTS (SELECT * FROM AM_SPEND_CATEGORY WHERE SPCAT_SPEND_CAT_LEVEL_1 IS NULL OR SPCAT_SPEND_CAT_LEVEL_2 IS NULL OR SPCAT_SPEND_CAT_LEVEL_3 IS NULL OR SPCAT_SPEND_CAT_LEVEL_4 IS NULL)
	BEGIN
		RAISERROR('***Need to check SPCAT_SPEND_CAT_LEVEL_1 to SPCAT_SPEND_CAT_LEVEL_4 again in AM_SPEND_CATEGORY ***',	20,	1) WITH LOG
	END




	/*
		Step 12: Check and raise an error if any gl account in AM_IRGR_GINI_ARDR_MAPPING have appear more than one time.
	*/
	IF EXISTS (SELECT * FROM AM_IRGR_GINI_ARDR_MAPPING GROUP BY IRGR_GL_ACCT HAVING COUNT (DISTINCT IRGR_GL_ACCT) > 1)
	BEGIN
		RAISERROR('***G/L ACCOUNTS ARE NOT DISTINCT IN THE AM_IRGR_GINI_ARDR_MAPPING***',	20,	1) WITH LOG
	END

	/*
		Step 13: Check and raise an error if any gl account in AM_IRGR_GINI_ARDR_MAPPING have appear more than one time.
	*/
	IF EXISTS (SELECT * FROM AM_IRGR_MATERIAL_GROUP_HIERARCHY GROUP BY T023T_MATKL HAVING COUNT (DISTINCT T023T_MATKL) > 1)
	BEGIN
		RAISERROR('***MATERIAL GROUPS ARE NOT DISTINCT IN THE AM_IRGR_MATERIAL_GROUP_HIERARCHY***',	20,	1) WITH LOG
	END

	/*
		Step 14: Check and raise an error if we get new value in AM_SPEND_CATEGORY table which have not been updated hierachy
	*/
	IF EXISTS (SELECT * FROM AM_IRGR_MATERIAL_GROUP_HIERARCHY WHERE IRGR_SPEND_CAT_LEVEL_1 IS NULL OR IRGR_SPEND_CAT_LEVEL_2 IS NULL OR IRGR_SPEND_CAT_LEVEL_3 IS NULL OR IRGR_SPEND_CAT_LEVEL_4 IS NULL)
	BEGIN
		RAISERROR('***SOME MATERIAL GROUPS HAVE NOT BEEN UPDATED IN AM_IRGR_MATERIAL_GROUP_HIERARCHY***',	20,	1) WITH LOG
	END
END

GO
