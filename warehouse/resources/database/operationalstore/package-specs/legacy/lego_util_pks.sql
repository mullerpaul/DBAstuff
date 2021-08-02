CREATE OR REPLACE PACKAGE lego_util
AS

/*******************************************************************************
 *PACKAGE NAME : lego_util
 *DATE CREATED : October 9, 2012
 *PURPOSE      : package for lego-related data loads.
 ******************************************************************************/

  PROCEDURE remove_invoice_data (i_invoice_id            NUMBER,
                                 i_current_invoice_date  DATE);
  
  FUNCTION most_recently_loaded_table(i_lego_name lego_refresh.object_name%TYPE)
    RETURN VARCHAR2;
    
  FUNCTION get_exadata_storage_clause(i_lego_name lego_refresh.object_name%TYPE)
    RETURN VARCHAR2;     

  FUNCTION get_partition_clause(i_lego_name lego_refresh.object_name%TYPE)
    RETURN VARCHAR2;     

  PROCEDURE load_lego_inv_det_worker (i_is_init_load     CHAR     DEFAULT 'N',
                                      i_date_range_min   DATE     DEFAULT NULL,
                                      i_date_range_max   DATE     DEFAULT NULL,
                                      i_lego_invoice_2   VARCHAR2 DEFAULT NULL,
                                      i_lego_object_name VARCHAR2,
                                      i_job_runtime      TIMESTAMP);  
  
  PROCEDURE load_lego_invoice_detail (i_is_init_load CHAR DEFAULT 'N');

  PROCEDURE upd_lego_assignment_cac;
  
  PROCEDURE upd_lego_job_cancel_tmp;

  PROCEDURE load_lego_rfx_cac (p_table_name IN VARCHAR2);

  PROCEDURE load_lego_proj_agreement_pay (p_table_name IN VARCHAR2);
  
  PROCEDURE load_lego_pa_geo_desc (p_table_name IN VARCHAR2);

  PROCEDURE load_lego_payment_request (p_table_name IN VARCHAR2);
  
  PROCEDURE load_lego_missing_time (p_table_name IN VARCHAR2);
  
  PROCEDURE load_lego_timecard_init;

  PROCEDURE load_lego_timecard_future;

  PROCEDURE load_lego_timecard (p_release_sql OUT VARCHAR2);
  
  PROCEDURE lego_address_refresh;

  PROCEDURE load_lego_address_init;

  PROCEDURE load_lego_contact_address_init;
	
  PROCEDURE load_lego_contact_gtt_init;

  PROCEDURE load_lego_cac_init;

  PROCEDURE load_lego_cac_collection_init;
  
  PROCEDURE load_lego_cacs_refresh;
  
  PROCEDURE load_lego_time_to_fill (p_table_name IN VARCHAR2);
  
  PROCEDURE load_lego_approvals_init;
  
  PROCEDURE load_lego_approvals_refresh;  
  
  PROCEDURE load_lego_tenure (pi_refresh_table_name IN VARCHAR2);
  
  PROCEDURE load_candidate_search_index;
  
END lego_util;
/
