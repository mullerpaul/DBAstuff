--- rename candidates declined to offer rejection count
UPDATE metric
   SET metric_name = 'offer rejection count'
 WHERE metric_id = 12
/

--- rename avg markup percentage to supplier markup ratio
UPDATE metric
   SET metric_name = 'supplier markup ratio'
 WHERE metric_id = 25
/

--- rename acceptance rate to candidate offer acceptance
UPDATE metric
   SET metric_name = 'candidate offer acceptance'
 WHERE metric_id = 14
/

--- reclassify 
UPDATE metric
   SET metric_category = 'candidate quality'
 WHERE metric_id = 29
/

--- renormalize metric coefficients based on new counts per category
UPDATE metric
   SET default_coefficient = CASE 
                               WHEN metric_category = 'candidate quality' THEN 1
                               WHEN metric_category = 'cost'              THEN 2
                               WHEN metric_category = 'efficiency'        THEN 4
                             END
/

COMMIT
/

