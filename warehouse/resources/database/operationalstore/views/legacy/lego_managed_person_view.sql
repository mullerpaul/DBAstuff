CREATE OR REPLACE FORCE VIEW lego_managed_person_vw
AS
SELECT manager_person_id, employee_person_id
  FROM lego_managed_person
/

