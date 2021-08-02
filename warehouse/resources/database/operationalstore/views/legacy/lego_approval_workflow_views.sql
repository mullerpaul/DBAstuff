CREATE OR REPLACE FORCE VIEW  lego_approval_workflow_vw 
AS 
SELECT BUYER_ORG_ID,
       is_active,
        approval_workflow_name,
        responsibility_name,
        approver_id,
        approval_type,
        approval_spend_limit
FROM lego_approval_workflow
/
