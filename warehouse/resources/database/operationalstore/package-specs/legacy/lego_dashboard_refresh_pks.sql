CREATE OR REPLACE PACKAGE lego_dashboard_refresh AS
  /******************************************************************************
     NAME:       lego_dashboard_refresh
     PURPOSE:    Build tables and processes associated with the dashboards
                 used by Falcon.
  
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     IQN-29295  11/20/2015  Paul Muller      Created this package.
                04/22/2016  Paul Muller      modifications for mart
     
  ******************************************************************************/

  PROCEDURE load_upcoming_ends_detail(pi_table_name  IN VARCHAR2,
                                      pi_source_name IN VARCHAR2,
                                      pi_source_scn  IN VARCHAR2);

  PROCEDURE load_upcoming_ends_row_rollup(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2);

  PROCEDURE load_upcoming_ends_org_rollup(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2);

  ----------------------------------------------------------------------------------
  PROCEDURE load_req_by_status_detail(pi_table_name  IN VARCHAR2,
                                      pi_source_name IN VARCHAR2,
                                      pi_source_scn  IN VARCHAR2);

  PROCEDURE load_req_by_status_row_rollup(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2);

  PROCEDURE load_req_by_status_org_rollup(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2);

  ----------------------------------------------------------------------------------
  PROCEDURE load_monthly_assignment_list(pi_table_name  IN VARCHAR2,
                                         pi_source_name IN VARCHAR2,
                                         pi_source_scn  IN VARCHAR2);

  ----------------------------------------------------------------------------------
  PROCEDURE month_assgn_list_spend_detail(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2);

  PROCEDURE month_asgn_cnt_spnd_row_rollup(pi_table_name  IN VARCHAR2,
                                           pi_source_name IN VARCHAR2,
                                           pi_source_scn  IN VARCHAR2);

  PROCEDURE month_asgn_cnt_spnd_org_rollup(pi_table_name  IN VARCHAR2,
                                           pi_source_name IN VARCHAR2,
                                           pi_source_scn  IN VARCHAR2);
                                           
  ----------------------------------------------------------------------------------                                                                                  
  PROCEDURE load_assgn_atom_detail(pi_table_name  IN VARCHAR2,
                                   pi_source_name IN VARCHAR2,
                                   pi_source_scn  IN VARCHAR2);   

  PROCEDURE assgn_loc_cmsa_atom_or(pi_table_name  IN VARCHAR2,
                                   pi_source_name IN VARCHAR2,
                                   pi_source_scn  IN VARCHAR2);
                                   
  PROCEDURE assgn_loc_st_atom_or(pi_table_name  IN VARCHAR2,
                                 pi_source_name IN VARCHAR2,
                                 pi_source_scn  IN VARCHAR2);          

  PROCEDURE assgn_loc_st_atom_rr(pi_table_name  IN VARCHAR2,
                                 pi_source_name IN VARCHAR2,
                                 pi_source_scn  IN VARCHAR2);  

  PROCEDURE assgn_loc_cmsa_atom_rr(pi_table_name  IN VARCHAR2,
                                   pi_source_name IN VARCHAR2,
                                   pi_source_scn  IN VARCHAR2);                                 

END lego_dashboard_refresh;
/
