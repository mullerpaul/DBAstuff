/* Joe Pullifrone 
   04/28/2017
   IQN-37523

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE lego_refresh_toggle_priv PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE lego_refresh_toggle_priv (
  object_name        VARCHAR2(30),
  source_name        VARCHAR2(6),
  grantee_user_name  VARCHAR2(30),
  grant_option       NUMBER(1)
  )
/
ALTER TABLE lego_refresh_toggle_priv 
  ADD CONSTRAINT lego_refresh_toggle_priv_pk PRIMARY KEY (object_name, source_name, grantee_user_name)
/

ALTER TABLE lego_refresh_toggle_priv 
  ADD CONSTRAINT lego_refresh_toggle_priv_fk01 FOREIGN KEY (object_name, source_name)
    REFERENCES lego_refresh (object_name, source_name)
/




