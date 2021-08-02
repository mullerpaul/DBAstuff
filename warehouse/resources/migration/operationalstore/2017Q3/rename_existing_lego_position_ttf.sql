/*
IQN-37567

05/04/2017

Dropping all of this and so we can rename it.
*/

DECLARE

  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_POSITION_TIME_TO_FILL';
  lv_syn_name    lego_refresh.synonym_name%TYPE := REPLACE(lv_object_name, 'LEGO_') || '_IQP';
  
BEGIN

  DELETE FROM lego_refresh
   WHERE object_name = lv_object_name;  

  DELETE FROM lego_refresh_history
    WHERE object_name = lv_object_name;

  COMMIT;
  
  BEGIN

    EXECUTE IMMEDIATE 'DROP SYNONYM '||lv_syn_name;

  EXCEPTION
    WHEN OTHERS THEN 
      NULL;
  END;
  
  BEGIN

    EXECUTE IMMEDIATE 'DROP TABLE '||lv_syn_name||'1 PURGE';

  EXCEPTION
    WHEN OTHERS THEN 
      NULL;
  END;

    BEGIN

    EXECUTE IMMEDIATE 'DROP TABLE '||lv_syn_name||'2 PURGE';

  EXCEPTION
    WHEN OTHERS THEN 
      NULL;
  END;
  
  lv_syn_name := REPLACE(lv_object_name, 'LEGO_') || '_WF';
  
  BEGIN

    EXECUTE IMMEDIATE 'DROP SYNONYM '||lv_syn_name;

  EXCEPTION
    WHEN OTHERS THEN 
      NULL;
  END;
  
  BEGIN

    EXECUTE IMMEDIATE 'DROP TABLE '||lv_syn_name||'1 PURGE';

  EXCEPTION
    WHEN OTHERS THEN 
      NULL;
  END;

    BEGIN

    EXECUTE IMMEDIATE 'DROP TABLE '||lv_syn_name||'2 PURGE';

  EXCEPTION
    WHEN OTHERS THEN 
      NULL;
  END;  

END;
/