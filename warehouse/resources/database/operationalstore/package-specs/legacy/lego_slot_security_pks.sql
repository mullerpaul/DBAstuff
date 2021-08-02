CREATE OR REPLACE PACKAGE lego_slot_security AS
/******************************************************************************
   NAME:       lego_slot_security
   PURPOSE:    Build tables and processes associated with the slot security 
               Legos used by Jasper.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   IQN-17904  07/23/2014  Paul Muller      Created this package.
   
******************************************************************************/

  PROCEDURE load_lego_job_managed_cac(p_table_name IN VARCHAR2);

  PROCEDURE load_lego_assign_managed_cac(p_table_name IN VARCHAR2);

  PROCEDURE load_lego_pa_managed_cac(p_table_name IN VARCHAR2);

  PROCEDURE load_lego_expense_managed_cac(pi_refresh_table_name IN VARCHAR2);

  PROCEDURE load_lego_timecard_managed_cac(pi_refresh_table_name IN VARCHAR2);

  PROCEDURE load_lego_slot_assignment (pi_refresh_table_name IN VARCHAR2);

  PROCEDURE load_lego_slot_job (pi_refresh_table_name IN VARCHAR2);
    
  PROCEDURE load_lego_slot_proj_agreement (pi_refresh_table_name IN VARCHAR2);

  PROCEDURE load_lego_slot_expense_report (pi_refresh_table_name IN VARCHAR2);
    
  PROCEDURE load_lego_slot_timecard (pi_refresh_table_name IN VARCHAR2);

  PROCEDURE load_lego_secure_inv_assgnmt (pi_refresh_table_name IN VARCHAR2);
  
  PROCEDURE load_lego_secure_inv_prj_agr (pi_refresh_table_name IN VARCHAR2);

END lego_slot_security;
/

