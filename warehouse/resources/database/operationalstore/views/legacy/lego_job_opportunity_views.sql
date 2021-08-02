/*******************************************************************************
SCRIPT NAME         lego_job_opportunity_views.sql 
 
LEGO OBJECT NAME    LEGO_JOB_OPPORTUNITY
 
CREATED             7/17/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************
 
07/17/2014 - J.Pullifrone - IQN-18303 - Initial creation - Release 12.1.2 
   
*******************************************************************************/  
CREATE OR REPLACE FORCE VIEW lego_job_opportunity_vw 
AS
SELECT supplier_org_id,
       job_opportunity_id,
       job_id,
       job_submission_id,
       create_date,
       last_modified_date,
       state
  FROM lego_job_opportunity
/

COMMENT ON COLUMN lego_job_opportunity_vw.supplier_org_id    IS 'the Foreign Key to LEGO_SUPPLIER_ORG_VW'
/
COMMENT ON COLUMN lego_job_opportunity_vw.job_opportunity_id IS 'the Primary key of this view'
/                                                                
COMMENT ON COLUMN lego_job_opportunity_vw.job_id             IS 'the Foreign Key to LEGO_JOB_VW'
/                                                                
COMMENT ON COLUMN lego_job_opportunity_vw.job_submission_id  IS 'the Foreign Key to FO job_submission'
/
COMMENT ON COLUMN lego_job_opportunity_vw.create_date        IS 'date the opportunity was created'
/                                                                
COMMENT ON COLUMN lego_job_opportunity_vw.last_modified_date IS 'date the opportunity was modified'
/
COMMENT ON COLUMN lego_job_opportunity_vw.state              IS 'state of the opportunity (Retracted or Active)'
/

