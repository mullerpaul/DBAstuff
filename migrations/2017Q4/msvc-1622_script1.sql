DECLARE
  le_col_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_col_exists, -1430);

BEGIN
  EXECUTE IMMEDIATE('ALTER TABLE SUPPLIER_RELEASE ADD ( DATABASE_NAME VARCHAR2(128) )');

EXCEPTION
  WHEN le_col_exists THEN
    NULL;

END;
/

COMMENT ON COLUMN SUPPLIER_RELEASE.DATABASE_NAME 
	IS 'This column contains the Beeline site where the data is pulled from. In Beeline, same client could reside on multiple lower environment sites. This field could distinguish which site it came from.'
/

