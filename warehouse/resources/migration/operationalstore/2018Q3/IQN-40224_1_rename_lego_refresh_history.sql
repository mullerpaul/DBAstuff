-- first get rid of constraints and then rename table to save off legacy data.
-- we get rid of the constraints so we can use those same names when we recreate the table.
ALTER TABLE lego_refresh_history
DROP PRIMARY KEY
DROP INDEX
/
ALTER TABLE lego_refresh_history
DROP CONSTRAINT lego_refresh_history_ck01
/
RENAME lego_refresh_history
TO lego_refresh_history_archive
/

