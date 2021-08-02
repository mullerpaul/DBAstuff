CREATE OR REPLACE PACKAGE lego_row_security AS
  /******************************************************************************
     NAME:       lego_row_security
     PURPOSE:    Build tables and processes associated with the row-level security 
                 Legos used by dashboards.
  
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     IQN-17904  07/23/2014  Paul Muller      Created this package.
                04/20/2016  Paul Muller      Renamed from lego_slot_security and removed
                                             procedures we don't need in mart.
  ******************************************************************************/

  PROCEDURE load_lego_assign_managed_cac(pi_table_name  IN VARCHAR2,
                                         pi_source_name IN VARCHAR2,
                                         pi_source_scn  IN VARCHAR2);

  PROCEDURE load_lego_job_managed_cac(pi_table_name  IN VARCHAR2,
                                      pi_source_name IN VARCHAR2,
                                      pi_source_scn  IN VARCHAR2);

  PROCEDURE load_assignment_row_security(pi_table_name  IN VARCHAR2,
                                         pi_source_name IN VARCHAR2,
                                         pi_source_scn  IN VARCHAR2);

  PROCEDURE load_lego_job_row_security(pi_table_name  IN VARCHAR2,
                                       pi_source_name IN VARCHAR2,
                                       pi_source_scn  IN VARCHAR2);

END lego_row_security;
/
