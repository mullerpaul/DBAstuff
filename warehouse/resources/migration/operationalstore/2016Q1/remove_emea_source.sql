----------------------------
-- It looks like we are NOT going to have EMEA data in the same mart DB as US data.
-- This script will remove the EMEA rows from LEGO_REFRESH and LEGO_SOURCE.
-- If we ever deploy mart to an EMEA location, we'll have to revisit this topic
-- and write a "smart script" which knows what environment in which its being run.
----------------------------

DELETE FROM lego_refresh WHERE source_name = 'EMEA'
/
DELETE FROM lego_source WHERE source_name = 'EMEA'
/
COMMIT
/
