/*************************************[SUPPLIER_RELEASE]*************************************/
ALTER TABLE SUPPLIER_RELEASE ADD ( DATABASE_NAME VARCHAR2(128) )
/

COMMENT ON COLUMN SUPPLIER_RELEASE.DATABASE_NAME 
	IS 'This column contains the Beeline site where the data is pulled from. In Beeline, same client could reside on multiple lower environment sites. This field could distinguish which site it came from.'
/

/***********************************[SUPPLIER_RELEASE_GTT]***********************************/
ALTER TABLE SUPPLIER_RELEASE_GTT ADD ( DATABASE_NAME VARCHAR2(128) )
/

COMMENT ON COLUMN SUPPLIER_RELEASE_GTT.DATABASE_NAME 
	IS 'This column contains the Beeline site where the data is pulled from. In Beeline, same client could reside on multiple lower environment sites. This field could distinguish which site it came from.'
/
