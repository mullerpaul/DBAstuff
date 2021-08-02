/* Joe Pullifrone 
   04/28/2017
   IQN-37523

*/

INSERT INTO lego_refresh_toggle_priv (object_name, source_name, grantee_user_name, grant_option)
     VALUES ('LEGO_BUS_ORG','USPROD','FINANCE',1)
/
INSERT INTO lego_refresh_toggle_priv (object_name, source_name, grantee_user_name, grant_option)
     VALUES ('LEGO_CAC_COLLECTION_CURRENT','USPROD','FINANCE',1)
/
INSERT INTO lego_refresh_toggle_priv (object_name, source_name, grantee_user_name, grant_option)
     VALUES ('LEGO_CAC_CURRENT','USPROD','FINANCE',1)
/
INSERT INTO lego_refresh_toggle_priv (object_name, source_name, grantee_user_name, grant_option)
     VALUES ('LEGO_INVOICE','USPROD','FINANCE',1)
/
COMMIT
/


