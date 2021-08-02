-- Create a table to hold a tree of legos that each lego relies on.
-- This is important so legos can be refreshed in the correct order to reduce data 
-- latency from Front Office to final lego.

-- I went through a few names for this table and its columns.  Of course, I'm sure we won't know if I
-- picked the right name or not until months or years from now!  So, here are the runner-up names:
-- LEGO_RELIANCE, LEGO_DEPENDANT_LEGO.

-- Since ALL of the columns of the table are in the PK, we really don't need 2 copies of the same data
-- (the table segment and the PK segment).  So we could recreate this as an IOT.  I left it as a normal 
-- heap table for now just to not get distracted from the main idea - plus its probably only going to be
-- 100 rows or so and that means we'll have two copies of an 8Kb block.  Not a big deal!

CREATE TABLE lego_refresh_dependency
  (object_name            VARCHAR2(30) NOT NULL,
   source_name            VARCHAR2(6)  NOT NULL,
   relies_on_object_name  VARCHAR2(30) NOT NULL,
   relies_on_source_name  VARCHAR2(6)  NOT NULL,
   CONSTRAINT lego_refresh_dependency_pk
     PRIMARY KEY (object_name, source_name, relies_on_object_name, relies_on_source_name),
   CONSTRAINT lego_refresh_dependency_fk01
     FOREIGN KEY (object_name, source_name)
     REFERENCES lego_refresh (object_name, source_name),
   CONSTRAINT lego_refresh_dependency_fk02
     FOREIGN KEY (relies_on_object_name, relies_on_source_name)
     REFERENCES lego_refresh (object_name, source_name)
  )
/

-- I was thinking about putting a constraint on the table to ensure that the parent and 
-- child SOURCE_NAME are the same; but ended up not doing so because its conceivable that 
-- we might have legos depend on legos from different sources.


COMMENT ON TABLE lego_refresh_dependency
IS 'Which other legos does this lego use in its refresh'
/

COMMENT ON COLUMN lego_refresh_dependency.object_name
IS 'Name of lego to be refreshed'
/
COMMENT ON COLUMN lego_refresh_dependency.source_name
IS 'Source of lego to be refreshed'
/
COMMENT ON COLUMN lego_refresh_dependency.relies_on_object_name
IS 'Name of lego used in the refresh'
/
COMMENT ON COLUMN lego_refresh_dependency.relies_on_source_name
IS 'Source of lego used in the refresh'
/
 
