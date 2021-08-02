CREATE GLOBAL TEMPORARY TABLE client_visibility_list_gtt
  (log_in_client_guid  RAW(16) NOT NULL,
   visible_client_guid RAW(16) NOT NULL)
ON COMMIT PRESERVE ROWS
/


