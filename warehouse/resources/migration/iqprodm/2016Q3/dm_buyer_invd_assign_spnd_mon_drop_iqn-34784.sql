--IQN-34784
--jpullifrone
--09/26/2016
--Changing this to Fast Refresh MV and putting in OPERATIONALSTORE schema
BEGIN
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW dm_buyer_invd_assign_spnd_mon';
EXCEPTION 
  WHEN OTHERS THEN NULL;
END;
/