CREATE OR REPLACE PACKAGE dm_fo_metric_graph
/* This package conatins all the procedures required to support the metric graphs
   needed for Old UI
 */
 AS
  PROCEDURE gen_spend(in_msg_id in number);

  PROCEDURE gen_billing(in_msg_id in number);

  PROCEDURE gen_contractor_hours(in_msg_id in number);
  
  PROCEDURE main;

END dm_fo_metric_graph;
/