USE [DIVA_GB00_FY23_24]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[ALPHA_NUMERIC_COMPARE](@string VARCHAR(MAX))
RETURNS BINARY(2)
BEGIN
RETURN CAST(@string AS BINARY(2))
END


GO
