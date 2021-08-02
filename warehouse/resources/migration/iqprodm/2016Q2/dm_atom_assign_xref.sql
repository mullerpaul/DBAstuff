--IQN-32013
--Joe Pullifrone, 5/16/2016
--The Purpose of script is to create a MVIEW to hold all Assignments in the DM that have gone through the Rate Event process and thus have
--been given Standardized (ATOM) values for Buyer Org, Supplier Org, Job Title/Cat, and Place.  Category ID is not needed here since it's on
--the DM_JOB_TITLES table

CREATE MATERIALIZED VIEW dm_atom_assign_xref 
PARALLEL 4
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
--ATOMIC_REFRESH = FALSE, mview will be truncated and whole data will be inserted. The refresh will go faster, and no undo will be generated.
--ATOMIC_REFRESH = TRUE (default), mview will be deleted and whole data will be inserted. Undo will be generated. We will have access at all times even while it is being refreshed.
--The MV refresh for this should be placed inside the code that loads DM_RATE_EVENT_MASTER, preferably in DM_RATE_EVENTS_PROC.  The reason we should choose on demand compete refresh
--is because the base table is only updated/inserted into 1x/week.  
ENABLE QUERY REWRITE
AS
SELECT assignment_id AS assignment_continuity_id,
       std_buyerorg_id, 
       std_supplierorg_id,
       std_job_title_id, 
       std_place_id, 
       buyerorg_id       AS buyer_org_id,       
       supplierorg_id    AS supplier_org_id,
       data_source_code
  FROM (SELECT rem.*, rank() over (partition by rem.assignment_id, rem.data_source_code order by rem.rate_event_end_date desc, rem.rate_event_start_date desc) rk 
          FROM dm_rate_event_master rem
         WHERE rem.delete_reason_code = 'N')  
  WHERE rk = 1
/ 
COMMENT ON COLUMN dm_atom_assign_xref.assignment_continuity_id  IS 'Unique value of Assignment - lowest level in this data set'
/ 
COMMENT ON COLUMN dm_atom_assign_xref.std_buyerorg_id           IS 'Standardized value for Buyer Org ID used to get buyer name'
/
COMMENT ON COLUMN dm_atom_assign_xref.std_supplierorg_id        IS 'Standardized value for Supplier Org ID used to get supplier name'
/
COMMENT ON COLUMN dm_atom_assign_xref.std_job_title_id          IS 'Standardized value for Job Title ID used to get job title and category descriptions'
/
COMMENT ON COLUMN dm_atom_assign_xref.std_place_id              IS 'Standardized value for Place ID - used to get place information'
/
COMMENT ON COLUMN dm_atom_assign_xref.buyer_org_id              IS 'FO value for Buyer Organization ID'
/
COMMENT ON COLUMN dm_atom_assign_xref.supplier_org_id           IS 'FO value for Supplier Organization ID'
/
COMMENT ON COLUMN dm_atom_assign_xref.data_source_code          IS 'Indicates the origin of data - usually either WF or everyone else, perhaps EMEA in the future'
/