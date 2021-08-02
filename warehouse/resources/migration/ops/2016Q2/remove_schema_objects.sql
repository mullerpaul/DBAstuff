-- We deployed a few objects to OPS instead of API in a few databases.
-- this script will drop the objects in those environments
-- and do nothing in other environments

BEGIN
  EXECUTE IMMEDIATE ('DROP PACKAGE dashboard_data_api');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE ('DROP TABLE dashboard_api_calls PURGE');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/

