--------------------------------------------------------
--  DDL for Table DM_STD_SUB_CATEGORY
--------------------------------------------------------

CREATE TABLE DM_STD_SUB_CATEGORY
(STD_SUB_CATEGORY_ID NUMBER NOT NULL, 
 STD_SUB_CATEGORY_DESC VARCHAR2(255 BYTE) NOT NULL)
/
ALTER TABLE DM_STD_SUB_CATEGORY ADD CONSTRAINT DM_STD_SUB_CATEGORY_PK PRIMARY KEY (STD_SUB_CATEGORY_ID)
/
