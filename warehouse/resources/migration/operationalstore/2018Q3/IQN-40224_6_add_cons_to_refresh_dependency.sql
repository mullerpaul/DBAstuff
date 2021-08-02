-- Add a few check constraints to LEGO_REFRESH_DEPENDENCY so that 
-- our code in the refresh API package can safely make a few assumptions
-- about the data there.
ALTER TABLE lego_refresh_dependency
ADD CONSTRAINT lego_refresh_dependency_ck01 
CHECK (object_name <> relies_on_object_name)  -- no "self rows"
/
ALTER TABLE lego_refresh_dependency
ADD CONSTRAINT lego_refresh_dependency_ck02 
CHECK (source_name = relies_on_source_name)   -- no cross-source dependencies
/

