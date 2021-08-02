CREATE OR REPLACE FORCE VIEW lego_secure_inv_assgnmt_vw
  (user_id, assignment_id)
AS
SELECT user_id, assignment_id 
  FROM lego_secure_inv_assgnmt
/

CREATE OR REPLACE FORCE VIEW lego_secure_inv_prj_agr_vw
  (user_id, project_agreement_id)
AS
SELECT user_id, project_agreement_id 
  FROM lego_secure_inv_prj_agr
/

CREATE OR REPLACE FORCE VIEW lego_secure_inv_both_vw
  (user_id, contract_id)
AS
SELECT user_id, 
       assignment_id        AS contract_id 
  FROM lego_secure_inv_assgnmt
 WHERE assignment_id <> -1 
 UNION ALL  
SELECT user_id, 
       project_agreement_id AS contract_id 
  FROM lego_secure_inv_prj_agr
 WHERE project_agreement_id <> -1 
/


