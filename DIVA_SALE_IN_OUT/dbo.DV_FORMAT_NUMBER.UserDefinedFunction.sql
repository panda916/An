USE [DIVA_SALE_IN_OUT]
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
/* This is standard SQL behaviour:

    A CASE expression evaluates to the first true condition.

    If there is no true condition, it evaluates to the ELSE part.

    If there is no true condition and no ELSE part, it evaluates to NULL
*/

CREATE  FUNCTION [dbo].[DV_FORMAT_NUMBER]
(	-- Add the parameters for the function here
@REPORT_NAME NVARCHAR(100),
@FIELD_USED_IN_REPORT NVARCHAR(100),
@INPUT_VALUE VARCHAR(100))



RETURNS money
AS
BEGIN
	DECLARE @return_amount FLOAT

	DECLARE @NUMBER_FORMAT NVARCHAR(MAX)	= (SELECT [FIELD_FORMAT] FROM [AM_DV_FIELD_MAPPING] WHERE  [FIELD_FROM_SAP_REPORT]= @FIELD_USED_IN_REPORT AND REPORT = @REPORT_NAME) 
	-- THIS WILL RETURN EITHER COMMA OR DOT

	SET @INPUT_VALUE = DBO.TRIM(@INPUT_VALUE)

	-- Declare the return variable here
	SET @return_amount = 
	--113.100.200,12
	---113,100,200.12
	
(SELECT 
		CASE WHEN @NUMBER_FORMAT = ',' THEN 
				
				IIF(CHARINDEX('-',@INPUT_VALUE,1)>0, -1*CAST(REPLACE(REPLACE(REPLACE(@INPUT_VALUE,'-',''),'.',''),',','.') AS FLOAT),CAST(REPLACE(REPLACE(REPLACE(@INPUT_VALUE,'-',''),'.',''),',','.') AS FLOAT))
			
	     WHEN @NUMBER_FORMAT = '.' THEN 

				IIF(CHARINDEX('-',@INPUT_VALUE,1)>0, -1*CAST(REPLACE(REPLACE(@INPUT_VALUE,'-',''),',','') AS FLOAT),CAST(REPLACE(REPLACE(@INPUT_VALUE,'-',''),',','') AS FLOAT))
			ELSE 
				IIF(CHARINDEX('-',@INPUT_VALUE,1)>0, -1*CAST(REPLACE(REPLACE(REPLACE(@INPUT_VALUE,'-',''),',',''),'.','') AS FLOAT),CAST(REPLACE(REPLACE(REPLACE(@INPUT_VALUE,'-',''),',',''),'.','') AS FLOAT))
		 END 
)

	-- Return the result of the function
	RETURN @return_amount

END

GO
