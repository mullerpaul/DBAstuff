CREATE OR REPLACE FORCE VIEW lego_secure_timecard_vw
  (user_id, 
   timecard_id)
AS
SELECT user_id, 
       timecard_id
  FROM lego_slot_timecard
/


