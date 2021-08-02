-- The table supplier_release_duplicates is meant to hold rows from CWS (only - no FO data) where the unique key 
-- would be violated if these rows were  loaded.  So we load it, and then exclude the loaded rows from the MERGE
-- into supplier_release.

-- However, we found there is a bug with the way we are loading it.  Rows that are NOT duplicates were finding 
-- their way in and then their information would not make it into SUPPLIER_RELEASE and so SSC would be missing 
-- recent information, leading to incorrect results.

-- We have a fix in this story (msvc-3864) to change the way we figure out which rows to exclude, so things will 
-- good going forward.  But to recover all the information we missed while this bug was in prod; we'll have to do
-- a full load from all CWS databases.  This is a different process than the normal incremental loads we do from CWS.
-- Since that full load means we are basically starting over, and since most of the duplicates in this table should 
-- not have been there anyway, we will also truncate the duplicates table with this story.

-- TRUNCATE is considered DDL instead of DML.  Thus it is non-transactional, meaning it doesn't require a commit 
-- and it can't be rolled back.

TRUNCATE TABLE supplier_release_duplicates
/
