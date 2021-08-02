/*******************************************************************************
SCRIPT NAME         buyer_invd_assign_spnd_mon_mv.sql 
 
OBJECT NAME         BUYER_INVD_ASSIGN_SPND_MON
 
CREATED             9/26/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

STORY               IQN-34784

DESCRIPTION         This materialized view was created to provide an aggregated 
                    view of Assignment Invoiced Spend by Month.  The original 
                    purpose is to provide data for a UI widget that will chart
                    Spend by month over time, but this could be used by any
                    other consumer for any other purpose.
                    
Here are the configurations for the MV:
Use ROWID if no PK is defined on the base table, which it is not.
Specify WITH SEQUENCE if the table is expected to have a mix of inserts/direct-loads, deletes, and updates.  It is not.
The normal and only operation on the base table (LEGO_INVOICED_EXPD_DETAIL) is INSERT INTO.  If an UPDATE or DELETE were
to take place, it would be due to a data issue and would need to be handled with a manual script.  If that happens,
you must then perform a Complete MV Refresh along with whatever manual script is doing an UPDATE or DELETE.  
In other words, UPDATE and DELETE operations will not be picked up during the normal FAST REFRESH of this MV.
You must specify all columns that will be selected from and used as filters in the MV.
You must use INCLUDING NEW VALUES in order to do FAST REFRESH.
If you truncate the MV Log of the base table or drop and recreate, it will force a Complete Refresh.
When doing a Complete Refresh, set ATOMIC_REFRESH=FALSE so it does a truncate and not a delete
  ATOMIC_REFRESH = FALSE, mview will be truncated and whole data will be inserted. The refresh will go faster, and no undo will be generated.
  ATOMIC_REFRESH = TRUE (default), mview will be deleted and whole data will be inserted. Undo will be generated. We will have access at all times even while it is being refreshed.


*******************************************************************************/  

CREATE MATERIALIZED VIEW buyer_invd_assign_spnd_mon_mv
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
ENABLE QUERY REWRITE
AS
SELECT buyer_org_id,
       assignment_continuity_id,
       TRUNC(invoice_date,'MM')   AS invoice_month_date,
       source_name,
       currency,
       SUM(buyer_adjusted_amount) AS buyer_invd_assign_spend_amt
  FROM lego_invoiced_expd_detail
 WHERE assignment_continuity_id IS NOT NULL
 GROUP BY buyer_org_id,
          assignment_continuity_id,  
          TRUNC(invoice_date,'MM'),
          source_name,
          currency
/
