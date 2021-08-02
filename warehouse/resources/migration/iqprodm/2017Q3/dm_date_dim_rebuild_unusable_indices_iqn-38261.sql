BEGIN

  FOR i IN (SELECT 'ALTER INDEX '||index_name||' REBUILD ONLINE' AS rebuildit
              FROM user_indexes
             WHERE table_name = 'DM_DATE_DIM'
               AND status = 'UNUSABLE'
             ORDER BY index_name)
  LOOP
  
  EXECUTE IMMEDIATE i.rebuildit;
  
  END LOOP;

END;
/