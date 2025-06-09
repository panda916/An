USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
  --------------------------------------------------------------
  Update history
  --------------------------------------------------------------
  Date		|	Who	|	Description
  01-08-2011	AJB		Initial version 
  06-09-2011	AJB		Added upper/lowercase insensitivity
  */

CREATE FUNCTION [dbo].[RemoveNonAlphaNumericCharacters](@Temp VarChar(1000)) Returns VarChar(1000) AS Begin      
While PatIndex('%[^a-zA-Z0-9]%', @Temp) > 0        
 Set @Temp = Stuff(@Temp, PatIndex('%[^a-zA-Z0-9]%', @Temp), 1, '')      
 Return upper(@TEmp)
 End

GO
