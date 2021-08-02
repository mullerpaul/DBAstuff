ALTER TABLE lego_refresh_dependency
DROP CONSTRAINT lego_refresh_dependency_ck02
/

-- USPROD legos cant depend on WFPROD legos and vice-versa.
-- HORIZON legos cant depend on anything
ALTER TABLE lego_refresh_dependency
ADD CONSTRAINT lego_refresh_dependency_ck02
CHECK ((source_name = 'USPROD' AND relies_on_source_name in ('USPROD','HORIZON')) OR
       (source_name = 'WFPROD' AND relies_on_source_name in ('WFPROD','HORIZON'))
      )
/


