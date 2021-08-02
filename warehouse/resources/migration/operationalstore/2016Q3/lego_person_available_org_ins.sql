/*******************************************************************************
SCRIPT NAME         lego_person_available_orgs_ins.sql 
 
LEGO OBJECT NAME    LEGO_PERSON_AVAILABLE_ORG
SOURCE NAME         USPROD
 
CREATED             08/01/2016
 
ORIGINAL AUTHOR     Paul Muller
  
*******************************************************************************/

DECLARE
  v_source        VARCHAR2(64) := 'lego_person_available_orgs_ins.sql';
  lv_next_refresh lego_refresh.refresh_on_or_after_time%TYPE;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source(v_source);

  logger_pkg.set_code_location('finding next refresh time');
  logger_pkg.info('finding next refresh time for LEGO_PERSON_AVAILABLE_ORG by copying it from LEGO_MANAGED_PERSON');
  BEGIN
    SELECT refresh_on_or_after_time
      INTO lv_next_refresh
      FROM lego_refresh
     WHERE source_name = 'USPROD'
       AND object_name = 'LEGO_MANAGED_PERSON';
  EXCEPTION
    WHEN no_data_found THEN
      lv_next_refresh := NULL;
  END;

  logger_pkg.set_code_location('Inserting new Refresh SQL for LEGO_PERSON_AVAILABLE_ORG, source USPROD');
  logger_pkg.info('Begin - INSERTING INTO LEGO_REFRESH');

  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     refresh_on_or_after_time,
     storage_clause,
     refresh_sql,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    ('LEGO_PERSON_AVAILABLE_ORG',
     'USPROD',
     'SQL TOGGLE',
     'TWICE DAILY',
     2,
     1,
     lv_next_refresh,
     'NOLOGGING',
     'x',
     'PERSON_AVAILABLE_ORG_IQP1',
     'PERSON_AVAILABLE_ORG_IQP2',
     'PERSON_AVAILABLE_ORG');

  COMMIT;

  logger_pkg.info('Insert Complete', TRUE);

  logger_pkg.set_code_location('Creating dummy table and synonym');
  logger_pkg.info('Creating dummy table and synonym - just in case!');
  BEGIN
    EXECUTE IMMEDIATE ('CREATE TABLE person_available_org_iqp1 (login_user_id NUMBER, login_org_id NUMBER, available_org_id NUMBER)');
    EXECUTE IMMEDIATE ('CREATE OR REPLACE SYNONYM person_available_org FOR person_available_org_iqp1');
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.warn('Could not create dummy table and synonym.  ' || SQLERRM);
  END;

  logger_pkg.info('Creating dummy table and synonym - done', TRUE);
  logger_pkg.unset_source(v_source);

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                     pi_error_code         => SQLCODE,
                     pi_message            => 'Error inserting new Refresh SQL for LEGO_PERSON_AVAILABLE_ORGS, source USPROD - ' ||
                                              SQLERRM,
                     pi_update_log         => TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;
  
END;
/
