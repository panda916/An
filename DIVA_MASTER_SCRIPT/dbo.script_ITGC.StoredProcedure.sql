USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[script_ITGC]
AS
Begin
EXEC SP_DROPTABLE  B_01_IT_MAIN_FACT
--SPE model
SELECT DISTINCT
		Entity AS 'Entity' ,
		Cycle AS 'Control_Category' ,
		'' AS 'Financial_Process' ,
		Process AS 'Process' ,
		'' AS 'Sub-Process' ,
		[Control UID] AS 'Control_ID' ,
		Title AS 'Title' ,
		Description AS 'Control_Description' ,
		'' AS 'Control_Reference' ,
		'' AS 'Legacy_Control_Number' ,
		Frequency AS 'Frequency' ,
		Nature AS 'Nature' ,
		[Control Type] AS 'Control_Type' ,
		[PWC Testing Type] AS 'PwC_Reliance' ,
		[Risk Rating] AS 'Risk_Rating' ,
		Risks AS 'Risk_Description' ,
		[Control Importance] AS 'Importance' ,
		[Subprocess Name] AS 'Application_Detail' ,
		[Application] AS 'Application' ,
		[Annual Sample Size] AS 'Sample_Size' ,
		'' AS 'CEL' ,
		[Control mapping] AS 'Control_Mapping' ,
		'' AS 'Module_OR_Component' ,
		A_SPE_MAPPING.[Map to ITGC Norm Model] AS 'Map_to_ITGC_Norm_Model',
		[Text description] AS 'ITCG_Norm_Text_description'
		INTO B_01_IT_MAIN_FACT
FROM A_SPE
LEFT JOIN A_SPE_MAPPING
ON A_SPE.[Control UID]=A_SPE_MAPPING.[Control ID]
LEFT JOIN A_SPE_ITGC_TEXT
ON A_SPE_ITGC_TEXT.[Map to ITGC Norm Model]=A_SPE_MAPPING.[Map to ITGC Norm Model]

-- SPE

EXEC SP_DROPTABLE  B_02_IT_CONTROL_MAP_VERITCAL
SELECT [Current ITGC Normative],
IIF (AIMS='X','AIMS','') AS ZF_APP_DESC
INTO B_02_IT_CONTROL_MAP_VERITCAL
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([ALL]='X','ALL','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([All_D-Series]='X','All D-Series','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (AMQ='X','AMQ','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([Ariba On Demand]='X','Ariba On Demand','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([Ariba On Prem]='X','Ariba On Prem','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (Broadview='X','Broadview','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (C2C='X','C2C','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (CIPS='X','CIPS','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (DEX='X','DEX','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([DEX BO]='X','DEX BO','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (LAS='X','LAS','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([EP PAS]='X','EP PAS','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (GPAS='X','GPAS','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (IDM='X','IDM','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (Mainframe='X','Mainframe','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (OPUS='X','OPUS','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (PAWS='X','PAWS','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([SAP SPNI]='X','SAP SPNI','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([SAP_ECC]='X','SAP ECC','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([SAP Business Objects]='X','SAP Business Objects','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([SAP GRC]='X','SAP GRC','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([SAP (BW/4_HANA)]='X','SAP (BW/4HANA)','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([SAP (S4/HANA)]='X','SAP (S4/HANA)','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([SAP SLT]='X','SAP SLT','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (S2F='X','S2F','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([Spent & Committed]='X','Spent & Committed','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (TAAS='X','TAAS','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([Visual Lease]='X','Visual_Lease','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([Web Methods]='X','Web Methods','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([Work Day]='X','Work Day','') AS ZF_APP_DESC
FROM A_SPE_APPLICATION_MAP

--SMP


--SMP
EXEC SP_DROPTABLE  B_01_IT_MAIN_FACT
SELECT 
		[Sony OpCo] AS 'Entity' ,
		'' AS 'Control_Category' ,
		[Financial Process] AS 'Financial_Process' ,
		[ITGC Process_Process Name_SOX ITGC Control Area - SMP] AS 'Process' ,
		'' AS 'Sub-Process' ,
		A_SMP.[Control #] AS 'Control_ID' ,
		'' AS 'Title' ,
		[Control Description] AS 'Control_Description' ,
		'' AS 'Control_Reference' ,
		'' AS 'Legacy_Control_Number' ,
		Frequency AS 'Frequency' ,
		[Nature of Control_Preventative / Detective] AS 'Nature' ,
		[Control Type_Manual / Automated] AS 'Control_Type' ,
		[PWC Testing Type] AS 'PwC_Reliance' ,
		[Risk Rating] AS 'Risk_Rating' ,
		[Risk Description] AS 'Risk_Description' ,
		[Control Importance - SMP] AS 'Importance' ,
		'' AS 'Application_Detail' ,
		[Subprocess Name] AS 'Application' ,
		[Annual Sample Size - SMP] AS 'Sample_Size' ,
		'' AS 'CEL' ,
		[Mapping to ITGC Process] AS 'Control_Mapping' ,
		'' AS 'Module_OR_Component' ,
A_SMP_MAPPING.[Normative mapping (AY)] AS 'Map_to_ITGC_Norm_Model',
		[Text description] AS 'ITCG_Norm_Text_description'
				INTO B_01_IT_MAIN_FACT
FROM A_SMP
JOIN A_SMP_MAPPING
ON A_SMP_MAPPING.[Control #]=A_SMP.[Control #]
LEFT JOIN A_SMP_ITGC_TEXT
ON A_SMP_MAPPING.[Normative mapping (AY)]=A_SMP_ITGC_TEXT.[Control #]
--SMP
EXEC SP_DROPTABLE  B_02_IT_CONTROL_MAP_VERITCAL
SELECT [Current ITGC Normative],
IIF (Tempo='X','Tempo','') AS ZF_APP_DESC
INTO B_02_IT_CONTROL_MAP_VERITCAL
FROM A_SMP_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF ([SAP BPC]='X','SAP BPC','') AS ZF_APP_DESC
FROM A_SMP_APPLICATION_MAP
UNION
SELECT [Current ITGC Normative],
IIF (Navision='X','Navision','') AS ZF_APP_DESC
FROM A_SMP_APPLICATION_MAP

--SME

EXEC SP_DROPTABLE  B_01_IT_MAIN_FACT
SELECT
		[BU/DIV] AS 'Entity' ,
		'' AS 'Control_Category' ,
		'' AS 'Financial_Process' ,
		'' AS 'Process' ,
		'' AS 'Sub-Process' ,
		[Control #] AS 'Control_ID' ,
		'' AS 'Title' ,
		[FYE20 Final Control Wording] AS 'Control_Description' ,
		'' AS 'Control_Reference' ,
		'' AS 'Legacy_Control_Number' ,
		[Control Frequency (daily, weekly, Monthly, etc#)] AS 'Frequency' ,
		[Nature (Prev#, Detect#, Etc#)] AS 'Nature' ,
		[Type (Auto, Manual, etc#)] AS 'Control_Type' ,
		[PwC Reliance] AS 'PwC_Reliance' ,
		[Control Risk Rating (High Med, Low)] AS 'Risk_Rating' ,
		Risks AS 'Risk_Description' ,
		[Importance (Key, Non-key, Primary, Secondary, etc#)] AS 'Importance' ,
		'' AS 'Application_Detail' ,
		[SAP (ECC, BW, SM)] AS 'Application' ,
		[Annual Sample size] AS 'Sample_Size' ,
		[CEL (Yes or No)] AS 'CEL' ,
		[Mapping to ITGC Process] AS 'Control_Mapping' ,
		'' AS 'Module_OR_Component' 
FROM A_SME


end
GO
