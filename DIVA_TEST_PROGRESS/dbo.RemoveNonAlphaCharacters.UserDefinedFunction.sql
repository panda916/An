USE [DIVA_TEST_PROGRESS]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[RemoveNonAlphaCharacters](@Temp VarChar(1000))
Returns VarChar(1000)
AS
Begin

    While PatIndex('%[^a-zA-Z0-9 _()=-]%', @Temp) > 0
        Set @Temp = Stuff(@Temp, PatIndex('%[^a-zA-Z0-9 _()=-]%', @Temp), 1, '')

    Return @Temp
End


GO
