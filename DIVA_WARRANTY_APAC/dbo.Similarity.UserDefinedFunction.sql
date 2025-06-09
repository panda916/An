USE [DIVA_WARRANTY_APAC]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[Similarity](@input1 [nvarchar](4000), @input2 [nvarchar](4000), @method [tinyint], @containmentBias [float], @minScoreHint [float])
RETURNS [float] WITH EXECUTE AS CALLER, RETURNS NULL ON NULL INPUT
AS 
EXTERNAL NAME [Microsoft.MasterDataServices.DataQuality].[Microsoft.MasterDataServices.DataQuality.SqlClr].[Similarity]
GO
