/*******************************************************************************
SCRIPT NAME         dm_invoiced_spend_all_mv_log.sql 
 
BASE OBJECT NAME    DM_INVOICED_SPEND_ALL
 
CREATED             5/11/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

STORY               IQN-32023

DESCRIPTION         This materialized view log was created to provide an aggregated 
                    view of Assignment Invoiced Spend by Month.  The original 
                    purpose is to provide data for a UI widget that will chart
                    Spend by month over time, but this could be used by any
                    other consumer for any other purpose.
                    
Here are the configurations for the MV:
Use ROWID if no PK is defined on the base table, which it is not.
Specify WITH SEQUENCE if the table is expected to have a mix of inserts/direct-loads, deletes, and updates.  It is not.
The normal and only operation on the base table (DM_INVOICED_SPEND_ALL) is INSERT INTO.  If an UPDATE or DELETE were
to take place, it would be due to a data issue and would need to be handled with a manual script.  If that happens,
you must then perform a Complete MV Refresh along with whatever manual script is doing an UPDATE or DELETE.  
In other words, UPDATE and DELETE operations will not be picked up during the normal FAST REFRESH of this MV.
You must specify all columns that will be selected from and used as filters in the MV.
You must use INCLUDING NEW VALUES in order to do FAST REFRESH.
If you truncate the MV Log of the base table or drop and recreate, it will force a Complete Refresh.

*******************************************************************************/  

CREATE MATERIALIZED VIEW LOG ON dm_invoiced_spend_all 
WITH ROWID
(buyer_bus_org_fk, work_order_id , invoice_date, currency, buyer_adjusted_amount, work_order_type)
INCLUDING NEW VALUES
/


