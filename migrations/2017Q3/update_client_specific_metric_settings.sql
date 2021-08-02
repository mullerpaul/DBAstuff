-- With msvc-1023, we added some metrics, got rid of others, and re-weighted still others.
-- the new metrics were copied to client-specific settings correctly, and the removed
-- metrics were deleted from client_specific areas correctly; but we did NOT correct for the 
-- re-weighted metrics.
-- This script takes care of that issue.

-- Since clients can't yet modify their own settings, I'm not worried about updating settings
-- for ALL clients with this script.

UPDATE client_metric_coefficient
   SET metric_coefficient = CASE 
                              WHEN metric_id IN (20,21,22)    THEN 4
                              WHEN metric_id IN (23,24,25,27) THEN 2
                              WHEN metric_id = 29             THEN 1
                            END  
 WHERE metric_id IN (20,21,22,23,24,25,27,29)
/

COMMIT
/

