CREATE OR REPLACE PACKAGE lego_tenure AS
  /******************************************************************************
     NAME:       lego_tenure
     PURPOSE:    Build tables and processes associated with the Tenure legos
  
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
                03/14/2016  Paul Muller      Created this package.
     
  ******************************************************************************/

  PROCEDURE load_lego_tenure(pi_refresh_table_name IN VARCHAR2,
                             pi_source_name        IN VARCHAR2,
                             pi_source_scn         IN VARCHAR2);

END lego_tenure;
/
