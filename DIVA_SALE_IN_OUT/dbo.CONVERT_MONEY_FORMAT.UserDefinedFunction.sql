USE [DIVA_SALE_IN_OUT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[CONVERT_MONEY_FORMAT]
(
	-- Add the parameters for the function here
	@AMOUNT Varchar(1000))
RETURNS money
AS
BEGIN
	Declare @return_amount float
	-- Declare the return variable here
	set @return_amount =  (select case when @amount <> '' then(cast(left((convert(varchar,dbo.trim(IIF(@AMOUNT = '-','0',REPLACE(@AMOUNT,'.',''))) )), 
						len((convert(varchar,dbo.trim(IIF(@AMOUNT = '-','0',REPLACE(@AMOUNT,'.',''))) )))-2) 
  +'.'+ right(convert(varchar,dbo.trim(IIF(@AMOUNT = '-','0',REPLACE(@AMOUNT,'.',''))) ),2) as money))
						else  0 end )
  

	-- Return the result of the function
	RETURN @return_amount

END

GO
