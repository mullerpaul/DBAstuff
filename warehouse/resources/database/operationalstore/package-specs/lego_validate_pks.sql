CREATE OR REPLACE PACKAGE lego_validate AUTHID DEFINER AS
  /******************************************************************************
     NAME:       LEGO_TESTER
     PURPOSE:    
  
     REVISIONS:
     Ver     Date        Author        Description
     ------  ----------  ------------  ------------------------------------
     1.0     05/07/2013  pmuller and   Created package.
                         jpullifrone
     1.1     06/24/2014  Hmajid        Added the join_test procedure.
  
  ******************************************************************************/

  FUNCTION ok_to_test(pi_refresh_object_name IN VARCHAR2) RETURN CHAR;

  --------------------------------------------------------------------------------
  PROCEDURE lego_assignment_rowcount;

  --------------------------------------------------------------------------------
  PROCEDURE unique_test(pi_table_name IN VARCHAR2,
                        pi_unique_key IN VARCHAR2);

  --------------------------------------------------------------------------------
  PROCEDURE rowcount_test(pi_table_name        IN VARCHAR2,
                          pi_expected_rowcount IN NUMBER);

  --------------------------------------------------------------------------------
  PROCEDURE rowcount_test(pi_table_name  IN VARCHAR2,
                          pi_upper_bound IN NUMBER,
                          pi_lower_bound IN NUMBER);

  --------------------------------------------------------------------------------
  PROCEDURE test_legos;
  
  PROCEDURE join_test(pi_driving_table_name        IN VARCHAR2,
                       pi_driving_col_name         IN VARCHAR2,
                       pi_detail_table_name         IN VARCHAR2,                     
                       pi_detail_col_name           IN VARCHAR2,
                       pi_join_operator   IN VARCHAR2);

END lego_validate; 
/

