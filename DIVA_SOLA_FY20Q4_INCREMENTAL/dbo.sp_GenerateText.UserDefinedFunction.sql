USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[sp_GenerateText](@Length int)
RETURNS varchar(32)
AS
BEGIN

DECLARE @RandomID varchar(32)
DECLARE @counter smallint
DECLARE @RandomNumber float
DECLARE @RandomNumberInt tinyint
DECLARE @CurrentCharacter varchar(1)
DECLARE @ValidCharacters varchar(255)
SET @ValidCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
DECLARE @ValidCharactersLength int
SET @ValidCharactersLength = len(@ValidCharacters)
SET @CurrentCharacter = ''
SET @RandomNumber = 0
SET @RandomNumberInt = 0
SET @RandomID = ''

SET @counter = 1
WHILE @counter < (@Length + 1)
BEGIN 
SET @RandomNumber = (SELECT RandNumber FROM vRandNumber) SET @RandomNumberInt = Convert(tinyint, ((@ValidCharactersLength - 1) * @RandomNumber + 1)) 
SELECT @CurrentCharacter = SUBSTRING(@ValidCharacters, @RandomNumberInt, 1) 
SET @counter = @counter + 1 SET @RandomID = @RandomID + @CurrentCharacter
END 

RETURN @RandomID 
END




GO
