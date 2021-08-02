-- These three indexes became "unusable" after we ran the script for msvc-3967.
-- we can make them "usable" again by simply rebuilding them.
-- If we ever need a script like msvc-3967 again, we should take precautions against
-- unusable indexes after ALTER TABLE x TRUNCATE PARTITION y.

-- This might take a while in environments with large amounts of data; but 
-- I don't think it should be TOO long for a migration.
-- Now that I've written that, we're doomed.

ALTER INDEX supplier_release_pk REBUILD
/

ALTER INDEX supplier_release_ui01 REBUILD
/

ALTER INDEX supplier_submission_pk REBUILD
/

