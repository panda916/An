USE [DIVA_SAP_USAGE_S4]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[B02_SAP_CONFIGURATION_O2C](@DBNAME as NVARCHAR(MAX))
AS

-- Remove exist tables
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU09_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU17_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU19_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU20_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU24_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU28_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU29A_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU29B_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU46_50_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU48_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU49_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU51_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU55_%'
	EXEC SP_REMOVE_TABLES_MASTER @DBNAME, 'SU87_%'

-- Run all scripts related to O2C
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU09_Identify credit memo/ returns sales doc types that don't prevent billing]   
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU17_Identify credit memo document types not set to reference sales orders or billing documents]  
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU19_Identify delivery item categories that don't block overdelivery]  
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU20_Identify billing document types that prevent auto GL posting]  
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU24_Identify sales document item categories that don't control items, quantities, pricing or billing]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU28_Identify credit control areas that don't provide default credit limits]   
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU29A_Identify delivery documents that do not require/ copy from the sales order]  
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU29B_Identify sales order document types that do not have default delivery/ billing document types set-up]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU46_50_Identify pricing procedures that allow for manual pricing]   
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU48_Identify sales document types that are not set to check credit limits]   
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU49_Identify lockboxes that are not correctly set-up]  
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU51_Identify document types credit memos that are not blocked for processing]   
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU55_Identify one-time customers that are not in correct account group]
	EXEC SP_EXEC_DYNAMIC @DBNAME,  [script_SU87_Identify sensitive customer fields that are not set for 4-eye principle]   
GO
