USE [DIVA_GPW_SOX]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GET_TABLESIZE]
  (@table varchar(255))
  RETURNS varchar(255)
  WITH EXEC AS CALLER
  AS
  BEGIN

  DECLARE @result varchar(255);
 
	-- Quickly get row counts.
	SELECT distinct @result = p.rows
	FROM sys.partitions p
	WHERE OBJECT_NAME(p.object_id) = @table

  RETURN @result
  END
GO
