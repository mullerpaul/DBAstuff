DECLARE
  lv_lego_name lego_refresh.object_name%TYPE := 'LEGO_ORG_SECURITY';
  lv_table_1   VARCHAR2(30);
  lv_table_2   VARCHAR2(30);
  lv_synonym   VARCHAR2(30);

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('migration script - remove_org_security_lego');
  logger_pkg.set_code_location('dropping objects');

  SELECT refresh_object_name_1, refresh_object_name_2, synonym_name
    INTO lv_table_1, lv_table_2, lv_synonym
    FROM lego_refresh a
   WHERE object_name = lv_lego_name
     AND source_name = 'USPROD';

  logger_pkg.info('dropping tables ' || lv_table_1 || ' ' || lv_table_2 || ' and synonym ' || lv_synonym);
  BEGIN
    EXECUTE IMMEDIATE ('drop table ' || lv_table_1);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  BEGIN
    EXECUTE IMMEDIATE ('drop table ' || lv_table_2);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  BEGIN
    EXECUTE IMMEDIATE ('drop synonym ' || lv_synonym);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  logger_pkg.info('dropping tables ' || lv_table_1 || ' ' || lv_table_2 || ' and synonym ' || lv_synonym ||
                  ' - complete!',
                  TRUE);

  logger_pkg.set_code_location('deleting metadata');
  logger_pkg.info('deleting from lego_refresh_index and lego_refresh');
  DELETE FROM lego_refresh_index WHERE object_name = lv_lego_name;
  DELETE FROM lego_refresh WHERE object_name = lv_lego_name;
  COMMIT;
  logger_pkg.info('deleting from lego_refresh_index and lego_refresh - complete', TRUE);

  logger_pkg.unset_source('migration script - remove_org_security_lego');

END;
/
