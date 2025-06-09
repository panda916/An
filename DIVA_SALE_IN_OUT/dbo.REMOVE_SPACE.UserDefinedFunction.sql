USE [DIVA_SALE_IN_OUT]
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

CREATE FUNCTION [dbo].[REMOVE_SPACE](@Temp VarChar(1000)) Returns VarChar(1000) AS Begin      
While PatIndex('% %', @Temp) > 0        
 Set @Temp = Stuff(@Temp, PatIndex('% %', @Temp), 1, '')      
 Return upper(@TEmp)
 End




GO
