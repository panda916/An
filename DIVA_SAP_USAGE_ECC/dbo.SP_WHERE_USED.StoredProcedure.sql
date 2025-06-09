USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[SP_WHERE_USED] (@SearchText varchar(1000))

AS
BEGIN
 SELECT DISTINCT @SearchText, SPName
 FROM (
  (SELECT ROUTINE_NAME SPName
   FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE ROUTINE_DEFINITION LIKE '%' + @SearchText + '%' 
   AND (ROUTINE_TYPE='PROCEDURE' OR ROUTINE_TYPE ='FUNCTION'))
  UNION ALL
  (SELECT OBJECT_NAME(id) SPName
   FROM SYSCOMMENTS 
   WHERE [text] LIKE '%' + @SearchText + '%' 
   AND (OBJECTPROPERTY(id, 'IsProcedure') = 1 OR OBJECTPROPERTY(id, 'IsScalarFunction') = 1 OR OBJECTPROPERTY(id, 'IsTableFunction') = 1  OR OBJECTPROPERTY(id, 'IsView') = 1)
   GROUP BY OBJECT_NAME(id))
  UNION ALL
  (SELECT OBJECT_NAME(object_id) SPName
   FROM sys.sql_modules
   WHERE (OBJECTPROPERTY(object_id, 'IsProcedure') = 1  OR OBJECTPROPERTY(object_id, 'IsScalarFunction') = 1  OR OBJECTPROPERTY(object_id, 'IsTableFunction') = 1   OR OBJECTPROPERTY(object_id, 'IsView') = 1 )
   AND definition LIKE '%' + @SearchText + '%')
 ) AS T
 ORDER BY T.SPName
END


GO
