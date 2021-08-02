INSERT INTO lego_object 
   VALUES ('LEGO_TIMECARD_ENTRY','USPROD','Holds timecard entry data but does not include rate information.','Y',SYSDATE)
/
INSERT INTO lego_object 
   VALUES ('LEGO_TIMECARD_ENTRY','WFPROD','Holds timecard entry data but does not include rate information.','Y',SYSDATE)
/
INSERT INTO lego_object 
   VALUES ('LEGO_TIMECARD_EVENT','USPROD','Holds timecard event data at the level of event_description in the FO.','Y',SYSDATE)
/
INSERT INTO lego_object 
   VALUES ('LEGO_TIMECARD_EVENT','WFPROD','Holds timecard event data at the level of event_description in the FO.','Y',SYSDATE)
/
COMMIT
/