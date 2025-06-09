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
CREATE FUNCTION [dbo].[TEST_SAP_NEW_REPORT_FORMAT]
(
	-- Add the parameters for the function here
	@AMOUNT Varchar(1000))
RETURNS money
AS
BEGIN
	Declare @return_amount float
	-- Declare the return variable here
	set @return_amount = 
	
	
(SELECT 
	CASE 
		WHEN 

			(RIGHT(dbo.trim(@AMOUNT),1) = '-' and LEFT(RIGHT(DBO.TRIM(@AMOUNT),3),1) = '.') OR  
			(RIGHT(dbo.trim(@AMOUNT),1) = '-' and LEFT(RIGHT(DBO.TRIM(@AMOUNT),4),1) = '.') OR 
			LEFT(RIGHT(DBO.TRIM(@AMOUNT),2),1) = '.' OR
			LEFT(RIGHT(DBO.TRIM(@AMOUNT),3),1) = '.'

			THEN CAST( REPLACE(dbo.trim(@amount),',','') AS FLOAT)
	 
		WHEN
			(RIGHT(dbo.trim(@AMOUNT),1) = '-' AND  LEFT(RIGHT(DBO.TRIM(@AMOUNT),3),1) = '.') OR 
			(RIGHT(dbo.trim(@AMOUNT),1) = '-' AND  LEFT(RIGHT(DBO.TRIM(@AMOUNT),3),1) = '.') OR 
			(LEFT(dbo.trim(@AMOUNT) , 1) = '-' AND LEFT(RIGHT(DBO.TRIM(@AMOUNT),3),1) = '.') OR 
			(LEFT(dbo.trim(@AMOUNT) , 1) = '-' AND LEFT(RIGHT(DBO.TRIM(@AMOUNT),2),1) = '.')  

			THEN -1*Cast(REPLACE(REPLACE(REPLACE(dbo.trim(@AMOUNT),'-',''),'.',''),',','.') as float) 
			ELSE Cast(REPLACE(REPLACE(REPLACE(dbo.trim(@AMOUNT),'-',''),'.',''),',','.') as float)
	END 
)



	-- Return the result of the function
	RETURN @return_amount

END

GO
