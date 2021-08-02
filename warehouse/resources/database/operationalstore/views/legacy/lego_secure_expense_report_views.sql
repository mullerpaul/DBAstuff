CREATE OR REPLACE FORCE VIEW lego_secure_expense_report_vw
  (user_id, 
   expense_report_id)
AS
SELECT user_id, expense_report_id
  FROM lego_slot_expense_report
/


