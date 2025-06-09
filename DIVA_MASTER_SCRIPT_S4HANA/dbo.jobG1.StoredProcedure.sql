USE [DIVA_MASTER_SCRIPT_S4HANA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   procedure [dbo].[jobG1]
as 
begin try
    begin try
         --USE DIVA_MASTER_SCRIPT_S4HANA
        EXEC B07_FIN_AP_AUTOMAPPING 'DIVA_SIE_S4_FY2022';
    end try 
    begin catch 
        select ERROR_MESSAGE() as messages;
    end catch

    begin try
     --USE DIVA_MASTER_SCRIPT_S4HANA
        EXEC B07_FIN_AR_AUTOMAPPING 'DIVA_SIE_S4_FY2022';
    end try 
    begin catch 
        select ERROR_MESSAGE() as messages;
    end catch

    select 'Success' as messages;
end try
begin catch 
    select ERROR_MESSAGE() as messages;
end catch
GO
