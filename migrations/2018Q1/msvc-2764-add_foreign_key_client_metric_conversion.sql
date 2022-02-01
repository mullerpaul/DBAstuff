ALTER TABLE SUPPLIER_SCORECARD.CLIENT_METRIC_CONVERSION ADD (
  CONSTRAINT CLIENT_METRIC_CONVERSION_FK01 
  FOREIGN KEY (METRIC_ID) 
  REFERENCES SUPPLIER_SCORECARD.METRIC (METRIC_ID)
  ENABLE VALIDATE)
/