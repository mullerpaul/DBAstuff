-- We need to wipe and reload ALL CWS (beeline) data.

-- Luckily, (or by design really), we have partitioned the data tables
-- by source vms and so we can TRUNCATE partitions instead of DELETING.
-- This is MUCH faster than deleting - in fact its pretty much instant.
-- Since it is a DDL operation and not a DML operation, we do not need 
-- to commit.

ALTER TABLE supplier_submission
TRUNCATE PARTITION p_beeline_vms
/

ALTER TABLE supplier_release
TRUNCATE PARTITION p_beeline_vms
/

