-- the SOURCE_NAME column is PK or FK on nearly all the lego metadata tables.
-- unfortunately, its only 6 char long and I want to create a new source "HORIZON" which is 7 chars!!

-- This script makes it just one character wider in each table where it is stored.
ALTER TABLE lego_source
MODIFY (source_name VARCHAR2(7))
/
ALTER TABLE lego_object
MODIFY (source_name VARCHAR2(7))
/
ALTER TABLE lego_refresh
MODIFY (source_name VARCHAR2(7))
/
ALTER TABLE lego_refresh_index
MODIFY (source_name VARCHAR2(7))
/
ALTER TABLE lego_refresh_history
MODIFY (source_name VARCHAR2(7))
/
ALTER TABLE lego_refresh_toggle_priv
MODIFY (source_name VARCHAR2(7))
/
ALTER TABLE lego_refresh_dependency
MODIFY (source_name VARCHAR2(7),
        relies_on_source_name VARCHAR2(7))
/

