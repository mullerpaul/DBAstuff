CREATE OR REPLACE FORCE VIEW dm_atom_job_title_cat
AS
SELECT atm.assignment_continuity_id,
       atm.std_buyerorg_id,
       db.std_buyerorg_name,
       atm.std_supplierorg_id,
       ds.std_supplierorg_name,
       jt.std_job_title_id,
       jt.std_job_title_desc,
       jc.std_job_category_id,
       jc.std_job_category_desc,
       atm.supplier_org_id,
       atm.buyer_org_id,
       atm.data_source_code       
  FROM dm_atom_assign_xref atm,
       dm_job_titles jt,
       dm_job_category jc,
       dm_buyers db,
       dm_suppliers ds
 WHERE atm.std_job_title_id   = jt.std_job_title_id
   AND jt.std_job_category_id = jc.std_job_category_id
   AND atm.std_buyerorg_id    = db.std_buyerorg_id
   AND atm.std_supplierorg_id = ds.std_supplierorg_id
   AND jt.is_deleted          = 'N'
/ 
