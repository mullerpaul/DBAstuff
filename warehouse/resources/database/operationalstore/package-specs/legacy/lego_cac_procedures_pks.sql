CREATE OR REPLACE PACKAGE lego_cac_procedures AS
  /******************************************************************************
     NAME:       lego_cac_procedures
     PURPOSE:    Code to refresh LEGO_CAC_HISTORY and LEGO_CAC_COLLECTION_HISTORY.
                 
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
                08/30/2016  Paul Muller      Uses a CDC snapshot process to get CAC
                                             data from Legacy IQPRODD legos.  A new 
                                             record is inserted for new or updated 
                                             data.   
  ******************************************************************************/

  PROCEDURE load_cac_history(pi_obj_name IN lego_refresh.object_name%TYPE,
                             pi_source   IN lego_refresh.source_name%TYPE);

  PROCEDURE load_cac_collection_history(pi_obj_name IN lego_refresh.object_name%TYPE,
                                        pi_source   IN lego_refresh.source_name%TYPE);

END lego_cac_procedures;
/
