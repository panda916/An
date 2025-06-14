USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_AP_ML_PRED]

AS

--DYNAMIC_SCRIPT_START
DECLARE @output_data_1_name NVARCHAR(128)  
DECLARE @inquery NVARCHAR(MAX)    
DECLARE @python_script NVARCHAR(MAX)
DECLARE @ML_package NVARCHAR(50)

EXEC SP_DROPTABLE 'B07_10_AP_PRED_OUTPUT'  
SELECT *,  
		ROW_NUMBER ( ) OVER (ORDER BY ZF_FLAG_SUMMARY) AS ID,     
		IIF(1 < 0, ZF_FLAG_SUMMARY, '') ZF_FLAG_SUMMARY_PREDICT
		--IIF(1 < 0, ZF_FLAG_SUMMARY, '') ML_BASED  
INTO B07_10_AP_PRED_OUTPUT  
FROM B07_01_RT_FIN_AP_INV_PAY_FLAGS    
WHERE ZF_FLAG_SUMMARY = '' OR ML_BASED = 'Y'


EXEC SP_DROPTABLE 'B07_10_RT_PRED'  

SELECT TOP 0 ID, ZF_FLAG_SUMMARY_PREDICT 
	INTO B07_10_RT_PRED 
FROM B07_10_AP_PRED_OUTPUT    

SET @inquery= 'SELECT * FROM B07_10_AP_PRED_OUTPUT'

IF DB_NAME() like '%SOLA%' SET @ML_package = 'SOLA_AP_ML_PACKAGE.pkl'
ELSE SET @ML_package = 'GENERIC_AP_ML_PACKAGE.pkl'

SET @python_script = N'
import pickle

import sys
sys.path.insert(0, "F:\\09_MACHINE_LEARNING_MATERIAL")
import support_class_def

class CustomUnpickler(pickle.Unpickler):
	def find_class(self, module, name):
		if name == "ColumnSelector":
			from support_class_def import ColumnSelector
			return ColumnSelector
		if name == "preprocessor":
			from support_class_def import preprocessor
			return preprocessor.preprocessor
		if name == "tokenizer_porter":
			from support_class_def import preprocessor
			return preprocessor.tokenizer_porter
		return super().find_class(module, name)


pipeline = CustomUnpickler(open("F:\\09_MACHINE_LEARNING_MATERIAL\\' + @ML_package + '", "rb")).load()  
X = InputDataSet[["BSAIK_BUKRS","T003T_LTEXT", "TSTCT_TTEXT", "BSAIK_SHKZG", "ZF_DEBIT_ACCOUNTS", "ZF_CREDIT_ACCOUNTS", "ZF_DEBIT_ACCOUNT_TEXTS", "ZF_CREDIT_ACCOUNT_TEXTS"]]  
y_pred = pipeline.predict(X)  
print(y_pred)  
InputDataSet["ZF_FLAG_SUMMARY_PREDICT"] = y_pred  
InputDataSet.fillna("")  
OutputDataSet = InputDataSet[["ID", "ZF_FLAG_SUMMARY_PREDICT"]]'

INSERT INTO B07_10_RT_PRED(ID, ZF_FLAG_SUMMARY_PREDICT)
EXEC sp_execute_external_script
  @language = N'Python',
  @script = @python_script,
@input_data_1 = @inquery,    
@input_data_1_name = N'InputDataSet'

UPDATE B07_10_AP_PRED_OUTPUT  
SET ZF_FLAG_SUMMARY = B07_10_RT_PRED.ZF_FLAG_SUMMARY_PREDICT,
ML_BASED = 'Y'
FROM B07_10_AP_PRED_OUTPUT  
LEFT JOIN B07_10_RT_PRED ON B07_10_RT_PRED.ID = B07_10_AP_PRED_OUTPUT.ID


DELETE AM_B07_01_RT
WHERE ZF_FLAG_SUMMARY = '' OR ML_BASED = 'Y'


INSERT INTO AM_B07_01_RT
			(ZF_FLAG_SUMMARY, ML_BASED, BSAIK_BUKRS, BSAIK_SHKZG, BSAIK_BSCHL, BSAIK_BLART, 
			T003T_LTEXT, LFA1_KTOKK, T077Y_TXT30, BKPF_TCODE, TSTCT_TTEXT, ZF_DEBIT_ACCOUNTS, 
			ZF_CREDIT_ACCOUNTS, ZF_DEBIT_ACCOUNT_TEXTS, ZF_CREDIT_ACCOUNT_TEXTS, ZF_BANK_DEBIT_ACCOUNTS, 
			ZF_BANK_CREDIT_ACCOUNTS, ZF_BS_DEBIT_ACCOUNTS, ZF_BS_CREDIT_ACCOUNTS, ZF_PL_DEBIT_ACCOUNTS, 
			ZF_PL_CREDIT_ACCOUNTS, ZF_SU_DEBIT_ACCOUNTS, ZF_SU_CREDIT_ACCOUNTS, ZF_CU_DEBIT_ACCOUNTS, 
			ZF_CU_CREDIT_ACCOUNTS, ZF_LIST_CSKT_KOSTL, ZF_LIST_CSKT_KTEXT)

SELECT ZF_FLAG_SUMMARY, ML_BASED, BSAIK_BUKRS, BSAIK_SHKZG, BSAIK_BSCHL, BSAIK_BLART, 
			T003T_LTEXT, LFA1_KTOKK, T077Y_TXT30, BKPF_TCODE, TSTCT_TTEXT, ZF_DEBIT_ACCOUNTS, 
			ZF_CREDIT_ACCOUNTS, ZF_DEBIT_ACCOUNT_TEXTS, ZF_CREDIT_ACCOUNT_TEXTS, ZF_BANK_DEBIT_ACCOUNTS, 
			ZF_BANK_CREDIT_ACCOUNTS, ZF_BS_DEBIT_ACCOUNTS, ZF_BS_CREDIT_ACCOUNTS, ZF_PL_DEBIT_ACCOUNTS, 
			ZF_PL_CREDIT_ACCOUNTS, ZF_SU_DEBIT_ACCOUNTS, ZF_SU_CREDIT_ACCOUNTS, ZF_CU_DEBIT_ACCOUNTS, 
			ZF_CU_CREDIT_ACCOUNTS, ZF_LIST_CSKT_KOSTL, ZF_LIST_CSKT_KTEXT
FROM B07_10_AP_PRED_OUTPUT


UPDATE AM_B07_01_RT
SET ZF_SUPP_INV = IIF(ZF_FLAG_SUMMARY = 'Supplier invoice', 'X', ''),
ZF_SUPP_INV_CANC = IIF(ZF_FLAG_SUMMARY = 'Supplier invoice cancellation', 'X', ''),
ZF_SUPP_PAY = IIF(ZF_FLAG_SUMMARY = 'Supplier payment', 'X', ''),
ZF_SUPP_PAY_CANC = IIF(ZF_FLAG_SUMMARY = 'Supplier payment cancellation', 'X', ''),
ZF_OTHERS = IIF(ZF_FLAG_SUMMARY = 'Others', 'X', ''),
ZF_NO_FLAG = IIF(ZF_FLAG_SUMMARY = 'No flag', 'X', '')
GO
