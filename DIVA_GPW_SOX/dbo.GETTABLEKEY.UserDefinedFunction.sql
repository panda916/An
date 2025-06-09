USE [DIVA_GPW_SOX]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GETTABLEKEY] 
(
	-- Add the parameters for the function here
	@tbl nvarchar(MAX)
)
RETURNS nvarchar(MAX)
AS
BEGIN
	
--DECLARE @tbl nvarchar(MAX) = 'BSEG'

DECLARE @TableKey nvarchar(MAX) = ''

--check if table contains full primary key
DECLARE @tbl3 as varchar(max)


DECLARE c1 CURSOR FOR

SELECT LTRIM(RTRIM(FIELDNAME)) from A_DD03L A
where TABNAME = @tbl and KEYFLAG = 'X'
ORDER BY POSITION
OPEN c1
 
  FETCH NEXT FROM c1 INTO @tbl3
  WHILE @@FETCH_STATUS = 0

	 BEGIN
		 --SET @TableKey  = @TableKey + '[' + RIGHT(@tbl, LEN(@tbl)-2) + '_' + @tbl3 + '], '
		 SET @TableKey  = @TableKey + '[' + @tbl + '_' + @tbl3 + '], '
		-- print @tbl3
		 FETCH NEXT FROM c1 INTO @tbl3  
	END
CLOSE c1
DEALLOCATE c1

return  LEFT(@TableKey, LEN(@TableKey)-1)



END








GO
