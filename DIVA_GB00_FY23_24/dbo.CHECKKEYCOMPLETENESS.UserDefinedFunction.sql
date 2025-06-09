USE [DIVA_GB00_FY23_24]
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
CREATE FUNCTION [dbo].[CHECKKEYCOMPLETENESS] 
(
	-- Add the parameters for the function here
	@tbl nvarchar(MAX)
)
RETURNS nvarchar(MAX)
AS
BEGIN
	
	
	
	
--DECLARE @tbl nvarchar(MAX) = 'CABNT'

DECLARE @MissingFields nvarchar(MAX) = ''

--check if table contains full primary key
DECLARE @tbl3 as varchar(max)

DECLARE c1 CURSOR FOR

 select  ltrim(rtrim(FIELDNAME)) from [zzSAP_DDIC].dbo.RUSSIA_DD03L_ECC_KAAP_WORK
LEFT JOIN sys.columns ON
 OBJECT_NAME(object_id) = @tbl AND
	FIELDNAME COLLATE DATABASE_DEFAULT = name COLLATE DATABASE_DEFAULT
where TABNAME = @tbl and KEYFLAG = 'X' AND name IS  NULL
ORDER BY position ASC
  OPEN c1
 
  FETCH NEXT FROM c1 INTO @tbl3
  WHILE @@FETCH_STATUS = 0

	 BEGIN
		 SET @MissingFields  = @Missingfields + @tbl3 + ', ' 
		-- print @tbl3
			 FETCH NEXT FROM c1
		  INTO @tbl3
		  
	END
CLOSE c1
DEALLOCATE c1
IF @MissingFields = '' 
	Return 'Complete: Key for '+@tbl+' is complete'	
	
return  'Incomplete: The key field(s) '+ LEFT(@MissingFields,LEN(@MissingFields)-1)+' are missing from '+@tbl
 
END





GO
