CREATE OR REPLACE PACKAGE dm_utils
AS
/******************************************************************************
 NAME:       DM_UTILS
 PURPOSE:    To perform utilify functions and procedures of a general nature.    
     
 REVISION HISTORY:     
 08/01/2016  jpullifrone IQN-33792 Nothing changed here in this proc but noting that
                                   reference to this proc has been removed from FO
                                   Legacy deploy scripts.
 08/05/2016  jpulliforne IQN-33877 Added refresh_mv procedure.   
 09/12/2016  jpullifrone IQN-34535 package was overwritten during 16.10 release.  Nothing changing here.
 ******************************************************************************/
 
    c_crlf          VARCHAR2(2) := chr(13) || chr(10);
    
  PROCEDURE refresh_mv (pi_mv_name  VARCHAR2,
                        pi_method   VARCHAR2,
                        pi_start_ts TIMESTAMP DEFAULT SYSTIMESTAMP);
  
 ---------------------------------------------------------------------------------
  PROCEDURE enable_refresh_job (pi_job_name VARCHAR2);

 ---------------------------------------------------------------------------------
  PROCEDURE disable_refresh_job (pi_job_name VARCHAR2);

  --------------------------------------------------------------------------------  
  PROCEDURE alter_chain (pi_chain_name VARCHAR2,
                         pi_step_name  VARCHAR2,
                         pi_attribute  VARCHAR2,
                         pi_value      BOOLEAN);
                         
  --------------------------------------------------------------------------------  
  PROCEDURE alter_chain (pi_chain_name VARCHAR2,
                         pi_step_name  VARCHAR2,
                         pi_attribute  VARCHAR2,
                         pi_value      VARCHAR2);    
                         
  --------------------------------------------------------------------------------                         
  FUNCTION get_std_title
  (
      p_fo_title    IN VARCHAR2
    , p_buyerorg_id IN NUMBER
    , p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
    , p_type        IN VARCHAR2 DEFAULT 'DESC'
  )
  RETURN VARCHAR2;
  
  --------------------------------------------------------------------------------  
  FUNCTION get_std_category
  (
      p_fo_title    IN VARCHAR2
    , p_buyerorg_id IN NUMBER
    , p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
    , p_type        IN VARCHAR2 DEFAULT 'DESC'
  )
  RETURN VARCHAR2;

  --------------------------------------------------------------------------------  
  PROCEDURE send_email
  (
      sender    IN VARCHAR2
    , recipient IN VARCHAR2
    , subject   IN VARCHAR2
    , message   IN VARCHAR2
  );
  
  --------------------------------------------------------------------------------  
--    FUNCTION weekend_days_between
--    (
--        p_start_date IN DATE
--      , p_end_date   IN DATE
--    )
--    RETURN NUMBER;

  --------------------------------------------------------------------------------
  FUNCTION bdays
  (
      start_date IN DATE
    , end_date   IN DATE
    , region     IN VARCHAR2 DEFAULT 'USA'
  ) 
  RETURN NUMBER; 
  
END dm_utils;
/