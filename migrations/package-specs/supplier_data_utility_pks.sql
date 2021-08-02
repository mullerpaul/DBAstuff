CREATE OR REPLACE PACKAGE supplier_data_utility
AS
/******************************************************************************
   NAME:       supplier_data_utility
   PURPOSE:    public functions and procedures which maintain the detailed data 
               used for grading and ranking suppleirs.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
              04/13/2017  Paul Muller      Created this package.
   MSCV-667   05/09/2017  Paul Muller      logging changes
******************************************************************************/

  PROCEDURE move_data_to_perm_tables (pi_legacy_source IN VARCHAR2);

END supplier_data_utility;  
/
