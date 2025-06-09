USE [DIVA_WARRANTY_APAC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[getStringPattern](@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)

AS
BEGIN
DECLARE @char NVARCHAR(1), @output NVARCHAR(MAX) = '', @pattern NVARCHAR(1)

DECLARE @i int = 1

WHILE @i <= len(@input)
BEGIN
    SET @char = SUBSTRING(@input, @i,1)
	IF (SELECT IIF(@char LIKE '[A-Za-z]', 1, 0)) = 1 SET @pattern = 'A'
	ELSE IF (SELECT IIF(@char LIKE '[0-9]', 1, 0)) = 1 SET @pattern = 'D'
	ELSE SET @pattern = ''
    SET @output = @output + @pattern
	SET @i = @i + 1
END
RETURN @output
END
GO
