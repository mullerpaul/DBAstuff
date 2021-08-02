CREATE OR REPLACE PACKAGE lego_supplier_scorecard AS
/******************************************************************************
   NAME:       lego_supplier_scorecard
   PURPOSE:    logic related to Supplier Scorecard 2.0

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   IQN-18303  7/17/2014   J.Pullifrone     Created this package.
   IQN-37660  05/19/2017  J.Pullifrone     Repurposing this package for supplier 
                                           scorecard 2.0
   IQN-38381  09/06/2017  J.Pullifrone     Moved individual procs into one.										   
******************************************************************************/

  PROCEDURE load_supplier_scorecard (pi_object_name IN lego_refresh.object_name%TYPE,
                                     pi_source      IN lego_refresh.source_name%TYPE);                                                                     
  

END lego_supplier_scorecard;
/
