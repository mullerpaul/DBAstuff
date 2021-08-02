/* When I started working on the new and improved Timecard load, that this table could be reused by more than just invoice 
   loads.  For that reason, I am renaming it.  Will have to make a few minor renaming changes in lego_invoice package body
   but no biggie. Also adding FK to LEGO_SOURCE.  IQN-33702, Joe P */
   
ALTER TABLE lego_invoice_object RENAME TO lego_object
/
ALTER TABLE lego_object RENAME CONSTRAINT lego_invoice_object_pk TO lego_object_pk
/
ALTER TABLE lego_object
ADD CONSTRAINT lego_object_fk01
FOREIGN KEY (source_name)
REFERENCES lego_source (source_name)
/
