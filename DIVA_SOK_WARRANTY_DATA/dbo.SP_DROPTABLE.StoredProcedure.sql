USE [DIVA_SOK_WARRANTY_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[SP_DROPTABLE]
  @value varchar(255)
  WITH EXECUTE AS CALLER
  AS
  BEGIN 

    DECLARE @dstr as varchar(max)
    
    /* Check if the table already exists in the database.
    Delete it when this is the case */
    IF EXISTS(SELECT 1 FROM sysobjects WHERE xtype = 'u' AND name='' + @value + '')
      BEGIN
        SET @dstr = 'DROP TABLE [' + @value + ']'
        EXEC (@dstr)
      END
	ELSE IF object_id('tempdb..' + @value) is not null
	      BEGIN
        SET @dstr = 'DROP TABLE [' + @value + ']'
        EXEC (@dstr)
      END
  END




GO
