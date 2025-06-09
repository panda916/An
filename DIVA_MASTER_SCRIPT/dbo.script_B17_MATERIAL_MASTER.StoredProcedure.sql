USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Khoi
-- Create date: <Create Date,,>
-- Description:	Create Material master cube
-- =============================================
CREATE     PROCEDURE [dbo].[script_B17_MATERIAL_MASTER]
AS
BEGIN

--Step 1 Create the Material master cube
--Get fields from MARA and MARC
--Add Name of the user and text description to the cube

EXEC SP_DROPTABLE B17_01_IT_MATERIAL_MASTER

EXEC SP_DROPTABLE 'B17_01_IT_MATERIAL_MASTER'
SELECT DISTINCT  
		A_MARA.*,
		A_MARC.*,
		A_T134T.T134T_MTBEZ ,--Material type description
		A_T023T.T023T_WGBEZ60 ,--Material group description
		V_USERNAME_NAME_TEXT,-- Name of the user
		MAKT_MAKTX,--Material description
		T001W_NAME1,--Plant name
		T024_EKNAM --purchasing group descriptionv
INTO B17_01_IT_MATERIAL_MASTER
FROM A_MARA 
--Add material type text description
LEFT JOIN A_T134T 
	ON T134T_MTART=MARA_MATNR 
--Add Material Group text description
LEFT JOIN A_T023T 
	ON T023T_MATKL=MARA_MATKL
--Add name of the user
LEFT JOIN A_V_USERNAME 
	ON MARA_ERNAM=V_USERNAME_BNAME
--Add material description
LEFT JOIN A_MAKT 
	ON MARA_MATNR=MAKT_MATNR 
--Add plant data for material
LEFT JOIN A_MARC 
      ON MARA_MATNR = MARC_MATNR
--Add the names of the Plants
LEFT JOIN A_T001W 
      ON MARC_WERKS = T001W_WERKS 
--Add the purchasing group description
LEFT JOIN A_T024 
	  ON T024_EKGRP= MARC_EKGRP

--Step 2 Rename the fields
EXEC SP_RENAME_FIELD 'B17_01_' ,B17_01_IT_MATERIAL_MASTER

END

GO
