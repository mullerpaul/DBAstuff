CREATE OR REPLACE FORCE VIEW client_visibility_list_vw 
   AS  SELECT DISTINCT LOG_IN_CLIENT_GUID,
                                               SCORE_CONFIG_OWNER_GUID 
      FROM client_visibility_list
/