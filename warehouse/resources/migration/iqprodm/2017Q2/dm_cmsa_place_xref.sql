CREATE TABLE DM_CMSA_PLACE_XREF
(
PARENT_STD_PLACE_ID NUMBER,
CMSA_CODE VARCHAR2(6 BYTE)
)
/
ALTER TABLE DM_CMSA_PLACE_XREF ADD CONSTRAINT DM_CMSA_PLACE_PK PRIMARY KEY (PARENT_STD_PLACE_ID,CMSA_CODE)
/

