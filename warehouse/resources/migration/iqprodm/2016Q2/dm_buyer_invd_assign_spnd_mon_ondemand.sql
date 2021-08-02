/*******************************************************************************
SCRIPT NAME         dm_buyer_invd_assign_spnd_mon_ondemand.sql 
 
OBJECT NAME         DM_BUYER_INVOICED_ASSIGNMENT_SPEND_MONTHLY
 
CREATED             6/09/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

STORY               IQN-32820

DESCRIPTION         This materialized view was created to provide an aggregated 
                    view of Assignment Invoiced Spend by Month.  The original 
                    purpose is to provide data for a UI widget that will chart
                    Spend by month over time, but this could be used by any
                    other consumer for any other purpose.
                    
Here are the configurations for the MV:
Use ROWID if no PK is defined on the base table, which it is not.
Specify WITH SEQUENCE if the table is expected to have a mix of inserts/direct-loads, deletes, and updates.  It is not.
The normal and only operation on the base table (DM_INVOICED_SPEND_ALL) is INSERT INTO.  If an UPDATE or DELETE were
to take place, it would be due to a data issue.    
  ATOMIC_REFRESH = FALSE, mview will be truncated and whole data will be inserted. The refresh will go faster, 
                   no undo will be generated, but the data will not be available while it is refreshing.
  ATOMIC_REFRESH = TRUE (default), mview will be deleted and whole data will be inserted. Undo will be generated. 
                   We will have access at all times even while it is being refreshed.

*******************************************************************************/  

CREATE MATERIALIZED VIEW dm_buyer_invd_assign_spnd_mon
PARALLEL 4
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT buyer_bus_org_fk           AS buyer_org_id,
       work_order_id              AS assignment_continuity_id,
       TRUNC(invoice_date,'MM')   AS invoice_month_date,
       currency,
       SUM(buyer_adjusted_amount) AS buyer_invd_assign_spend_amt
  FROM dm_invoiced_spend_all
 WHERE work_order_type <> 'M'
 GROUP BY buyer_bus_org_fk,
          work_order_id,  
          TRUNC(invoice_date,'MM'),
          currency
/



