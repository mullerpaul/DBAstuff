--drop existing materialized view and log
DECLARE
  e_tbl_vw_does_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT (e_tbl_vw_does_not_exist, -942);
  e_mv_does_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT (e_mv_does_not_exist, -12003);  
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW LOG ON dm_invoiced_spend_all';
  EXCEPTION
    WHEN e_tbl_vw_does_not_exist
      THEN NULL;    --suppress "table or view does not exist" error
  END;
  BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW dm_buyer_invd_assign_spnd_mon';
  EXCEPTION
    WHEN e_mv_does_not_exist
      THEN NULL;    --suppress "table or view does not exist" error
  END;  
END;
/
