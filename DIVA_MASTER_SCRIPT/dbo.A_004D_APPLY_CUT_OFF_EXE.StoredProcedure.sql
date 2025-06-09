USE [DIVA_MASTER_SCRIPT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[A_004D_APPLY_CUT_OFF_EXE](@cut_off_date_YYYYMMDD NVARCHAR(MAX))
AS


DECLARE @cut_off_date DATE = CONVERT(date, @cut_off_date_YYYYMMDD, 111)
BEGIN TRY
	DECLARE @delete_record INT, @errormsg NVARCHAR(MAX)
	SET @delete_record = (SELECT COUNT(*) FROM A_EKKO WHERE EKKO_BEDAT > @cut_off_date)
	SET @errormsg = CAST(@delete_record AS NVARCHAR(MAX)) + ' record(s) will be deleted'
	RAISERROR (@errormsg, 0, 1) WITH NOWAIT
	DELETE A_EKKO WHERE EKKO_BEDAT > @cut_off_date
END TRY BEGIN CATCH END CATCH

BEGIN TRY
	SET @delete_record = (SELECT COUNT(*) FROM A_BSAK WHERE BSAK_BUDAT > @cut_off_date)
	SET @errormsg = CAST(@delete_record AS NVARCHAR(MAX)) + ' record(s) will be deleted'
	RAISERROR (@errormsg, 0, 1) WITH NOWAIT
	DELETE A_BSAK WHERE BSAK_BUDAT > @cut_off_date
END TRY BEGIN CATCH END CATCH

BEGIN TRY
	SET @delete_record = (SELECT COUNT(*) FROM A_BSIK WHERE BSIK_BUDAT > @cut_off_date)
	SET @errormsg = CAST(@delete_record AS NVARCHAR(MAX)) + ' record(s) will be deleted'
	RAISERROR (@errormsg, 0, 1) WITH NOWAIT
	DELETE A_BSIK WHERE BSIK_BUDAT > @cut_off_date
END TRY BEGIN CATCH END CATCH

BEGIN TRY
	SET @delete_record = (SELECT COUNT(*) FROM A_BKPF WHERE BKPF_BUDAT > @cut_off_date)
	SET @errormsg = CAST(@delete_record AS NVARCHAR(MAX)) + ' record(s) will be deleted'
	RAISERROR (@errormsg, 0, 1) WITH NOWAIT
	DELETE A_BKPF WHERE BKPF_BUDAT > @cut_off_date
END TRY BEGIN CATCH END CATCH

BEGIN TRY
	SET @delete_record = (SELECT COUNT(*) FROM A_RBKP WHERE RBKP_BUDAT > @cut_off_date)
	SET @errormsg = CAST(@delete_record AS NVARCHAR(MAX)) + ' record(s) will be deleted'
	RAISERROR (@errormsg, 0, 1) WITH NOWAIT
	DELETE A_RBKP WHERE RBKP_BUDAT > @cut_off_date
END TRY BEGIN CATCH END CATCH

BEGIN TRY
DELETE A_MKPF WHERE MKPF_BUDAT > @cut_off_date
END TRY BEGIN CATCH END CATCH

GO
