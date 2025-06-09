USE [DIVA_SOTHAI_WARRANTY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Nhat,Pham>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
/*
This will take parameters from AM TABLES to determine the date format and convert the date to predefined format
ISO 112	 yyyymmdd
*/
CREATE FUNCTION [dbo].[DV_FORMAT_DATE]

(@REPORT_NAME NVARCHAR(100),
@FIELD_USED_IN_REPORT NVARCHAR(100),
@INPUT_VALUE nvarchar(100))

RETURNS DATE

AS
BEGIN
DECLARE @CONVERTED_DATE DATE

/* 
dd.mm.yyyy
mm.dd.yyyy
yyyy.mm.dd
yyyy.dd.mm
dd/mm/yyyy
mm/dd/yyyy
yyyy/mm/dd
yyyy/dd/mm
dd-mm-yyyy
mm-dd-yyyy
yyyy-mm-dd
yyyy-dd-mm
ddmmyyyy
mmddyyyy
yyyymmdd
yyyyddmm

*/

DECLARE @date_format NVARCHAR(MAX)	= (SELECT FIELD_FORMAT FROM AM_DV_FIELD_MAPPING WHERE FIELD_FROM_SAP_REPORT= @FIELD_USED_IN_REPORT AND REPORT = @REPORT_NAME) 

--All the seperators will be removed here
SET @date_format = REPLACE(REPLACE(REPLACE(REPLACE((@date_format),'.',''),'-',''),'/',''),' ','')
SET @INPUT_VALUE = REPLACE(REPLACE(REPLACE(REPLACE((@INPUT_VALUE),'.',''),'-',''),'/',''),' ','')

DECLARE @return_year varchar(10)

DECLARE @return_month varchar(10)

DECLARE @return_day varchar(10)


SET @return_year=  (

		SELECT 
			CASE 
				WHEN
				@date_format = 'ddmmyyyy' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),5,4)

				WHEN 
				@date_format = 'mmddyyyy' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),5,4)
				WHEN 
				@date_format = 'yyyymmdd' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),1,4) END)


SET @return_month=  (

		SELECT 
			CASE
				WHEN
				@date_format = 'ddmmyyyy' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),3,2)

				WHEN 
				@date_format = 'mmddyyyy' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),1,2)
				WHEN 
				@date_format = 'yyyymmdd' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),5,2) END)


SET @return_day=  (

		SELECT 
			CASE
				WHEN
				@date_format = 'ddmmyyyy' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),1,2)

				WHEN 
				@date_format = 'mmddyyyy' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),3,2)
				WHEN 
				@date_format = 'yyyymmdd' THEN 
							SUBSTRING(dbo.TRIM(@INPUT_VALUE),7,2) END)



SET @CONVERTED_DATE = CONVERT(DATE,(@return_year+@return_month+@return_day))



RETURN @CONVERTED_DATE

END 
GO
