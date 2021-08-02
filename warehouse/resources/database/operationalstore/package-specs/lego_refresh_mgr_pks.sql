CREATE OR REPLACE PACKAGE lego_refresh_mgr_pkg AUTHID DEFINER AS
  /******************************************************************************
     NAME:       LEGO_REFRESH_MGR_PKG
     PURPOSE:    To manage refresh of LEGO objects.
  
     REVISIONS:
     Ver     Date        Author        Description
     ------  ----------  ------------  ------------------------------------
     1.0     8/15/2012   jlooney       Created this package.
     2.0     11/08/2012  pmuller       Modified package to support multi-threaded 
                                       execution, syncronized refreshes, and syncronized 
                                       releases.
     2.1     02/26/2013  pmuller       Added procedures for operational administration.
     2.2     09/11/2013  jpullifrone   Added procedure, run_lego_refresh_stats.
     2.3     10/15/2013  jpullifrone   Added procedure, refresh_incremental_lego.
     2.4     06/03/2016  jpullifrone   IQN-32537, remove 1/2 pass and release logic.
     4.0     09/12/2018  pmuller       IQN-40224. Removed refresh groups and automatic scheduling.
                                       Removed the refresh entrypoints since they are now obsolete.
                                       Also removed the lego_refresh_stats procedure since it hasn't 
                                       been used in a few years.
  ******************************************************************************/

  /* ToDo - Do we really need the two get% functions and the ctas proc to be public??
     Investigate and remove from the public spec (and body too) if possible.  */
  --------------------------------------------------------------------------------
  FUNCTION get_lego_parameter_text_value(pi_parameter_name IN VARCHAR2)
    RETURN VARCHAR2;

  --------------------------------------------------------------------------------
  FUNCTION get_lego_parameter_num_value(pi_parameter_name IN VARCHAR2)
    RETURN VARCHAR2;

  --------------------------------------------------------------------------------
  PROCEDURE ctas(pi_table_name         IN VARCHAR2,
                 pi_stmt_clob          IN CLOB,
                 pi_storage_clause     IN VARCHAR2 DEFAULT NULL,
                 pi_partition_clause   IN VARCHAR2 DEFAULT NULL);

  --------------------------------------------------------------------------------
  PROCEDURE refresh_object(pi_refresh_object IN lego_refresh.object_name%TYPE,
                           pi_source         IN lego_refresh.source_name%TYPE,
                           pi_runtime        IN TIMESTAMP,
                           pi_refresh_scn    IN NUMBER);

  --------------------------------------------------------------------------------
  PROCEDURE refresh_incremental_lego (pi_scheduler_job_name       VARCHAR2,
                                      pi_current_table_name       VARCHAR2,
                                      pi_old_table_name           VARCHAR2,
                                      pi_synonym_name             VARCHAR2,                                                                            
                                      pi_create_new_table_text    CLOB,
                                      pi_proc_call_for_data_load  VARCHAR2,    
                                      pi_start_date               TIMESTAMP WITH TIME ZONE,
                                      pi_drop_old_table           CHAR      DEFAULT 'Y',
                                      pi_is_retry                 CHAR      DEFAULT 'N');                           

END lego_refresh_mgr_pkg;
/
