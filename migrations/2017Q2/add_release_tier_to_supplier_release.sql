ALTER TABLE supplier_release ADD (release_tier NUMBER)
/
COMMENT ON COLUMN supplier_release.release_tier 
IS 'Number indicating the order in which suppliers recieved the requisition.  NULL indicates supplier tiering was not used, or the info could not be found'
/

