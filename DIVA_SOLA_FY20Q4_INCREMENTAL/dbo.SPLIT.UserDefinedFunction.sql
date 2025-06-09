USE [DIVA_SOLA_FY20Q4_INCREMENTAL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SPLIT] (
    @string nvarchar(max),
    @delim nvarchar(max)
  )
  RETURNS @tbl table (
    Id int identity(1,1),
    items nvarchar(max),
    length int
  ) 
  AS  
  BEGIN 

  /*
  Title:        Split
  Description:  Function to split a string into items based on delimiter provided by user

  Features:
  - no limits to number of characters in string
  - leading and trailing spaces are removed from every slice
  - supports delimiters of any length; single-character as well as multi-character
  - supports unicode
  - returns a table with a row for each item

  --------------------------------------------------------------
  Update history
  --------------------------------------------------------------
  Date      | Who | Description
  30-04-2011  dvdw  Initial version
  01-05-2011  dvdw  update output table with original length of slice  
  */

  DECLARE @c int
  DECLARE @item nvarchar(max)
  SET @c = Charindex(@delim,@string)

    WHILE @c > 0
    BEGIN
    
    SET @item = ltrim(rtrim(Substring(@string,1,@c-1)))
    
      --IF(len(@item)>0)
        INSERT INTO @tbl (items, length) VALUES(@item,@c-1)

      SET @string = Substring(@string,@c+len(@delim),len(@string))
      
      -- move cursor to next occurrence of delimiter
      SET @c = Charindex(@delim,@string)
      
    END
    
    -- last slice
    INSERT INTO @tbl (items,length) values(ltrim(rtrim(@string)),len(@string)-1)

    RETURN
  END

GO
