-- We are able to modify this numeric column to text IF and OLNY IF the column 
-- is empty! If its NOT empty, this will fail with a ORA-01439 "column to be
-- modified must be empty to change datatype" error.
-- I'm not adding code to catch that error because at this time, the column 
-- is empty in all environments.

-- If this DOES end up failing with an ORA-01439, then we will want to 
-- take action anyway since we may not want to lose data.  or perhaps we might.
-- Its best to leave that decision up to a human and not code!

ALTER TABLE supplier_release
MODIFY (release_tier VARCHAR2(70))
/

