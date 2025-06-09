USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SP_ML_PRED] (@database AS NVARCHAR(MAX))

AS

--DYNAMIC_SCRIPT_START
DECLARE @output_data_1_name NVARCHAR(128)
DECLARE @inquery NVARCHAR(MAX)
DECLARE @model NVARCHAR(50) = 'SOLA_ML_PACKAGE'
DECLARE @lmodel2 varbinary(max) = (select TOP 1 bin from ML_module where name = @model);
EXEC SP_DROPTABLE SOLA_ML_PREDICT
SELECT TOP 0 T003T_LTEXT, TSTCT_TTEXT, BSAIK_SHKZG, ZF_SU_DEBIT_ACCOUNTS,
			ZF_SU_CREDIT_ACCOUNTS, ZF_BS_CREDIT_ACCOUNTS, ZF_BS_DEBIT_ACCOUNTS, ZF_CREDIT_ACCOUNTS,
			ZF_DEBIT_ACCOUNTS, ZF_PL_CREDIT_ACCOUNTS, ZF_PL_DEBIT_ACCOUNTS, ZF_FLAG_SUMMARY, ZF_FLAG_SUMMARY ZF_FLAG_PREDICT
INTO DIVA_MASTER_SCRIPT..SOLA_ML_PREDICT
FROM DIVA_SOLA_DATA_REFRESH..AM_B07_01_RT

SET @inquery= 'SELECT top 1000 T003T_LTEXT, TSTCT_TTEXT, BSAIK_SHKZG, ZF_SU_DEBIT_ACCOUNTS,
			ZF_SU_CREDIT_ACCOUNTS, ZF_BS_CREDIT_ACCOUNTS, ZF_BS_DEBIT_ACCOUNTS, ZF_CREDIT_ACCOUNTS,
			ZF_DEBIT_ACCOUNTS, ZF_PL_CREDIT_ACCOUNTS, ZF_PL_DEBIT_ACCOUNTS, ZF_FLAG_SUMMARY
			FROM ' + @database + '..AM_B07_01_RT'

INSERT INTO DIVA_MASTER_SCRIPT..SOLA_ML_PREDICT
EXEC sp_execute_external_script
  @language = N'Python',
  @script = N'
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


pipeline = CustomUnpickler(open("F:\\09_MACHINE_LEARNING_MATERIAL\\SOLA_ML_PACKAGE.pkl", "rb")).load()
X = InputDataSet[["T003T_LTEXT", "TSTCT_TTEXT", "BSAIK_SHKZG", "ZF_SU_DEBIT_ACCOUNTS", "ZF_SU_CREDIT_ACCOUNTS", "ZF_BS_CREDIT_ACCOUNTS", "ZF_BS_DEBIT_ACCOUNTS", "ZF_CREDIT_ACCOUNTS", "ZF_DEBIT_ACCOUNTS", "ZF_PL_CREDIT_ACCOUNTS", "ZF_PL_DEBIT_ACCOUNTS"]]
prediction = pipeline.predict(X)
InputDataSet["Prediction"] = prediction
#print(type(InputDataSet))
OutputDataSet = InputDataSet
'
,@input_data_1 = @inquery,
  @input_data_1_name = N'InputDataSet',
  @params = N'@lmodel2 varbinary(max)',
  @lmodel2 = @lmodel2
  SELECT * FROM SOLA_ML_PREDICT
GO
