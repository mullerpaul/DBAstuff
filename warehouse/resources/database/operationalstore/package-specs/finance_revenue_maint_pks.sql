create or replace PACKAGE finance_revenue_maint AS

  /*  Table Reference 

      FINANCE_LOAD_TRACKER - Table used to keep track of what finance revenue data has been pulled and loaded
                             and what to pull next.

      FINANCE_APPROVED_INVOICE -  GTT that holds approved invoice IDs and approved dates.
      
      FINANCE_ORG_CURRENCY - Table used to determine currency conversion for a given buyer organization.  Used for 
                             this process only for right now.

      FINANCE_REVENUE_STAGE - GTT that holds finance revenue data for the current run.  What data it holds
                              is driven by the values used in FINANCE_LOAD_TRACKER.

      FINANCE_REVENUE - Table that holds current and historical finance revenue data.  
  */
  
  
  PROCEDURE index_maint (pi_object_name   IN lego_object.object_name%TYPE,
                         pi_process_stage IN VARCHAR2);   
  
  /* Example call:
     BEGIN 
       --EXECUTE IMMEDIATE 'ALTER SESSION SET TIME_ZONE =dbtimezone';
       --EXECUTE IMMEDIATE 'ALTER SESSION SET TIME_ZONE = ''+02:00'''; --for EMEA
       --finance_revenue_maint.off_cycle_fin_rev_load('FINANCE_REVENEUE','USPROD');
     END;
     / 
  
  */
  
  PROCEDURE off_cycle_fin_rev_load (pi_object_name IN lego_object.object_name%TYPE,
                                    pi_source      IN lego_object.source_name%TYPE,
                                    pi_start_ts    IN TIMESTAMP DEFAULT SYSTIMESTAMP);


  /* Example call:
     BEGIN 
       --EXECUTE IMMEDIATE 'ALTER SESSION SET TIME_ZONE =dbtimezone';
       --EXECUTE IMMEDIATE 'ALTER SESSION SET TIME_ZONE = ''+02:00'''; --for EMEA
       --finance_revenue_maint.drop_oc_fin_rev_job('FINANCE_REVENEUE');
     END;
     / 
  
  */  
  PROCEDURE drop_oc_fin_rev_job (pi_object_name lego_object.object_name%TYPE);									

  
  PROCEDURE main (pi_object_name IN lego_object.object_name%TYPE,
                  pi_source      IN lego_object.source_name%TYPE,
				  pi_start_date  IN finance_load_tracker.start_date%TYPE DEFAULT NULL,
                  pi_end_date    IN finance_load_tracker.end_date%TYPE   DEFAULT NULL);


END finance_revenue_maint;
/