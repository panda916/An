USE [DIVA_GB00_FY23_24]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[SPLIT_STRING_POSITION_NTH_VALUE](@Temp VarChar(1000),@DELIMINATOR VARCHAR(10), @POSITION INT)
Returns VarChar(1000)
AS
Begin
	Declare @return_value varchar(1000)

	set @return_value =  (select items from Split(@Temp,@DELIMINATOR) where id = @POSITION)
	Return	@return_value 
End



--declare @test varchar(100)
--set @test = 'S740905-EXCHANGE RATE LOSS - UNREALISED'

--select items from Split(@test,'-') where id = 1



GO
