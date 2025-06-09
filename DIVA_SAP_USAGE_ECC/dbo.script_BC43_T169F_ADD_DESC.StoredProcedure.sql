USE [DIVA_SAP_USAGE_ECC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_BC43_T169F_ADD_DESC]
AS
--DYNAMIC_SCRIPT_START
EXEC SP_DROPTABLE BC43_01_IT_T691F

SELECT A_T691F.*,
CASE 
	WHEN T691F_STREA='' THEN 'No message'
	WHEN T691F_STREA='A' THEN 'Warning'
	WHEN T691F_STREA='B' THEN 'Error message'
	WHEN T691F_STREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_STREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_STREA_DESC,
CASE 
	WHEN T691F_WSREA='' THEN 'No message'
	WHEN T691F_WSREA='A' THEN 'Warning'
	WHEN T691F_WSREA='B' THEN 'Error message'
	WHEN T691F_WSREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_WSREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_WSREA_DESC, 
CASE 
	WHEN T691F_MAREA='' THEN 'No message'
	WHEN T691F_MAREA='A' THEN 'Warning'
	WHEN T691F_MAREA='B' THEN 'Error message'
	WHEN T691F_MAREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_MAREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_MAREA_DESC,
CASE 
	WHEN T691F_FSREA='' THEN 'No message'
	WHEN T691F_FSREA='A' THEN 'Warning'
	WHEN T691F_FSREA='B' THEN 'Error message'
	WHEN T691F_FSREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_FSREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_FSREA_DESC ,
CASE 
	WHEN T691F_RSREA='' THEN 'No message'
	WHEN T691F_RSREA='A' THEN 'Warning'
	WHEN T691F_RSREA='B' THEN 'Error message'
	WHEN T691F_RSREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_RSREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_RSREA_DESC,
CASE 
	WHEN T691F_PDREA='' THEN 'No message'
	WHEN T691F_PDREA='A' THEN 'Warning'
	WHEN T691F_PDREA='B' THEN 'Error message'
	WHEN T691F_PDREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_PDREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_PDREA_DESC,
CASE 
	WHEN T691F_OIREA='' THEN 'No message'
	WHEN T691F_OIREA='A' THEN 'Warning'
	WHEN T691F_OIREA='B' THEN 'Error message'
	WHEN T691F_OIREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_OIREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_OIREA_DESC,
CASE 
	WHEN T691F_DNREA='' THEN 'No message'
	WHEN T691F_DNREA='A' THEN 'Warning'
	WHEN T691F_DNREA='B' THEN 'Error message'
	WHEN T691F_DNREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_DNREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_DNREA_DESC,
CASE 
	WHEN T691F_SPREA='' THEN 'No message'
	WHEN T691F_SPREA='A' THEN 'Warning'
	WHEN T691F_SPREA='B' THEN 'Error message'
	WHEN T691F_SPREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_SPREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_SPREA_DESC,
CASE 
	WHEN T691F_PJREA='' THEN 'No message'
	WHEN T691F_PJREA='A' THEN 'Warning'
	WHEN T691F_PJREA='B' THEN 'Error message'
	WHEN T691F_PJREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_PJREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_PJREA_DESC,
CASE 
	WHEN T691F_PKREA='' THEN 'No message'
	WHEN T691F_PKREA='A' THEN 'Warning'
	WHEN T691F_PKREA='B' THEN 'Error message'
	WHEN T691F_PKREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_PKREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_PKREA_DESC,
CASE 
	WHEN T691F_PLREA='' THEN 'No message'
	WHEN T691F_PLREA='A' THEN 'Warning'
	WHEN T691F_PLREA='B' THEN 'Error message'
	WHEN T691F_PLREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_PLREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_PLREA_DESC ,
CASE 
	WHEN T691F_USR0REA='' THEN 'No message'
	WHEN T691F_USR0REA='A' THEN 'Warning'
	WHEN T691F_USR0REA='B' THEN 'Error message'
	WHEN T691F_USR0REA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_USR0REA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_USR0REA_DESC ,
CASE 
	WHEN T691F_USR1REA='' THEN 'No message'
	WHEN T691F_USR1REA='A' THEN 'Warning'
	WHEN T691F_USR1REA='B' THEN 'Error message'
	WHEN T691F_USR1REA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_USR1REA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_USR1REA_DESC 
,
CASE 
	WHEN T691F_USR2REA='' THEN 'No message'
	WHEN T691F_USR2REA='A' THEN 'Warning'
	WHEN T691F_USR2REA='B' THEN 'Error message'
	WHEN T691F_USR2REA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_USR2REA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_USR2REA_DESC ,
CASE 
	WHEN T691F_PMREA='' THEN 'No message'
	WHEN T691F_PMREA='A' THEN 'Warning'
	WHEN T691F_PMREA='B' THEN 'Error message'
	WHEN T691F_PMREA='C' THEN 'Like A + value by which the credit limit has been exceeded'
	WHEN T691F_PMREA='D' THEN 'Like B + value by which the credit limit has been exceeded'
END AS ZF_T691F_PMREA_DESC ,
	T691T_RTEXT
INTO BC43_01_IT_T691F
FROM A_T691F
LEFT JOIN A_T691T
ON T691F_KKBER=T691T_KKBER AND T691F_CTLPC=T691T_CTLPC AND T691T_SPRAS='EN'
GO
