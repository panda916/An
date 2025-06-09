USE [DIVA_GB00_FY23_24]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_REMOVE_TEMPORARY_TABLE]
as

BEGIN 
--- this is to remove all the temporary table generated in each steps while generating cubes (cleaning up database)
exec SP_REMOVE_TABLES 'B%[_]__[_]TT%'

END





GO
