DECLARE
    lv_source     processing_log.source%TYPE := 'msvc-2695_client_metric_coeff_api_call_ut02.sql';
    lv_msg                 VARCHAR2(255);
    lc_dummy_client_guid   CONSTANT RAW(16) := hextoraw('ABCD000000000000000000000000ABCD');
    lv_txn_log_pk          RAW(16) := sys_guid;
    lv_cmc_pk              RAW(16) := sys_guid;
    lv_new_cat_coeff       PLS_INTEGER;
    
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2695_client_metric_coeff_api_call_ut02');
  
   
    INSERT INTO client_visibility_list ( 
		log_in_client_guid, 
		visible_client_guid,
		score_config_owner_guid ) 
    VALUES ( 
		lc_dummy_client_guid,
        lc_dummy_client_guid,
        lc_dummy_client_guid );

    INSERT INTO transaction_log (
        txn_guid,
        session_guid,
        request_guid,
        request_timestamp,
        processed_timestamp,
        bus_org_guid,
        entity_name,
        entity_guid_1) 
    VALUES (
        lv_txn_log_pk,
        sys_guid,
        sys_guid,
        systimestamp,
        systimestamp,
        lc_dummy_client_guid,
        'client_metric_coefficient',
        lv_cmc_pk);

	INSERT INTO client_metric_coefficient (
		client_metric_coefficient_guid,
		client_guid,
		metric_id,
		metric_coefficient,
		last_txn_guid,
		last_txn_date,
		effective_date )
	VALUES (
		lv_cmc_pk,
		lc_dummy_client_guid,
		12,
		10,
		lv_txn_log_pk,
		SYSDATE,
		SYSDATE);
		
		
		
-- call SET here

    client_metric_settings_util.set_client_metric_coefficient(lc_dummy_client_guid,
                                                               12,
                                                               5,
                                                               SYSDATE,
                                                              'datanauts',
                                                               sys_guid); 

-- SQL stetment here
    SELECT metric_coefficient
    INTO lv_new_cat_coeff
    FROM client_metric_coefficient
    WHERE
            client_guid = lc_dummy_client_guid
        AND
            termination_date IS NULL
        AND
            metric_id = 12;

-- remove data

    DELETE FROM client_visibility_list 
	WHERE log_in_client_guid = lc_dummy_client_guid;

    DELETE FROM client_metric_coefficient 
	WHERE client_guid = lc_dummy_client_guid;

    DELETE FROM transaction_log 
	WHERE bus_org_guid = lc_dummy_client_guid;

    COMMIT;
	
    IF lv_new_cat_coeff <> 5 THEN
    lv_msg := 'msvc-2695_client_metric_coeff_api_call_ut02 FAILED.';
    logger_pkg.info(lv_msg);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2695_client_metric_coeff_api_call_ut02 PASSED.';
  logger_pkg.info(lv_msg);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/