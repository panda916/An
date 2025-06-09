USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CLEAN_DATA]
(@value varchar(255))
RETURNS varchar(255)
WITH EXEC AS CALLER
AS
BEGIN
DECLARE @result varchar(255)

While PatIndex('%[^a-zA-Z0-9]%', @value) > 0        
 Set @value = Stuff(@value, PatIndex('%[^a-zA-Z0-9]%', @value), 1, '')      
 	
  SELECT @result = lower(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@value,'.',''),',',''),'-',''),'#',''),'''',''),'"',''),'(',''),')',''),'&',''),'AB',''),' AS',''),'ABEE',''),'AE',''),'APS',''),'BV',''),'BVBA',''),'BVio',''),'Company',''),'Corp',''),' Co ',''),'EE',''),'JLLC',''),'KG',''),'LLC',''),'LLP',''),'Ltd',''),'limited',''),'MEPE',''),'NV',''),'OBEE',''),'OE',''),'responsabilidadelimitada',''),'Sapa',''),'SARL',''),'SdeRL',''),'SpA',''),'Srl',''),'SRO',''),'UAB',''),'VOF',''),' ','')) --FROM [_CUBE_PTP-01-SMD]
  RETURN @result
END




GO
