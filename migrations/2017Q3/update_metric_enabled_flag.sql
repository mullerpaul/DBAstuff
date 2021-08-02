-- This column is slated to be removed; but since its still referenced in code at this point,
-- we have to make sure the data is correct.  All rows should be set to Y.

UPDATE metric 
   SET enabled_flag = 'Y'
/

COMMIT
/

