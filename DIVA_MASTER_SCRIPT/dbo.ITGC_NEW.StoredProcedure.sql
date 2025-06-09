USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ITGC_NEW]
AS
--Create a script for ITGC dashboard

--Step 1Create the main fact cube, union all Region together.
-- Some Entity don't have enought data, so they will be blank field
--For some enity don't have mapping with ITGC norminate,ITCG_Norm_Text_description,Control_Mapping
--So might need to join with the Mapping table in order get the necessary data
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
		CAST([Annual Sample Size] AS NVARCHAR) AS 'Sample_Size' ,
		'' AS 'CEL' ,
		[Control mapping] AS 'Control_Mapping' ,
		'' AS 'Module_OR_Component' ,
		A_SPE_MAPPING.[Map to ITGC Norm Model] AS 'Map_to_ITGC_Norm_Model',
		[Text description] AS 'ITCG_Norm_Text_description'
		INTO B_01_IT_MAIN_FACT
FROM A_SPE
 JOIN A_SPE_MAPPING
ON A_SPE.[Control UID]=A_SPE_MAPPING.[Control ID]
LEFT JOIN A_SPE_ITGC_TEXT
ON A_SPE_ITGC_TEXT.[Map to ITGC Norm Model]=A_SPE_MAPPING.[Map to ITGC Norm Model]


--SMP
UNION

--SMP

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
		CAST([Annual Sample Size - SMP] AS NVARCHAR) AS 'Sample_Size' ,
		'' AS 'CEL' ,
		[Mapping to ITGC Process] AS 'Control_Mapping' ,
		'' AS 'Module_OR_Component' ,
A_SMP_MAPPING.[Normative mapping (AY)] AS 'Map_to_ITGC_Norm_Model',
		[Text description] AS 'ITCG_Norm_Text_description'

FROM A_SMP
JOIN A_SMP_MAPPING
ON A_SMP_MAPPING.[Control #]=A_SMP.[Control #]
LEFT JOIN A_SMP_ITGC_TEXT
ON A_SMP_MAPPING.[Normative mapping (AY)]=A_SMP_ITGC_TEXT.[Control #]
WHERE A_SMP.[Control #]<>'TEMPO-SD-001'
UNION
--SME

SELECT
		[BU/DIV] AS 'Entity' ,
		'' AS 'Control_Category' ,
		'' AS 'Financial_Process' ,
		'' AS 'Process' ,
		'' AS 'Sub-Process' ,
		A_SME.[Control #] AS 'Control_ID' ,
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
		[Application or Infra] AS 'Application' ,
		CAST([Annual Sample size] AS NVARCHAR) AS 'Sample_Size' ,
		[CEL (Yes or No)] AS 'CEL' ,
		[Mapping to ITGC Process] AS 'Control_Mapping' ,
		'' AS 'Module_OR_Component' ,
		A_SME.[Control #] AS 'Map_to_ITGC_Norm_Model',
		[Text description] AS 'ITCG_Norm_Text_description'

FROM A_SME
LEFT JOIN A_SMP_ITGC_TEXT
ON A_SME.[Control #]=A_SMP_ITGC_TEXT.[Control #]

UNION
--SIEE

SELECT 
[Entity Name] AS 'Entity' ,
Cycle AS 'Control_Category' ,
'' AS 'Financial_Process' ,
Process AS 'Process' ,
[Subprocess Name] AS 'Sub-Process' ,
[Control UID] AS 'Control_ID' ,
Title AS 'Title' ,
Description AS 'Control_Description' ,
A_SIEE.[Control Reference] AS 'Control_Reference' ,
[Legacy Control Number] AS 'Legacy_Control_Number' ,
Frequency AS 'Frequency' ,
Nature AS 'Nature' ,
[Control Type] AS 'Control_Type' ,
[PwC Reliance] AS 'PwC_Reliance' ,
[Risk Level] AS 'Risk_Rating' ,
[Risk Description] AS 'Risk_Description' ,
Significance AS 'Importance' ,
'' AS 'Application_Detail' ,
Application AS 'Application' ,
CAST([Sample Size] AS NVARCHAR) AS 'Sample_Size' ,
'' AS 'CEL' ,
[Mapping to ITGC Process] AS 'Control_Mapping' ,
[Module/Component] AS 'Module_OR_Component' ,
[Mapping to Normative] AS 'Map_to_ITGC_Norm_Model',
		[Text description] AS 'ITCG_Norm_Text_description'

FROM A_SIEE
JOIN A_SIEE_MAPPING
ON A_SIEE_MAPPING.[Control Reference]=A_SIEE.[Control Reference]
LEFT JOIN A_SMP_ITGC_TEXT
ON A_SIEE_MAPPING.[Mapping to Normative]=A_SMP_ITGC_TEXT.[Control #]
UNION
SELECT 
[Entity Name] AS 'Entity' ,
Cycle AS 'Control_Category' ,
'' AS 'Financial_Process' ,
Process AS 'Process' ,
[Subprocess Name] AS 'Sub-Process' ,
[Control UID] AS 'Control_ID' ,
Title AS 'Title' ,
Description AS 'Control_Description' ,
A_SIE_LLC.[Control Reference] AS 'Control_Reference' ,
[Legacy Control Number] AS 'Legacy_Control_Number' ,
Frequency AS 'Frequency' ,
Nature AS 'Nature' ,
[Control Type] AS 'Control_Type' ,
[PwC Reliance] AS 'PwC_Reliance' ,
[Risk Level] AS 'Risk_Rating' ,
[Risk Description] AS 'Risk_Description' ,
Significance AS 'Importance' ,
'' AS 'Application_Detail' ,
Application AS 'Application' ,
CAST([Sample Size] AS NVARCHAR) AS 'Sample_Size' ,
'' AS 'CEL' ,
[Mapping to ITGC Process] AS 'Control_Mapping' ,
[Module/Component] AS 'Module_OR_Component' ,
[Mapping to Normative] AS 'Map_to_ITGC_Norm_Model',
		[Text description] AS 'ITCG_Norm_Text_description'

FROM A_SIE_LLC
JOIN A_SIE_LLC_MAPPING
ON A_SIE_LLC_MAPPING.[Control Reference]=A_SIE_LLC.[Control Reference]
LEFT JOIN A_SMP_ITGC_TEXT
ON A_SIE_LLC_MAPPING.[Mapping to Normative]=A_SMP_ITGC_TEXT.[Control #]


--Step 2 Add updated value fields, since for the same field in different region, the values might be in the same meaning but different text
-- For excample Nature might be Preventative, Prevent or Preventive


--Step 2.1 Create empty fields
ALTER TABLE B_01_IT_MAIN_FACT
ADD  Importance_Updated nvarchar(max),
Risk_Rating_Updated nvarchar(max),
Nature_Updated nvarchar(max),
Control_Type_Update nvarchar(max),
PwC_Reliance_Update nvarchar(max),
Frequency_Update nvarchar(max)

--Step 2.2 Update the data
UPDATE B_01_IT_MAIN_FACT
SET Nature_Updated='Detective' WHERE Nature='Detect' OR Nature='Detective'
UPDATE B_01_IT_MAIN_FACT
SET Nature_Updated='Preventative' WHERE Nature='Prevent' OR  Nature='Preventive' OR Nature='Preventative'


UPDATE B_01_IT_MAIN_FACT
SET Importance_Updated='Key' WHERE Importance='Key' OR Importance='Primary'
UPDATE B_01_IT_MAIN_FACT
SET Importance_Updated='Non-key' WHERE Importance='Secondary ' OR  Importance='Non-key' 


UPDATE B_01_IT_MAIN_FACT
SET Risk_Rating_Updated='High' WHERE Risk_Rating='High' 
UPDATE B_01_IT_MAIN_FACT
SET Risk_Rating_Updated='Medium' WHERE Risk_Rating='Med ' OR  Risk_Rating='Medium'
UPDATE B_01_IT_MAIN_FACT
SET Risk_Rating_Updated='Low' WHERE Risk_Rating='Low '


UPDATE B_01_IT_MAIN_FACT
SET Control_Type_Update='Automated' WHERE Control_Type='Automatic' OR Control_Type='Automated'
UPDATE B_01_IT_MAIN_FACT
SET Control_Type_Update='Manual' WHERE Control_Type='Manual'
UPDATE B_01_IT_MAIN_FACT
SET Control_Type_Update='Manual - IT Dependent' WHERE Control_Type='Manual - IT Dependent' OR Control_Type='IT Dependent Manual'


UPDATE B_01_IT_MAIN_FACT
SET PwC_Reliance_Update='Independent' WHERE PwC_Reliance='Independent'
UPDATE B_01_IT_MAIN_FACT
SET PwC_Reliance_Update='PwC Reliance' WHERE PwC_Reliance='PwC Reliance' OR PwC_Reliance='Reliance' OR PwC_Reliance='Rely'
UPDATE B_01_IT_MAIN_FACT
SET PwC_Reliance_Update='Blank' WHERE PwC_Reliance is NULL

UPDATE B_01_IT_MAIN_FACT 
SET Frequency_Update=Frequency
UPDATE B_01_IT_MAIN_FACT
SET Frequency_Update='Ad Hoc' WHERE Frequency='Ad hoc?' OR Frequency='Ad-hoc'
UPDATE B_01_IT_MAIN_FACT
SET Frequency_Update='Annually' WHERE  Frequency='Annual'
UPDATE B_01_IT_MAIN_FACT
SET Frequency_Update='As Needed' WHERE Frequency='As needed'
UPDATE B_01_IT_MAIN_FACT
SET Frequency_Update='Multiple times daily' WHERE  Frequency='Multiple times daily' OR Frequency='Multiple times a day'
UPDATE B_01_IT_MAIN_FACT
SET Frequency_Update='Semi Annual' WHERE  Frequency='Semi-Annual' OR Frequency='Semi-Annually'

--Step 3 Create a special table to store application for SMP
--Since for SMP, if they has Application='All Applications',
-- There will be add up for 3 others Application Tempo,SAP BPC,Navision
EXEC SP_DROPTABLE B_02_IT_APP
SELECT DISTINCT Entity,Map_to_ITGC_Norm_Model,Application,Application AS Application_UPDATE
INTO B_02_IT_APP
FROM B_01_IT_MAIN_FACT WHERE Entity='SMP'


DELETE  FROM B_02_IT_APP WHERE Application='All Applications'

INSERT INTO B_02_IT_APP VALUES 
('SMP','401.3.3','All Applications','Tempo'),
('SMP','401.3.3','All Applications','SAP BPC'),
('SMP','401.3.3','All Applications','Navision')


GO
