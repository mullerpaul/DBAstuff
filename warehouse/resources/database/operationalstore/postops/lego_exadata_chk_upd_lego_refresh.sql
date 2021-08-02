/*******************************************************************************
 *DATE CREATED   : April 3, 2012
 *AUTHOR         : Joe Pullifrone
 *PURPOSE        : This script will check to see if it is running on a database
 *                 with Exadata.  If it is not then it will remove the Exadata
 *                 portion of the exadata_storage_clause from lego_refresh.  
 *MODIFICATIONS:
 ******************************************************************************/ 
DECLARE
  e_non_exadata          EXCEPTION;
  PRAGMA EXCEPTION_INIT (e_non_exadata, -64307);
  e_invalid_storage      EXCEPTION;
  PRAGMA EXCEPTION_INIT (e_invalid_storage, -02143);
  v_dummy_table_name     VARCHAR2(30) := 'sos_text_exadata';

BEGIN

  --check to see if this is an Exadata database by trying to create a dummy table
  BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE ' || v_dummy_table_name || ' COMPRESS FOR QUERY HIGH AS SELECT 1 dummy FROM dual';
    EXECUTE IMMEDIATE 'DROP TABLE ' || v_dummy_table_name;
    --this is an Exadata database so get the full storage clause
          
  EXCEPTION
    WHEN e_non_exadata OR e_invalid_storage THEN
      --this is NOT an Exadata database so strip out the Exadata storage portion of the clause
      UPDATE lego_refresh
         SET storage_clause =
             REPLACE(
                     REPLACE(
                             REPLACE(storage_clause, 'STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH'),
                                                     'STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY LOW'), 
                                                     'STORAGE (CELL_FLASH_CACHE KEEP)') 
       WHERE storage_clause LIKE '%STORAGE (CELL_FLASH_CACHE KEEP)%';  
	   
      COMMIT;     
  END;
  
END;
/

