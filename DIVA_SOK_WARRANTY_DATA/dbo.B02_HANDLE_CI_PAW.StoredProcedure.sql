USE [DIVA_SOK_WARRANTY_DATA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE        PROC [dbo].[B02_HANDLE_CI_PAW]
AS 


select IncidentNo, COUNT(*) A
FROM [dbo].[Reg_full_data]
GROUP BY IncidentNo
HAVING COUNT(*) > 1      
ORDER BY A DESC




UPDATE [Reg_full_data]
SET IncidentNo = TRIM(IncidentNo)



SELECT 
	Z_FY,
	IncidentNo,
	ISNULL([Pending/Approved2],'') Approved1, -- Column R
	ISNULL([Pending/Approved3],'')  Approved2, -- V
	ISNULL([Pending/Approved4],'')  Approved3, -- Z
	ISNULL([Pending/Approved5],'')  Approved4, -- ad 
	ISNULL([Pending/Approved6],'')  Approved5, -- AH
	ISNULL([Pending/Approved7],'')  Approved6, -- AL
	ISNULL([Pending/Approved8],'')  Approved7, -- AP 
	ISNULL([Pending/Approved9],'')  Approved8, -- AT
	ISNULL([Pending/Approved10] ,'')  Approved9, -- AX
	ISNULL([Pending/Approved11] ,'') Approved10, -- BB
	ISNULL([Pending/Approved12] ,'') Approved11, -- BF
	ISNULL([Pending/Approved13] ,'') Approved12, -- BJ
	ISNULL([Pending/Approved14] ,'') Approved13, -- BN
	ISNULL([Pending/Approved15] ,'') Approved14, -- BR
	ISNULL([Pending/Approved16] ,'') Approved15, -- BV
	ISNULL([Pending/Approved17] ,'') Approved16, -- BZ
	ISNULL([Pending/Approved18] ,'') Approved17, -- CD
	ISNULL([Pending/Approved19] ,'') Approved18, -- CZ
	ISNULL([Pending/Approved20] ,'') Approved19, -- CL
	ISNULL([Pending/Approved21] ,'') Approved20, -- CP
	ISNULL([Pending/Approved22] ,'') Approved21, -- CT
	ISNULL([Pending/Approved23] ,'') Approved22, -- CX
	([RCD_USD (category)] )  [RCD_USD (category)]-- DM
INTO [Reg_List_of_Approved]
FROM [Reg_full_data]

-- Update the [Reg_List_of_Approved] table for [RCD_USD (category)] amounbt

UPDATE [Reg_List_of_Approved]
SET [RCD_USD (category)] = 
CASE 
	WHEN [RCD_USD (category)] IS NULL THEN '0'
	WHEN [RCD_USD (category)] = '<1000' THEN '1. < 1K'
	WHEN [RCD_USD (category)] = '<5000' THEN '2. < 5K'
	WHEN [RCD_USD (category)] = '<10000' THEN '3. < 10K'
	WHEN [RCD_USD (category)] = '<50000' THEN '4. < 50K'
	WHEN [RCD_USD (category)] = '<100000' THEN '5. < 100K'
	WHEN [RCD_USD (category)] = '<200000' THEN '6. < 200K'
	WHEN [RCD_USD (category)] = '<500000' THEN '7. < 500K'
	WHEN [RCD_USD (category)] = '<1000000' THEN '8. < 1M'
	WHEN [RCD_USD (category)] = '>1000000' THEN '9. > 1M'

END 


--- DELETE RECORDS WHERE DM IS NULL AND DUP

DELETE FROM [Reg_List_of_Approved]

WHERE CONCAT(Z_FY, IncidentNo) IN 
(

	SELECT 
		CONCAT(Z_FY, IncidentNo)
	FROM [Reg_List_of_Approved]
	GROUP BY CONCAT(Z_FY, IncidentNo)
	HAVING COUNT(*) > 1
	   
)
AND [RCD_USD (category)] IS NULL



-- Step 2 / Add table to show list of Approved vertical
DROP TABLE [Reg_List_of_Approved_VER]

SELECT *,
ROW_NUMBER() OVER(PARTITION BY Z_FY,IncidentNo   ORDER BY FLAG asc) as Rowid
INTO [Reg_List_of_Approved_VER]
FROM (
SELECT  RANK() OVER(PARTITION BY Z_FY,IncidentNo,Name_of_approved   ORDER BY FLAG asc) Rank, *

FROM 
(

SELECT 
	Z_FY,IncidentNo, Approved1 AS Name_of_approved, 1 as flag
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved2 AS Name_of_approved ,2
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved3 AS Name_of_approved, 3
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved4 AS Name_of_approved , 4
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved5 AS Name_of_approved , 5
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved6 AS Name_of_approved , 6
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved7 AS Name_of_approved , 7
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved8 AS Name_of_approved , 8
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved9 AS Name_of_approved, 9
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved10 AS Name_of_approved, 10
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved11 AS Name_of_approved, 11
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved12 AS Name_of_approved, 12
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved13 AS Name_of_approved, 13
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved14 AS Name_of_approved, 14
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved15 AS Name_of_approved , 15
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved16 AS Name_of_approved, 16
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved17 AS Name_of_approved, 17
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved18 AS Name_of_approved, 18
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved19 AS Name_of_approved, 19
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved20 AS Name_of_approved, 20
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved21 AS Name_of_approved, 21
FROM [Reg_List_of_Approved]
UNION ALL 
SELECT 
	Z_FY,IncidentNo, Approved22 AS Name_of_approved, 22
FROM [Reg_List_of_Approved]
) A 
WHERE A.Name_of_approved <> ''
) B 
WHERE B .Rank =  1
ORDER BY flag






-- 3391
-- 30740

ALTER TABLE [Reg_List_of_Approved_VER] ADD ZF_NO_DISTINCT_APPR INT

UPDATE [Reg_List_of_Approved_VER]
SET ZF_NO_DISTINCT_APPR = ZF_COUNT
FROM [Reg_List_of_Approved_VER] A
	INNER JOIN (
		SELECT 
			CONCAT(Z_FY, IncidentNo) ZF_KEY,
			COUNT(DISTINCT Rowid) ZF_COUNT
		FROM [Reg_List_of_Approved_VER]
		GROUP BY CONCAT(Z_FY, IncidentNo)
	)B
ON ZF_KEY = CONCAT(A.Z_FY, A.IncidentNo)

ALTER TABLE [Reg_List_of_Approved_VER] ADD ZF_RCD_USD_AMOUNT NVARCHAR(20)

UPDATE [Reg_List_of_Approved_VER]
SET ZF_RCD_USD_AMOUNT = B.[RCD_USD (category)]
FROM [Reg_List_of_Approved_VER] A 
	INNER JOIN [Reg_List_of_Approved]  B 
		ON A.Z_FY = B.Z_FY
		AND A.IncidentNo = B.IncidentNo





SELECT *
FROM [Reg_List_of_Approved]
where IncidentNo = 'CI-SEV-ST2-21040076'


SELECT DISTINCT [RCD_USD (category)]
FROM [Reg_List_of_Approved]
WHERE IncidentNo = 'CI-SEV-ST2-22030039'






GO
