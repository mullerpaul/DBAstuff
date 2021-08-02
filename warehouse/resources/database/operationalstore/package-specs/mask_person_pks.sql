CREATE OR REPLACE PACKAGE mask_person
AS
  PROCEDURE process_erasure_request (pi_person_to_erase IN  NUMBER,
                                     po_status          OUT VARCHAR2);

END mask_person;
/
