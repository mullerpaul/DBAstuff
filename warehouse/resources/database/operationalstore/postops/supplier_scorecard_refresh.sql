--changes made for IQN-38381 necessitate a one-time refresh 
BEGIN 
  lego_refresh_mgr_pkg.refresh('LEGO_SUPPLIER_SCORECARD','USPROD'); 
END;
/