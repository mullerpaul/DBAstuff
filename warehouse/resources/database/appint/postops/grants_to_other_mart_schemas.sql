-- I'm currently leaning towards handling intra-schema grants with a simple "dumb" 
-- script with a list of grants.  No loops or anything fancy here.  

-- This script should be either "runAlways", or "runOnChange".

-- This strategy puts the onus on us developers to keep this up to date when we 
-- add new or remove old objects.  I know thats a lot of work, its easy to forget, 
-- and it can break the migration when we do forget!  But hopefully the threat of
-- making a mistake which breaks the build will motiviate us to keep this up-to-date!
-- So thats why there is no error handling here and liquibase will stop if this fails.  


-- Organizing this list by grantee.  If that proves to not be the best way, then re-org!


--grants to OPS schema
GRANT SELECT ON databasechangelog TO ops
/
GRANT SELECT ON databasechangeloglock TO ops
/
GRANT SELECT ON processing_log TO ops
/
GRANT SELECT ON dashboard_api_calls TO ops
/
GRANT EXECUTE, DEBUG ON dashboard_data_api TO ops
/

-- grants to OPERATIONALSTORE schema
GRANT SELECT ON dashboard_api_calls TO operationalstore
/

-- grants to READONLY schema
GRANT SELECT ON databasechangelog TO readonly
/
GRANT SELECT ON databasechangeloglock TO readonly
/
GRANT SELECT ON processing_log TO readonly
/
GRANT SELECT ON dashboard_api_calls TO readonly
/
GRANT EXECUTE, DEBUG ON dashboard_data_api TO appint_user
/
