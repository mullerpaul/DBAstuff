CREATE TABLE lego_invoice_object (
  object_name                 VARCHAR2(30),
  source_name                 VARCHAR2(6),
  object_desc                 VARCHAR2(255) NOT NULL,
  enabled                     CHAR(1) NOT NULL,
  create_date                 DATE NOT NULL)
/

ALTER TABLE lego_invoice_object
ADD CONSTRAINT lego_invoice_object_pk
PRIMARY KEY (object_name, source_name)
/

