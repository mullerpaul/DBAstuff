DECLARE
  lv_no_such_view EXCEPTION;
  PRAGMA EXCEPTION_INIT(lv_no_such_view, -942);

BEGIN
  /* wrapping these drops with error handlers in case we run from 
     scratch in a new database (for example a dev laptop db)  */
  BEGIN
    EXECUTE IMMEDIATE ('DROP VIEW lego_mnth_asgn_lst_spnd_det_vw');
  EXCEPTION
    WHEN lv_no_such_view THEN
      NULL;
  END;

  BEGIN
    EXECUTE IMMEDIATE ('DROP VIEW lego_req_by_status_detail_vw');
  EXCEPTION
    WHEN lv_no_such_view THEN
      NULL;
  END;

  BEGIN
    EXECUTE IMMEDIATE ('DROP VIEW lego_upcoming_ends_detail_vw');
  EXCEPTION
    WHEN lv_no_such_view THEN
      NULL;
  END;

END;
/
