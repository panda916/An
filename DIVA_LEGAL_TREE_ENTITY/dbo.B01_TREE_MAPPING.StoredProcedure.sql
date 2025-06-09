USE [DIVA_LEGAL_TREE_ENTITY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE      PROCEDURE [dbo].[B01_TREE_MAPPING]
AS


-- Step 1 / Make tree entity based on AM_TREE_MAPPING

EXEC SP_REMOVE_TABLES   'AM_TREE_MAPPING_RESULT'

SELECT 
	DISTINCT 
	ROW_NUMBER() OVER(ORDER BY A.Child ASC)  AS ZF_ID,
	A.Child as 'Parent',
	ISNULL(B.Child,'') as 'Child level 1',
	ISNULL(C.Child,'') as 'Child level 2',
	ISNULL(D.Child,'') as 'Child level 3',
	ISNULL(E.Child ,'')as 'Child level 4',
	ISNULL(F.Child,'') as 'Child level 5',
	ISNULL(G.Child,'') as 'Child level 6',
	ISNULL(H.Child,'') as 'Child level 7' ,
	ISNULL(K.Child,'') as 'Child level 8',
	ISNULL(L.Child,'') as 'Child level 9',
	ISNULL(I.Child,'') as 'Child level 10',
	ISNULL(O.Child,'') as 'Child level 11',
	ISNULL(Y.Child,'') as 'Child level 12'
INTO AM_TREE_MAPPING_RESULT
FROM AM_TREE_MAPPING AS A
LEFT JOIN AM_TREE_MAPPING AS B ON B.Parent_Company = A.Child -- Level 1
LEFT JOIN AM_TREE_MAPPING AS C ON C.Parent_Company = B.Child -- Level 2
LEFT JOIN AM_TREE_MAPPING AS D ON D.Parent_Company = C.Child -- Level 3
LEFT JOIN AM_TREE_MAPPING AS E ON E.Parent_Company = D.Child -- Level 4
LEFT JOIN AM_TREE_MAPPING AS F ON F.Parent_Company = E.Child -- Level 5
LEFT JOIN AM_TREE_MAPPING AS G ON G.Parent_Company = F.Child -- Level 6
LEFT JOIN AM_TREE_MAPPING AS H ON H.Parent_Company = G.Child -- Level 7
LEFT JOIN AM_TREE_MAPPING AS K ON K.Parent_Company = H.Child -- Level 8
LEFT JOIN AM_TREE_MAPPING AS L ON L.Parent_Company = K.Child -- Level 9
LEFT JOIN AM_TREE_MAPPING AS I ON I.Parent_Company = L.Child -- Level 10
LEFT JOIN AM_TREE_MAPPING AS O ON O.Parent_Company = I.Child -- Level 11
LEFT JOIN AM_TREE_MAPPING AS Y ON Y.Parent_Company = O.Child -- Level 12

WHERE A.Parent_Company = 'Top node' -- and B.Child = 'Sony Corporation' AND D.Child = 'SMN Corporation' AND E.Child = 'Ruby Groupe Inc.'
ORDER BY 
	A.Child , 
	ISNULL(B.Child,''), 
	ISNULL(C.Child,''), 
	ISNULL(D.Child,''), 
	ISNULL(E.Child,''), 
	ISNULL(F.Child,''), 
	ISNULL(G.Child,''), 
	ISNULL(H.Child,''), 
	ISNULL(K.Child,''), 
	ISNULL(L.Child,''), 
	ISNULL(I.Child,''), 
	ISNULL(O.Child,'') ,
	ISNULL(Y.Child,'')


-- Step 2 / Append value into company country

EXEC SP_REMOVE_TABLES   'AM_TREE_MAPPING_RESULT_APPEND'

SELECT DISTINCT *
INTO AM_TREE_MAPPING_RESULT_APPEND
FROM (

SELECT 
	DISTINCT 
	ZF_ID,
	Parent AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Parent level
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 1] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 1
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 2] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 2
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 3] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 3
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 3] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 3
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 4] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 4
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 5] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 5
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 6] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 6
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 7] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 7
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 8] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 8
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 9] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 9
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 10] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 10
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 11] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 11
UNION
SELECT 
	DISTINCT 
	ZF_ID,
	[Child level 12] AS ZF_KEY_JOIN    
FROM AM_TREE_MAPPING_RESULT   -- Child level 12 
) AS A 
LEFT JOIN (SELECT DISTINCT * FROM AM_COUNTRY_KEY ) AS B ON A.ZF_KEY_JOIN = B.Company
WHERE A.ZF_KEY_JOIN <> '' 
ORDER BY A.ZF_ID


SELECT * FROM AM_TREE_MAPPING_RESULT_APPEND



GO
