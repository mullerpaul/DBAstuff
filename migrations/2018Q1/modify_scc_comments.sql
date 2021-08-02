DECLARE
 ln_count number := 0;
BEGIN

    select count(1)
    into  ln_count
    from user_objects
   where object_name = 'SUPPLIER_SCORECARD_COMMENTS'
      and object_type = 'TABLE';

IF ln_count > 0 THEN
EXECUTE IMMEDIATE 'DROP TABLE SUPPLIER_SCORECARD_COMMENTS';
END IF;
END;
/
CREATE TABLE supplier_scorecard_comments (
  client_comment_guid  RAW(26) NOT NULL,
  client_guid                  RAW(16) NOT NULL,
  LAST_TXN_GUID                  RAW(16)        NOT NULL,
  LAST_TXN_DATE                  DATE           DEFAULT sys_extract_utc(systimestamp) NOT NULL,
  created_by_username   VARCHAR2(100 CHAR) ,
  comments             VARCHAR2(4000 CHAR),
  EFFECTIVE_DATE       DATE           NOT NULL,
  TERMINATION_DATE     DATE
)
/

ALTER TABLE supplier_scorecard_comments ADD CONSTRAINT ssc_comments_pk PRIMARY KEY (client_comment_guid)
/

ALTER TABLE supplier_scorecard_comments ADD (
  CONSTRAINT supplier_scorecard_cmnt_FK01 
  FOREIGN KEY (LAST_TXN_GUID) 
  REFERENCES TRANSACTION_LOG (TXN_GUID)
  ENABLE VALIDATE)
/