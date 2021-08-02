DECLARE
  lv_object_name   lego_refresh.object_name%TYPE := 'LEGO_BLONE_LINKED_FO_ACCOUNT';
  lv_synonym_name  VARCHAR2(29)                  := 'BLONE_LINKED_FO_ACCOUNT_HOR';

BEGIN

  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    (lv_object_name,
     'HORIZON',
     'SQL TOGGLE',
     'NOLOGGING',
     lv_synonym_name || '1',
     lv_synonym_name || '2',
     lv_synonym_name);

  COMMIT;

  /* Dummy table and synonym so that converence_search load package can compile before next refresh. */
  EXECUTE IMMEDIATE 'create table ' || lv_synonym_name || '1' || 
                    q'{  as SELECT sys_guid()  AS one_service_guid,
                                   'abc'       AS name,
                                   'abc'       AS provider,
                                   sys_guid()  AS account_service_guid,
                                   'abc'       AS account_id,
                                   'abc'       AS service_user_name,
                                   'abc'       AS service_user_domain
                              FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_synonym_name || 
                    ' for ' || lv_synonym_name || '1';

END;
/

