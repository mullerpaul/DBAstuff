--- update Beeline rows
UPDATE client_visibility_list
   SET score_config_owner_guid = visible_client_guid
 WHERE visible_client_guid in (SELECT client_guid FROM supplier_release
                                WHERE legacy_source_vms = 'Beeline')
/

-- Update IQN rows
UPDATE client_visibility_list T
   SET score_config_owner_guid = (SELECT enterprise_bus_org_guid
                                    FROM operationalstore.bus_org_iqp b
                                   WHERE b.bus_org_guid = t.log_in_client_guid) 
 WHERE score_config_owner_guid IS NULL
/

COMMIT
/