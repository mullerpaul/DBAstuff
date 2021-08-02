DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-1667_load_legacy_beeline_viz_data_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_cnt_client_guid_data_table   PLS_INTEGER;
  lv_cnt_client_guid_new_table   PLS_INTEGER;
  
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('Check for Table');
  
  logger_pkg.info('Checking for table...');

  SELECT COUNT(distinct client_guid)
    INTO lv_cnt_client_guid_data_table
    FROM supplier_scorecard.supplier_release
    WHERE legacy_source_vms = 'Beeline';
	
  SELECT COUNT(distinct cvl.log_in_client_guid)
    INTO lv_cnt_client_guid_new_table
    FROM Supplier_Scorecard.Client_Visibility_List cvl, supplier_scorecard.supplier_release sr
    WHERE cvl.visible_client_guid = sr.client_guid
	AND sr.legacy_source_vms = 'Beeline';

  IF lv_cnt_client_guid_data_table <> lv_cnt_client_guid_new_table THEN
    lv_msg := 'Script msvc-1667_load_legacy_beeline_viz_data.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'Script msvc-1667_load_legacy_beeline_viz_data.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

