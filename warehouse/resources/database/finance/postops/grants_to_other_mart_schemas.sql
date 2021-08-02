-- I'm currently leaning towards handling intra-schema grants with a simple "dumb" 
-- script with a list of grants.  No loops or anything fancy here.  

-- This script should be either "runAlways", or "runOnChange".

-- This strategy puts the onus on us developers to keep this up to date when we 
-- add new or remove old objects.  I know thats a lot of work thats easy to forget, 
-- and it can break the migration when we do forget!  Hopefully the fact that a mistake
-- makes this script fail bady will make us keep this up-to-date.
-- Thats why there is no error handling here and liquibase will stop if this fails.  


-- Organizing this list by grantee.  If that proves to not be the best way, then re-org!

GRANT SELECT ON finance_revenue_vw TO finance_user
/
GRANT SELECT ON finance_revenue_vw TO ops
/
GRANT SELECT ON finance_revenue_vw TO readonly
/

