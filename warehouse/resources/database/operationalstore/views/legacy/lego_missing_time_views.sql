CREATE OR REPLACE FORCE VIEW lego_missing_time_vw 
AS 
SELECT assignment_continuity_id,
       buyer_org_id,
       supplier_org_id,
       week_ending_date
  FROM lego_missing_time
/
  
COMMENT ON COLUMN lego_missing_time_vw.assignment_continuity_id      IS 'Assignment Continuity ID - FK to LEGO_ASSIGNMENT_VW'
/
COMMENT ON COLUMN lego_missing_time_vw.buyer_org_id                  IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/
COMMENT ON COLUMN lego_missing_time_vw.supplier_org_id               IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/
COMMENT ON COLUMN lego_missing_time_vw.week_ending_date              IS 'Timecard Weekending Date that is missing'
/

  
