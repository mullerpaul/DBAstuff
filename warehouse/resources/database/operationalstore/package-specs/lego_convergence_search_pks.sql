CREATE OR REPLACE PACKAGE lego_convergence_search
AUTHID DEFINER
IS
/******************************************************************************
   NAME:       lego_convergence_search
   PURPOSE:    logic related to the BLone convergence search bar

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   IQN-39946  05/01/2018  Paul Muller      Created this package using the 
                                           lego_supplier_scorecard pacakge as a template.

   ******************************************************************************/

  PROCEDURE load_convergence_search (pi_object_name IN lego_refresh.object_name%TYPE,
                                     pi_source      IN lego_refresh.source_name%TYPE);                                                                     
  

END lego_convergence_search;
/
