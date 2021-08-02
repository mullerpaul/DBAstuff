CREATE OR REPLACE PACKAGE BODY lego_row_security AS
/******************************************************************************
   NAME:       lego_row_security
   PURPOSE:    Build tables and processes associated with the row-level security 
               Legos used by dashboards.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   IQN-17904  07/23/2014  Paul Muller      Created this package.
              04/20/2016  Paul Muller      renamed package and two of the procedures.
                                           Broke the %_MANAGED_CAC legos into two legos.
                                           Also added source parameter on all procs.
******************************************************************************/

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_assign_managed_cac(pi_table_name  IN VARCHAR2,
                                         pi_source_name IN VARCHAR2,
                                         pi_source_scn  IN VARCHAR2) AS
  
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_assign_managed_cac
    || AUTHOR               : Erik Clark
    || DATE CREATED         : 09/25/2013
    || PURPOSE              : This builds the LEGO_ASSIGN_MANAGED_CAC object used to report Managed CAC Records
    ||                      : in the ASSIGNMENT domain
    || MODIFICATION HISTORY : 07/16/2014 - pmuller - total rewrite - 12.1.2.  
    ||                      : Made this dependant on the new LEGO_MANAGED_CAC, LEGO_ASSIGNMENT_VW view, and the FO tables.
    ||                      : Also moved it into group 2 with other security legos.
    ||                      : 04/20/2016 - pmuller - changes for datamart.  Also removed dependency on LEGO_ASSIGNMENT.
    \*---------------------------------------------------------------------------*/
  
    /* LEGO_ASSIGN_MANAGED_CAC contains a mapping of person IDs to the assignments which they can see 
    based on the managed CAC heirarchy.  If a person manages a CAC on an assignment, then they can 
    view the assignment.   */
    
    lv_managed_cac_table    VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_MANAGED_CAC', 
                                                                                    i_source_name => pi_source_name);
    lv_assignment_cac_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_ASSIGNMENT_CAC_MAP', 
                                                                                    i_source_name => pi_source_name);

    lv_sql   VARCHAR2(1000) := 
    'SELECT mc.user_id, ctk.assignment_continuity_id ' ||
    '  FROM ' || lv_assignment_cac_table || ' ctk, ' ||
            lv_managed_cac_table || ' mc ' ||
    ' WHERE mc.cac_value_id = ctk.cac_value_id';
  
  BEGIN
    lego_refresh_mgr_pkg.ctas
       (pi_table_name       => pi_table_name,
        pi_stmt_clob        => lv_sql,
        pi_partition_clause => lego_tools.get_partition_clause
                                  (fi_object_name => 'LEGO_ASSIGN_MANAGED_CAC',
                                   fi_source_name => pi_source_name),
        pi_storage_clause   => lego_tools.get_storage_clause
                                  (fi_object_name => 'LEGO_ASSIGN_MANAGED_CAC',
                                   fi_source_name => pi_source_name));

  END load_lego_assign_managed_cac;

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_job_managed_cac(pi_table_name  IN VARCHAR2,
                                      pi_source_name IN VARCHAR2,
                                      pi_source_scn  IN VARCHAR2) AS
  /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_job_managed_cac
    || AUTHOR               : Erik Clark
    || DATE CREATED         : 09/25/2013
    || PURPOSE              : This builds the LEGO_JOB_MANAGED_CAC object used to report Managed CAC Records
    ||                      : in the JOB domain
    || MODIFICATION HISTORY : 07/16/2014 - pmuller - total rewrite - 12.1.2.  
    ||                      : Made this dependant on the new LEGO_MANAGED_CAC, LEGO_JOB, and the FO tables.
    ||                      : Also moved it into group 2 with other security legos.
    ||                      : 04/20/2016 - pmuller - changes for datamart.  Also removed dependency on LEGO_ASSIGNMENT.
    \*---------------------------------------------------------------------------*/
  
    lv_managed_cac_table  VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_MANAGED_CAC', 
                                                                                i_source_name => pi_source_name);
    lv_job_cac_table      VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_JOB_CAC_MAP', 
                                                                                i_source_name => pi_source_name);

    lv_sql   VARCHAR2(1000) := 
    'SELECT mc.user_id, ctk.job_id' ||
    '  FROM ' || lv_job_cac_table || ' ctk, ' ||
            lv_managed_cac_table || ' mc ' ||
    ' WHERE mc.cac_value_id = ctk.cac_value_id';
  
  BEGIN
    lego_refresh_mgr_pkg.ctas
       (pi_table_name       => pi_table_name,
        pi_stmt_clob        => lv_sql,
        pi_partition_clause => lego_tools.get_partition_clause
                                  (fi_object_name => 'LEGO_JOB_MANAGED_CAC',
                                   fi_source_name => pi_source_name),
        pi_storage_clause   => lego_tools.get_storage_clause
                                  (fi_object_name => 'LEGO_JOB_MANAGED_CAC',
                                   fi_source_name => pi_source_name));

  END load_lego_job_managed_cac;
  
  ----------------------------------------------------------------------------------
  PROCEDURE load_assignment_row_security (pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2) AS
    /* pi_source_scn is not actually used; but we need to accept it because of
       the way the refresh manager handles procedureal toggle legos. */                                          

    /*---------------------------------------------------------------------------*\
    || AUTHOR               : Paul Muller
    || DATE CREATED         : July 22nd, 2014
    || PURPOSE              : This procedure creates lego_slot_assignment
    || MODIFICATION HISTORY : 07/22/2014 - pmuller - initial build. 12.1.2
    ||                      : 04/20/2016 - pmuller - renamed from load_lego_slot_assignment             
    \*---------------------------------------------------------------------------*/

    lv_managed_person_base_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_MANAGED_PERSON', 
                                                                                       i_source_name => pi_source_name);
    lv_managed_cac_base_table    VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_ASSIGN_MANAGED_CAC', 
                                                                                       i_source_name => pi_source_name);
    lv_assignment_base_table     VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_ASSIGNMENT_SLOTS', 
                                                                                       i_source_name => pi_source_name);

    /* May want to experiment with replacing UNION ALL & DISTINCT with just a UNION.  */
    lv_sql                       VARCHAR2(4000) := q'{SELECT DISTINCT login_user_id, assignment_id
  FROM (SELECT lmp.manager_person_id AS login_user_id, 
               lsa.assignment_id
          FROM }' || lv_managed_person_base_table || ' lmp, ' ||
               lv_assignment_base_table || q'{ lsa
         WHERE lmp.employee_person_id = lsa.user_id
         UNION ALL
        SELECT amc.user_id AS login_user_id, 
               amc.assignment_continuity_id AS assignment_id
          FROM }' || lv_managed_cac_base_table || ' amc)';

  BEGIN
    lego_refresh_mgr_pkg.ctas
       (pi_table_name       => pi_table_name,
        pi_stmt_clob        => lv_sql,
        pi_partition_clause => lego_tools.get_partition_clause
                                  (fi_object_name => 'LEGO_ASSIGNMENT_ROW_SECURITY',
                                   fi_source_name => pi_source_name),
        pi_storage_clause   => lego_tools.get_storage_clause
                                  (fi_object_name => 'LEGO_ASSIGNMENT_ROW_SECURITY',
                                   fi_source_name => pi_source_name));

  END load_assignment_row_security ;
    
  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_job_row_security (pi_table_name  IN VARCHAR2,
                                        pi_source_name IN VARCHAR2,
                                        pi_source_scn  IN VARCHAR2) AS
    /* pi_source_scn is not actually used; but we need to accept it because of
       the way the refresh manager handles procedureal toggle legos. */                                          
    /*---------------------------------------------------------------------------*\
    || AUTHOR               : Paul Muller
    || DATE CREATED         : July 22nd, 2014
    || PURPOSE              : This procedure creates lego_slot_job
    || MODIFICATION HISTORY : 07/22/2014 - pmuller - initial build. 12.1.2
    ||                      : 04/20/2016 - pmuller - renamed from load_lego_slot_job             
    \*---------------------------------------------------------------------------*/

    lv_managed_person_base_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_MANAGED_PERSON', 
                                                                                       i_source_name => pi_source_name);
    lv_managed_cac_base_table    VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_JOB_MANAGED_CAC', 
                                                                                       i_source_name => pi_source_name);
    lv_job_base_table            VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name   => 'LEGO_JOB_SLOTS', 
                                                                                       i_source_name => pi_source_name);

    /* May want to experiment with replacing UNION ALL & DISTINCT with just a UNION. */
    lv_sql                       VARCHAR2(4000) := q'{SELECT DISTINCT login_user_id, job_id
  FROM (SELECT lmp.manager_person_id AS login_user_id, 
               lsj.job_id
          FROM }' || lv_managed_person_base_table || ' lmp, ' ||
               lv_job_base_table || q'{ lsj
         WHERE lmp.employee_person_id = lsj.user_id
         UNION ALL
        SELECT jmc.user_id AS login_user_id, 
               jmc.job_id
          FROM }' || lv_managed_cac_base_table || ' jmc)';

  BEGIN
    lego_refresh_mgr_pkg.ctas
       (pi_table_name       => pi_table_name,
        pi_stmt_clob        => lv_sql,
        pi_partition_clause => lego_tools.get_partition_clause
                                  (fi_object_name => 'LEGO_JOB_ROW_SECURITY',
                                   fi_source_name => pi_source_name),
        pi_storage_clause   => lego_tools.get_storage_clause
                                  (fi_object_name => 'LEGO_JOB_ROW_SECURITY',
                                   fi_source_name => pi_source_name));

  END load_lego_job_row_security ;
    
END lego_row_security;
/
