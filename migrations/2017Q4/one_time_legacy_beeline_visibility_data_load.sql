-- One time load of existing client_guid data into visibility table.

-- We load any existing client_guids into a row as BOTH the login_guid AND
-- the visibile_guid.  This allows us to use this table as a join-through. 
MERGE INTO client_visibility_list t
USING (SELECT DISTINCT client_guid
         FROM supplier_release
        WHERE legacy_source_vms = 'Beeline') s
   ON (t.log_in_client_guid = s.client_guid AND
       t.visible_client_guid = s.client_guid)
 WHEN NOT MATCHED THEN 
INSERT (log_in_client_guid, visible_client_guid)
VALUES (client_guid, client_guid)
/

COMMIT
/

