USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   FUNCTION [dbo].[REMOVE_LEADING_ZEROES_FOR_AP](@Input VarChar(1000))
Returns VarChar(1000)
AS
Begin
	Declare @Result VarChar(1000)
	If ISNUMERIC(@Input) = 1
		Set @Result = SUBSTRING(@Input, PATINDEX('%[^0]%', @Input+'.'), LEN(@Input))
	Else 
		Set @Result = @Input
	Return @Result
End

GO
