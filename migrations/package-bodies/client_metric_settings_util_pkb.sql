CREATE OR REPLACE PACKAGE BODY client_metric_settings_util
AS
/***************************************************************************************************************************************
   NAME:       client_metric_settings_util
   PURPOSE:    public functions and procedures which maintain client specific
               formula settings.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   MSVC-595   04/21/2017  Paul Muller      Created this package.
   MSVC-604   04/24/2017  Paul Muller      Added remove settings proc 
   MSVC-690   05/08/2017  Paul Muller      Added writes to transaction_log table.
                                           Also removed remove_client_settings since
                                           its tough to log correctly. Revisit the need
                                           for that functionality later.
   MSVC-612   06/19/2017  Joe Pullifrone   Convert txn log timestamps to UTC.
   MSVC-2585  03/01/2018  Hassina Majid    Populate new effective_date column and load
                                           defaults into client_category_coefficient
                                           based on the unique category names
                                           in metric.metric_category.
   MSVC-2764  03/06/2018  McKay Dunlap     Remove References to client_metric_coefficient_guid for 
                                           client_metric_conversion and added in metric_id, client_guid
                                           inserts in code. 
  MSVC-2694  03/13/2018  Hassina Majid    create pair of PL/SQL procedures to serve as client_category API call for client_category_coefficient.
  MSVC-2695  03/13/2018  Hassina Majid    create pair of PL/SQL set and get procedures to serve as client_metric API call for client_metric_coefficient. 
  MSVC-2696  03/19/2018  Hassina Majid    create pair of PL/SQL set and get procedures to serve as client_metric API call for client_metric_conversion.  
  MSVC-2889  03/20/2018  Hassina Majid    remove effective_date input from score settings SET procedure.
  MSVC-2896  03/21/2018  Hassina Majid    Added "as-of" time input parameter to score settings GET calls.
  MSVC-2892  03/22/2018  Hassina Majid    Added get/set routines for metric range grade scores.
  MSVC-3159  04/24/2018  Hassina Majid    Add supplier scorecard comments if it exists update it for
                                                                       given client.
  MSVC-3160  05/01/2018  Hassina Majid    Add a new procedure which include the set convresion and set score routines.
  MSVC-3257  05/14/2018  Hassina Majid    Remove commits and timestamp from all set procedures.
                                                                       Also, changed logic to use just date when updating existing data
                                                                       due to how application will be working and expected to update data.  
                                                                       Combined set client metric coversion and score into new procedure 
                                                                       set_all_metric_conversion.
 MSVC-3258  05/21/2018   Hassina Majid   Add the procedure which shows the historical activity on all client
                                                                      related tables which has changed from the intial addition. 
                                                                      This indicate any changes to Client_category_coefficient, client_metric_coefficient,
                                                                      client_metric_conversion tables.
 MSVC-3497 05/30/2018    Hassina Majid   Change the sort order on historical data.
 MSVC-3594 06/07/2018    Hassina Majid   Changed code to show comments regarless of whether metric data is changed or not!
 MSVC-3476 07/02/2018    Hassina Majid   Added the initial version of historical data and indicate it in comment field as per requirement.
 MSVC-3933 08/06/2018    Boris Pogrebitskiy Change to update of a metric to override username at the same time as range and points.
 MSVC-3963 08/13/2018    Updated the historical to show a new comment on initial version of client data loaded.
                           
****************************************************************************************************************************************/

 PROCEDURE initialize_logger IS
  BEGIN
    /* Instantiate the logger and set the level to INFO.
      Do we want to parameterize the logging level instead?  
      Perhaps have it passed by the caller in each client DB?
      Investigate later. */
    logger_pkg.instantiate_logger;
    logger_pkg.set_source('CLIENT_METRIC_SETTINGS_UTIL');
    logger_pkg.set_level('DEBUG');

  END initialize_logger;
  
  FUNCTION get_score_owning_guid(pi_login_guid IN RAW) 
  RETURN client_visibility_list.score_config_owner_guid%type
  IS
  lv_score_config_owner_guid client_visibility_list.score_config_owner_guid%type; 
  BEGIN
     
     SELECT DISTINCT score_config_owner_guid
       INTO lv_score_config_owner_guid
       FROM client_visibility_list
      WHERE log_in_client_guid = pi_login_guid;

  RETURN lv_score_config_owner_guid;
 
  
  END;
  
  PROCEDURE insert_into_transaction_Log (pi_session_guid  IN  RAW,
                                         pi_request_guid  IN  RAW, 
                                         pi_request_timestamp IN timestamp, 
                                         pi_bus_org_guid  IN   RAW, 
                                         pi_entity_name   IN   VARCHAR, 
                                         pi_entity_guid_1 IN  RAW,
                                         Pi_message_text  IN   VARCHAR,
                                         po_txn_guid      OUT  RAW)  IS
                                         
   lv_txn_guid RAW(16);
  BEGIN
  
     lv_txn_guid := sys_guid;
       
     INSERT INTO transaction_log
           (txn_guid,           
            session_guid,
            request_guid,
            request_timestamp,
            processed_timestamp,
            bus_org_guid,
            entity_name,
            entity_guid_1,
            message_text)
      VALUES 
        (lv_txn_guid,
         pi_session_guid,
         pi_request_guid,
         pi_request_timestamp, 
         sys_extract_utc(SYSTIMESTAMP),
         pi_bus_org_guid,
         pi_entity_name,
         pi_entity_guid_1,        
         Pi_message_text);    
                 
         po_txn_guid := lv_txn_guid;
     
  
  END insert_into_transaction_Log;
   
 PROCEDURE copy_defaults_to_client (pi_client_guid  IN RAW,
                                     pi_session_guid IN RAW,
                                     pi_request_guid IN RAW)
  IS
    lv_request_timestamp TIMESTAMP := sys_extract_utc(SYSTIMESTAMP);
    lv_txn_log_pk        RAW(16);
    lv_ccc_pk            RAW(16);
    
  BEGIN
    /* Copies all metric settings which do not already exist in client-specific tables
       to the client-specific tables.  This is a safe operation which WILL NOT
       overwrite or otherwise lose any client data. */ 

    /* I've decided to NOT include a check on the input for a valid client GUID here.  
       We should revisit that decision after this is in production.  I don't want 
       to insert data for non-existant clients into the CLIENT_METRIC_% tables!
       UPDATE : This is only called from the data load.  That calls it based on 
       existing client data, so the lack of this check is not a concern.  */

    /* I'm never a fan of nested loops in PL/SQL code since there is usually a faster
       way to get it done with set-based SQL statements instead.  However, in this 
       case, after trying and failing with a few different approaches, I couldn't
       get the data correct for the multiple parent tables!  
       Perhaps at some point in the future, we should look for a better way. 
       Luckily, I don't expect the inner loop to execute more than about 150 times!
       (30 outer * 5 inner)  */ 
      
    FOR i IN (SELECT metric_id,
                     default_coefficient,
                     sys_guid() AS client_metric_coefficient_pk,
                     sys_guid() AS txn_log_pk
                FROM metric m
               WHERE enabled_flag = 'Y'
                 AND NOT EXISTS (SELECT NULL
                                   FROM client_metric_coefficient cmc
                                  WHERE m.metric_id = cmc.metric_id
                                    AND cmc.client_guid = pi_client_guid)) LOOP
      
      /* parent txn log entry */
      INSERT INTO transaction_log
        (txn_guid, session_guid, request_guid, 
         request_timestamp, processed_timestamp,
         bus_org_guid, 
         entity_name, entity_guid_1,
         message_text)
      VALUES 
        (i.txn_log_pk, pi_session_guid, pi_request_guid,
         lv_request_timestamp,sys_extract_utc(SYSTIMESTAMP),
         pi_client_guid, 
         'client_metric_coefficient', i.client_metric_coefficient_pk,
         'Copying default coefficient for metric: ' || to_char(i.metric_id) ||
         '  For client: ' || rawtohex(pi_client_guid) || 
         '  New PK: ' || rawtohex(i.client_metric_coefficient_pk));

      /* Parent client data */
      INSERT INTO client_metric_coefficient 
        (client_metric_coefficient_guid, client_guid, metric_id, 
         metric_coefficient, last_txn_guid,effective_date )
      VALUES 
        (i.client_metric_coefficient_pk, pi_client_guid, i.metric_id, 
         i.default_coefficient, i.txn_log_pk,trunc(sys_extract_utc(systimestamp))
         );
        
      /* Child rows and their txn log entries. */
      FOR j IN (SELECT sys_guid() AS client_metric_conversion_pk,
                       sys_guid() AS txn_log_pk,
                       greater_than_or_equal, less_than,
                       range_grade, range_score, range_score_conversion_factor
                  FROM default_metric_conversion 
                 WHERE metric_id = i.metric_id) loop

        /* txn log entry for each child row */
        INSERT INTO transaction_log
          (txn_guid, session_guid, request_guid, 
           request_timestamp, processed_timestamp,
           bus_org_guid, 
           entity_name, entity_guid_1,
           message_text)
        VALUES 
          (j.txn_log_pk, pi_session_guid, pi_request_guid,
           lv_request_timestamp, sys_extract_utc(SYSTIMESTAMP),
           pi_client_guid, 
           'client_metric_conversion', j.client_metric_conversion_pk,
           'Copying default conversion info for metric: ' || to_char(i.metric_id) ||
           '  Range grade: ' || j.range_grade ||
           '  For client ' || rawtohex(pi_client_guid) || 
           '  New PK: ' || rawtohex(j.client_metric_conversion_pk));
        
        /* insert default data into client_metric_conversion_insert  */
        INSERT INTO client_metric_conversion
          (client_metric_conversion_guid,   --client_metric_coefficient_guid,
           greater_than_or_equal, less_than,
           range_grade, range_score, range_score_conversion_factor,
           last_txn_guid,effective_date, 
           metric_id, client_guid)
        VALUES
          (j.client_metric_conversion_pk, --i.client_metric_coefficient_pk,
           j.greater_than_or_equal, j.less_than,
           j.range_grade, j.range_score, j.range_score_conversion_factor,
           j.txn_log_pk,trunc(sys_extract_utc(systimestamp)), 
           i.metric_id, pi_client_guid);

      END LOOP;  --child rows

    END LOOP;  --parent rows
    
    /* Insert default category coefficients.  We don't have a table storing these now.
       If we ever add one it would be called DEFAULT_CATEGORY_COEFFICIENT.
       For now, we just hardcode the default value for each category, 10, into the inserts. */
    FOR k IN ( SELECT DISTINCT metric_category
                 FROM metric) LOOP

      lv_txn_log_pk := sys_guid;
      lv_ccc_pk := sys_guid;

      INSERT INTO transaction_log
        (txn_guid, session_guid, request_guid, 
         request_timestamp, processed_timestamp,
         bus_org_guid, 
         entity_name, entity_guid_1,
         message_text)
      VALUES 
        (lv_txn_log_pk, pi_session_guid, pi_request_guid,
         lv_request_timestamp, sys_extract_utc(SYSTIMESTAMP),
         pi_client_guid, 
         'client_category_coefficient', lv_ccc_pk,
         'Copying defaults conversion info for category: ' || to_char(k.metric_category) ||
         '  For client: ' || rawtohex(pi_client_guid) || 
         '  New PK: ' || rawtohex(lv_ccc_pk));

      INSERT INTO client_category_coefficient
        (client_ctgry_coefficient_guid,
         client_guid,
         metric_category,
         category_coefficient,
         last_txn_guid,
         effective_date)
      VALUES
        (lv_ccc_pk,
         pi_client_guid,
         k.metric_category,
         10,   -- hardcoding value here.
         lv_txn_log_pk,
         trunc(sys_extract_utc(systimestamp))) ; 

    END LOOP;  -- client_category_coefficient
    
    /* Commit or rollback must be done by caller. */
    
    /* ToDo - proper error handling */

  END copy_defaults_to_client;  

  PROCEDURE get_client_catgry_coefficient(pi_login_guid IN RAW,
                                pi_category_name IN CLIENT_CATEGORY_COEFFICIENT.METRIC_CATEGORY%TYPE,
                                pi_as_of_date_utc IN DATE DEFAULT trunc(sys_extract_utc(systimestamp)),
                                po_category_coefficient OUT CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE)
  IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_category_coefficient CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE;
    lv_last_effective_date date;
  BEGIN
   
     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);

    BEGIN 
          
        SELECT category_coefficient
       INTO lv_category_coefficient
      FROM CLIENT_CATEGORY_COEFFICIENT
      WHERE client_guid = lv_score_owning_guid
       AND metric_category =  pi_category_name
       AND  trunc(effective_date) = pi_as_of_date_utc;   
       
     EXCEPTION WHEN no_data_found THEN 
      
       SELECT max (TRUNC (effective_date))         
         INTO lv_last_effective_date
         FROM  CLIENT_CATEGORY_COEFFICIENT
         WHERE client_guid = lv_score_owning_guid
          AND metric_category =  pi_category_name
          AND TRUNC (effective_date) <= pi_as_of_date_utc;
          
             SELECT category_coefficient
       INTO lv_category_coefficient
      FROM CLIENT_CATEGORY_COEFFICIENT
      WHERE client_guid = lv_score_owning_guid
       AND metric_category =  pi_category_name
       AND  trunc(effective_date) = lv_last_effective_date;   
       
      
     END;  

    po_category_coefficient :=   lv_category_coefficient;         
       
  END get_client_catgry_coefficient;
  
  PROCEDURE set_client_catgry_coefficient(pi_login_guid IN RAW,
                                          pi_category_name IN CLIENT_CATEGORY_COEFFICIENT.METRIC_CATEGORY%TYPE,
                                          pi_category_coefficient IN CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE,
                                          pi_username IN VARCHAR,
                                          pi_session_guid IN RAW)
  IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_category_coefficient CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE;
   lv_request_timestamp TIMESTAMP := sys_extract_utc(SYSTIMESTAMP);
   lv_old_ccc_pk          RAW(16);
   lv_transaction_log_pk  RAW(16);
   lv_request_guid        RAW(16) :=  SYS_GUID;
   lv_new_ccc_pk          RAW(16) :=  SYS_GUID;
   lv_effective_date_in   DATE := trunc(sys_extract_utc(systimestamp));
   lv_count               NUMBER := 0;
  
   
  BEGIN
  
     initialize_logger;
     
     -- Update the transaction log for an existing change to Client Category Coefficient
     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);
          
      -- check to see if the category was already modified as of a UTC sysdate

     SELECT COUNT(*)
       into lv_count
      FROM  client_category_coefficient
    WHERE client_guid = lv_score_owning_guid
        AND metric_category = pi_category_name
        AND trunc(effective_date)  = lv_effective_date_in;    

 IF lv_count > 0 THEN      -- record exists and update data with new changes
                        
      UPDATE client_category_coefficient
         SET  category_coefficient =  pi_category_coefficient,
                 created_by_username =  pi_username         
        WHERE client_guid = lv_score_owning_guid
        AND metric_category = pi_category_name
        AND trunc(effective_date)  = lv_effective_date_in;   

 ELSE  
     BEGIN
        SELECT  CLIENT_CTGRY_COEFFICIENT_GUID
       INTO  lv_old_ccc_pk
       FROM  client_category_coefficient
      WHERE client_guid = lv_score_owning_guid
        AND metric_category = pi_category_name
        AND termination_date IS NULL;      

     insert_into_transaction_Log (pi_session_guid,
                                  lv_request_guid, 
                                  lv_request_timestamp, 
                                  lv_score_owning_guid, 
                                  'client_category_cofficient', 
                                  lv_old_ccc_pk,
                                  'End dating old client coefficient row.',
                                  lv_transaction_log_pk); 
                                         
      UPDATE client_category_coefficient
         SET last_txn_guid =  lv_transaction_log_pk, 
             last_txn_date = sys_extract_utc(systimestamp),             
             termination_date  = lv_effective_date_in
       WHERE client_ctgry_coefficient_guid = lv_old_ccc_pk;
      
      --  Insert a new transaction row for an new Client Category Coefficient
--      
      insert_into_transaction_Log (pi_session_guid,
                                  lv_request_guid, 
                                  lv_request_timestamp, 
                                  lv_score_owning_guid, 
                                  'client_category_cofficient', 
                                  lv_new_ccc_pk,
                                  'Inserting new client coefficient row.',
                                  lv_transaction_log_pk); 

     EXCEPTION WHEN no_data_found THEN  -- if no data exists for this client to terminate first time insertion
                NULL;
     END;

                               
      INSERT into client_category_coefficient
      (client_ctgry_coefficient_guid,
       client_guid,
       metric_category,
       category_coefficient,
       last_txn_guid,
       effective_date,
       created_by_username) 
      VALUES (lv_new_ccc_pk,
              lv_score_owning_guid,
              pi_category_name,
              pi_category_coefficient,
              lv_transaction_log_pk,
              lv_effective_date_in,
              pi_username);    


      --  Insert a new transaction row for an new Client Metric Coefficient
      
          insert_into_transaction_Log (pi_session_guid,
                                  lv_request_guid, 
                                  lv_request_timestamp, 
                                  lv_score_owning_guid, 
                                  'client_category_cofficient', 
                                  lv_new_ccc_pk,
                                  'Inserting new client coefficient row.',
                                  lv_transaction_log_pk); 
 
   END IF;
   
    /* Commit or rollback must be done by caller. */
    
    /* ToDo - proper error handling */
              
   
  END set_client_catgry_coefficient; 


  PROCEDURE get_client_metric_coefficient(pi_login_guid IN RAW,
                                          pi_metric_id IN CLIENT_METRIC_COEFFICIENT.METRIC_ID%TYPE,
                                          pi_as_of_date_utc IN DATE DEFAULT trunc(sys_extract_utc(systimestamp)),
                                          po_metric_coefficient OUT CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE)
  IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_metric_coefficient CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE;
    lv_last_effective_date date;
  BEGIN

     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);
     
    BEGIN
    
      SELECT metric_coefficient
       INTO lv_metric_coefficient
      FROM CLIENT_METRIC_COEFFICIENT
      WHERE client_guid = lv_score_owning_guid
       AND metric_id =  pi_metric_id
       AND trunc(effective_date) = pi_as_of_date_utc;
       
       
     EXCEPTION WHEN no_data_found THEN
      
       SELECT max(TRUNC (effective_date))        
         INTO lv_last_effective_date
         FROM CLIENT_METRIC_COEFFICIENT
        WHERE client_guid =  lv_score_owning_guid
          AND metric_id = pi_metric_id
          AND TRUNC (effective_date) <= pi_as_of_date_utc;
          
             SELECT metric_coefficient
       INTO lv_metric_coefficient
      FROM CLIENT_METRIC_COEFFICIENT
      WHERE client_guid = lv_score_owning_guid
       AND metric_id =  pi_metric_id
       AND trunc(effective_date) = lv_last_effective_date;
       
      
     END;
    
   
    po_metric_coefficient :=   lv_metric_coefficient;    
       
  END get_client_metric_coefficient;
  
  PROCEDURE set_client_metric_coefficient(pi_login_guid IN RAW,
                                          pi_metric_id IN CLIENT_METRIC_COEFFICIENT.METRIC_ID%TYPE,
                                          pi_metric_coefficient IN CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE,
                                          pi_username IN VARCHAR,
                                          pi_session_guid IN RAW)
  IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_metric_coefficient   CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE;
   lv_request_timestamp TIMESTAMP := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   lv_old_cmc_pk             RAW(16);
   lv_transaction_log_pk RAW(16);
   lv_request_guid           RAW(16) :=  SYS_GUID;
   lv_new_cmc_pk           RAW(16) :=  SYS_GUID;
   lv_effective_date_in    DATE := TRUNC(sys_extract_utc(systimestamp));
   lv_count                       NUMBER := 0;
  
   
  BEGIN
  
     initialize_logger;
     
     -- Update the transaction log for an existing change to Client Metric Coefficient
     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);
          

   -- Check to see if metric is updated within in a given day (date is based on UTC )
     SELECT count(*)
       INTO  lv_count
       FROM  client_metric_coefficient
      WHERE client_guid = lv_score_owning_guid
        AND metric_id = pi_metric_id
        AND trunc(effective_date)  = lv_effective_date_in;      

    IF lv_count >  0 THEN  -- data exists and just update the current metric data

        UPDATE client_metric_coefficient
             SET metric_id = pi_metric_id,
                   metric_coefficient =  pi_metric_coefficient,
                   created_by_username =    pi_username         
         WHERE client_guid = lv_score_owning_guid
              AND metric_id = pi_metric_id
              AND trunc(effective_date)  = lv_effective_date_in;                          

ELSE      

   BEGIN

   SELECT  CLIENT_METRIC_COEFFICIENT_GUID
       INTO  lv_old_cmc_pk
       FROM  client_metric_coefficient
      WHERE client_guid = lv_score_owning_guid
        AND metric_id = pi_metric_id
        AND termination_date IS NULL;      

     insert_into_transaction_Log (pi_session_guid,
                                  lv_request_guid, 
                                  lv_request_timestamp, 
                                  lv_score_owning_guid, 
                                  'client_metric_cofficient', 
                                  lv_old_cmc_pk,
                                  'End dating old client metric coefficient row.',
                                  lv_transaction_log_pk); 
                                         
      UPDATE client_metric_coefficient
         SET last_txn_guid =  lv_transaction_log_pk, 
             last_txn_date = sys_extract_utc(systimestamp),             
             termination_date  = lv_effective_date_in
       WHERE client_metric_coefficient_guid = lv_old_cmc_pk;
      
      --  Insert a new transaction row for an new Client Metric Coefficient
      
      insert_into_transaction_Log (pi_session_guid,
                                  lv_request_guid, 
                                  lv_request_timestamp, 
                                  lv_score_owning_guid, 
                                  'client_metric_cofficient', 
                                  lv_new_cmc_pk,
                                  'Inserting new client metric coefficient row.',
                                  lv_transaction_log_pk); 

   EXCEPTION WHEN no_data_found THEN
      NULL;
   END;
  
      -- new row of data                    
      INSERT into client_metric_coefficient
      (client_metric_coefficient_guid,
       client_guid,
       metric_id,
       metric_coefficient,
       last_txn_guid,
       effective_date,
       created_by_username) 
      VALUES (lv_new_cmc_pk,
              lv_score_owning_guid,
              pi_metric_id,
              pi_metric_coefficient,
              lv_transaction_log_pk,
              lv_effective_date_in,
              pi_username);  

      --  Insert a new transaction row for an new Client Metric Coefficient
      
      insert_into_transaction_Log (pi_session_guid,
                                  lv_request_guid, 
                                  lv_request_timestamp, 
                                  lv_score_owning_guid, 
                                  'client_metric_cofficient', 
                                  lv_new_cmc_pk,
                                  'updating client metric coefficient row.',
                                  lv_transaction_log_pk);   
END IF;   
/* Commit or rollback must be done by caller. */
    
/* ToDo - proper error handling */

  END set_client_metric_coefficient; 


  procedure GET_CLIENT_METRIC_CONVERSION (pi_login_guid IN RAW,
                                          pi_metric_id IN number,
                                          pi_as_of_date_utc IN DATE DEFAULT trunc(sys_extract_utc(systimestamp)),
                                          po_max_value OUT NUMBER,
                                          po_AB_breakpoint OUT NUMBER,
                                          po_BC_breakpoint OUT NUMBER,
                                          po_CD_breakpoint OUT NUMBER,
                                          po_DF_breakpoint OUT NUMBER,
                                          po_min_value OUT NUMBER)
  IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_max_value  CLIENT_METRIC_CONVERSION.GREATER_THAN_OR_EQUAL%TYPE;
   lv_min_value  CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
   lv_ab_breakpoint  NUMBER;
   lv_bc_breakpoint  NUMBER;
   lv_cd_breakpoint  NUMBER;
   lv_df_breakpoint  NUMBER;
   lv_last_effective_date  DATE;
  BEGIN

     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);

     WITH pivot_data
      AS (SELECT range_grade, greater_than_or_equal, less_than 
            FROM client_metric_conversion
           WHERE client_guid = lv_score_owning_guid
            AND metric_id = pi_metric_id
            AND  trunc(effective_date)  =  pi_as_of_date_utc )
       SELECT  CASE WHEN a_upper_breakpoint > b_upper_breakpoint THEN a_upper_breakpoint ELSE a_lower_breakpoint END AS max_value,
               CASE WHEN a_lower_breakpoint > b_lower_breakpoint THEN a_lower_breakpoint ELSE b_lower_breakpoint END AS ab_breakpoint,
               CASE WHEN b_lower_breakpoint > c_lower_breakpoint THEN b_lower_breakpoint ELSE c_lower_breakpoint END AS bc_breakpoint,
               CASE WHEN c_lower_breakpoint > d_lower_breakpoint THEN c_lower_breakpoint ELSE d_lower_breakpoint END AS cd_breakpoint,
               CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN d_lower_breakpoint ELSE f_lower_breakpoint END AS df_breakpoint,
               CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN f_lower_breakpoint ELSE f_upper_breakpoint END AS min_value
         INTO lv_max_value, lv_AB_breakpoint, lv_BC_breakpoint, lv_CD_breakpoint, lv_DF_breakpoint, lv_min_value
         FROM pivot_data
         PIVOT (MAX(greater_than_or_equal) AS lower_breakpoint,
                MAX(less_than)             AS upper_breakpoint
           FOR  range_grade IN ('A' AS a,
                                'B' AS b,
                                'C' AS c,
                                'D' AS d,
                                'F' AS f));
                                
       -- IF no data found for the as of date being passed, look and return data for previous available effective date
       -- for the client and metric id. 
        IF lv_ab_breakpoint IS NULL THEN   -- Not data found for the given date
               SELECT max(TRUNC (effective_date))                    
                 INTO lv_last_effective_date
                 FROM client_metric_conversion
                WHERE client_guid =  lv_score_owning_guid
                  AND metric_id = pi_metric_id
                  AND TRUNC (effective_date) <= pi_as_of_date_utc;  -- look up the very first row since all five would have the same effective date
        
          WITH pivot_data
            AS (SELECT range_grade, greater_than_or_equal, less_than 
                  FROM client_metric_conversion
                 WHERE client_guid = lv_score_owning_guid
                   AND metric_id = pi_metric_id
                   AND  trunc(effective_date)  =  lv_last_effective_date )
          SELECT  CASE WHEN a_upper_breakpoint > b_upper_breakpoint THEN a_upper_breakpoint ELSE a_lower_breakpoint END AS max_value,
                  CASE WHEN a_lower_breakpoint > b_lower_breakpoint THEN a_lower_breakpoint ELSE b_lower_breakpoint END AS ab_breakpoint,
                  CASE WHEN b_lower_breakpoint > c_lower_breakpoint THEN b_lower_breakpoint ELSE c_lower_breakpoint END AS bc_breakpoint,
                  CASE WHEN c_lower_breakpoint > d_lower_breakpoint THEN c_lower_breakpoint ELSE d_lower_breakpoint END AS cd_breakpoint,
                  CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN d_lower_breakpoint ELSE f_lower_breakpoint END AS df_breakpoint,
                  CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN f_lower_breakpoint ELSE f_upper_breakpoint END AS min_value
         INTO lv_max_value, lv_AB_breakpoint, lv_BC_breakpoint, lv_CD_breakpoint, lv_DF_breakpoint, lv_min_value
         FROM pivot_data
         PIVOT (MAX(greater_than_or_equal) AS lower_breakpoint,
                MAX(less_than)             AS upper_breakpoint
           FOR  range_grade IN ('A' AS a,
                                'B' AS b,
                                'C' AS c,
                                'D' AS d,
                                'F' AS f));
  END IF;

   po_max_value := lv_max_value;
   po_ab_breakpoint := lv_ab_breakpoint; 
   po_BC_breakpoint := lv_bc_breakpoint;
   PO_CD_breakpoint := lv_cd_breakpoint;
   po_DF_breakpoint := lv_df_breakpoint;
   po_min_value := lv_min_value;     
  
  END get_client_metric_conversion;

 procedure GET_CLIENT_METRIC_SCORE (pi_login_guid IN RAW,
                                   pi_metric_id IN number,
                                   pi_as_of_date_utc IN DATE DEFAULT TRUNC(sys_extract_utc(systimestamp)),
                                   po_A_score OUT NUMBER,
                                   po_B_score OUT NUMBER,
                                   po_C_score OUT NUMBER,
                                   po_D_score OUT NUMBER,
                                   po_F_score OUT NUMBER
                                   )
IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_a_score  NUMBER;
   lv_b_score  NUMBER;
   lv_c_score  NUMBER;
   lv_d_score  NUMBER;
   lv_f_score  NUMBER;
   lv_last_effective_date DATE;

  BEGIN

     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);     
    
     BEGIN       
     SELECT a_score,b_score,c_score,d_score,f_score
       INTO lv_a_score, lv_b_score,lv_c_score,lv_d_score,lv_f_score
       FROM (SELECT client_guid,
                       metric_id ,
                       range_grade,
                       range_score,
                       termination_date,
                       effective_date                   
                  FROM client_metric_conversion
                 WHERE client_guid = lv_score_owning_guid
                   AND metric_id =  pi_metric_id                           
                   AND trunc(effective_date) = pi_as_of_date_utc )
      PIVOT (MIN (range_score)
        FOR range_grade IN  ('A' as a_score,
                             'B' as b_score,
                             'C' as c_score,
                             'D' as d_score,
                             'F' as f_score));
     
   EXCEPTION WHEN no_data_found THEN     
         
    -- look up the very first row since all five would have the same effective date
     SELECT max(TRUNC (effective_date))                    
       INTO lv_last_effective_date
       FROM client_metric_conversion
      WHERE client_guid =  lv_score_owning_guid
        AND metric_id = pi_metric_id
        AND TRUNC (effective_date) <= pi_as_of_date_utc;  
                               
     SELECT a_score,b_score,c_score,d_score,f_score
       INTO lv_a_score, lv_b_score,lv_c_score,lv_d_score,lv_f_score
       FROM (SELECT client_guid,
                       metric_id ,
                       range_grade,
                       range_score,
                       termination_date,
                       effective_date                   
                  FROM client_metric_conversion
                 WHERE client_guid = lv_score_owning_guid
                   AND metric_id =  pi_metric_id                           
                   AND trunc(effective_date) = lv_last_effective_date )
      PIVOT (MIN (range_score)
        FOR range_grade IN  ('A' as a_score,
                             'B' as b_score,
                             'C' as c_score,
                             'D' as d_score,
                             'F' as f_score));
   END;
   po_a_score := lv_a_score; 
   po_b_score := lv_b_score;
   Po_c_score := lv_c_score;
   po_d_score := lv_d_score;
   po_f_score := lv_f_score;  
   
/* ToDo - proper error handling */

END GET_CLIENT_METRIC_SCORE;

procedure SET_ALL_METRIC_CONVERSION (pi_login_guid IN RAW,
                                   pi_metric_id IN NUMBER,                                     
                                   pi_username IN VARCHAR,
                                   pi_session_guid IN RAW,
                                   pi_A_score IN NUMBER,
                                   pi_B_score IN NUMBER,
                                   pi_C_score IN NUMBER,
                                   pi_D_score IN NUMBER,
                                   pi_F_score IN NUMBER,
                                   pi_AB_breakpoint IN NUMBER,
                                   pi_BC_breakpoint IN NUMBER,
                                   pi_CD_breakpoint IN NUMBER,
                                   pi_DF_breakpoint IN NUMBER                                 
                                   )
IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_metric_coefficient CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE;
   lv_request_timestamp TIMESTAMP := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   lv_old_cmv_pk          RAW(16);
   lv_transaction_log_pk  RAW(16);
   lv_request_guid        RAW(16) :=  SYS_GUID;
   lv_new_cmv_pk          RAW(16);
   TYPE grades_arr_type IS VARRAY(5) OF VARCHAR2(1);
   grades_arr grades_arr_type := grades_arr_type('A','B','C','D','F');
   empty_set grades_arr_type;   
   lv_effective_date_in   DATE := trunc(sys_extract_utc(systimestamp)); 
   empty_set grades_arr_type;   
   lv_bigger_is_better BOOLEAN;
   lv_range_score NUMBER;
   lv_temp_gte    NUMBER;
   lv_temp_lt     NUMBER;
   lv_max         NUMBER;
   lv_min         NUMBER;
   lv_count       NUMBER := 0;
   lv_first_time_insert  NUMBER := 0;
   
 BEGIN

   initialize_logger;
     
   lv_score_owning_guid := get_score_owning_guid(pi_login_guid);
        
   IF  pi_AB_breakpoint > pi_DF_breakpoint THEN 
         lv_bigger_is_better := TRUE;
   ELSE lv_bigger_is_better := FALSE; 
   END IF;
   
   -- Check to see if this client has data for given metric and date 
   SELECT  count(*)
     INTO lv_count      
     FROM  client_metric_conversion
    WHERE client_guid = lv_score_owning_guid
     AND metric_id = pi_metric_id
     AND trunc(effective_date) = lv_effective_date_in;
     
   -- If data exists for client for a given date then update it otherwise add a new row   
   IF lv_count > 0 THEN
       -- Update the transaction log and insert new change for a given new date to Client Metric conversion
               
     FOR i in grades_arr.FIRST .. grades_arr.LAST 
     LOOP 
         lv_new_cmv_pk := SYS_GUID; 
       
         SELECT  CLIENT_METRIC_CONVERSION_GUID, range_score, greater_than_or_equal, less_than
           INTO lv_old_cmv_pk, lv_range_score, lv_temp_gte, lv_temp_lt     
           FROM  client_metric_conversion
          WHERE client_guid = lv_score_owning_guid
            AND metric_id = pi_metric_id
            AND range_grade = grades_arr(i) 
           --  AND termination_date IS NULL;
           AND trunc(effective_date) = lv_effective_date_in;
            
         IF grades_arr(i) = 'A' THEN
           IF lv_bigger_is_better THEN
             lv_max := lv_temp_lt;
           ELSE
             lv_max := lv_temp_gte;
           END IF;
         END IF;      
        
        IF grades_arr(i) = 'F' THEN
           IF lv_bigger_is_better THEN
             lv_min := lv_temp_gte;
           ELSE
             lv_min := lv_temp_lt;
           END IF;
        END IF;
    
        insert_into_transaction_Log (pi_session_guid,
                                   lv_request_guid, 
                                   lv_request_timestamp, 
                                   lv_score_owning_guid, 
                                   'client_metric_conversion', 
                                   lv_old_cmv_pk, 
                                   'End dating old client metric conversion score for grade range = ' ||  grades_arr(i),
                                   lv_transaction_log_pk);

         IF  grades_arr(i) = 'A' THEN
           lv_range_score := pi_A_score;
         ELSIF grades_arr(i) = 'B' THEN
           lv_range_score := pi_B_score;
         ELSIF  grades_arr(i) = 'C' THEN
           lv_range_score := pi_C_score;
         ELSIF grades_arr(i) = 'D' THEN
           lv_range_score := pi_D_score;
         ELSIF grades_arr(i) = 'F' THEN
           lv_range_score := pi_F_score;
         ELSE 
           NULL;
         END IF;
         
         IF lv_bigger_is_better
         THEN 
           CASE 
             WHEN grades_arr(I) = 'A' THEN lv_temp_gte := pi_ab_breakpoint; lv_temp_lt := lv_max;
             WHEN grades_arr(I) = 'B' THEN lv_temp_gte := pi_bc_breakpoint; lv_temp_lt := pi_ab_breakpoint;
             WHEN grades_arr(I) = 'C' THEN lv_temp_gte := pi_cd_breakpoint; lv_temp_lt := pi_bc_breakpoint;
             WHEN grades_arr(I) = 'D' THEN lv_temp_gte := pi_df_breakpoint; lv_temp_lt := pi_cd_breakpoint;
             WHEN grades_arr(I) = 'F' THEN lv_temp_gte := lv_min;           lv_temp_lt := pi_df_breakpoint;
         END CASE;  
         ELSE
           CASE 
             WHEN grades_arr(I) = 'A' THEN lv_temp_gte := lv_max;           lv_temp_lt := pi_ab_breakpoint;
             WHEN grades_arr(I) = 'B' THEN lv_temp_gte := pi_ab_breakpoint; lv_temp_lt := pi_bc_breakpoint;
             WHEN grades_arr(I) = 'C' THEN lv_temp_gte := pi_bc_breakpoint; lv_temp_lt := pi_cd_breakpoint;
             WHEN grades_arr(I) = 'D' THEN lv_temp_gte := pi_cd_breakpoint; lv_temp_lt := pi_df_breakpoint;
             WHEN grades_arr(I) = 'F' THEN lv_temp_gte := pi_df_breakpoint; lv_temp_lt := lv_min;
           END CASE;  
      
         END IF;
       
         UPDATE client_metric_conversion
           SET   range_score =  lv_range_score,
                 greater_than_or_equal = lv_temp_gte,
                 less_than = lv_temp_lt,
                 created_by_username = pi_username
          WHERE client_guid = lv_score_owning_guid
            AND metric_id = pi_metric_id
            AND range_grade = grades_arr(i) 
            AND trunc(effective_date) = lv_effective_date_in;        
                    
     END LOOP;  
   ELSE     -- This case when first time insert for a metric or a new day for a client that has data already
     FOR i in grades_arr.FIRST .. grades_arr.LAST 
     LOOP 
         lv_new_cmv_pk := SYS_GUID; 
         
        BEGIN
         SELECT  CLIENT_METRIC_CONVERSION_GUID, range_score, greater_than_or_equal, less_than
           INTO lv_old_cmv_pk, lv_range_score, lv_temp_gte, lv_temp_lt     
           FROM  client_metric_conversion
          WHERE client_guid = lv_score_owning_guid
            AND metric_id = pi_metric_id
            AND range_grade = grades_arr(i) 
            AND termination_date IS NULL;
         EXCEPTION WHEN no_data_found THEN
             lv_first_time_insert := 1;
         END;
            
         IF grades_arr(i) = 'A' THEN
           IF lv_bigger_is_better THEN
             lv_max := lv_temp_lt;
           ELSE
             lv_max := lv_temp_gte;
           END IF;
         END IF;
      
        
        IF grades_arr(i) = 'F' THEN
           IF lv_bigger_is_better THEN
             lv_min := lv_temp_gte;
           ELSE
             lv_min := lv_temp_lt;
           END IF;
        END IF;
    
        -- This is when data exists for prior day for this customer however not the very first time data inserted
        IF lv_first_time_insert  <> 1 THEN 
           insert_into_transaction_Log (pi_session_guid,
                                   lv_request_guid, 
                                   lv_request_timestamp, 
                                   lv_score_owning_guid, 
                                   'client_metric_conversion', 
                                   lv_old_cmv_pk, 
                                   'End dating old client metric conversion score for grade range = ' ||  grades_arr(i),
                                   lv_transaction_log_pk);
                                             
         UPDATE client_metric_conversion
            SET last_txn_guid =  lv_transaction_log_pk, 
                last_txn_date = sys_extract_utc(systimestamp),             
                termination_date  = lv_effective_date_in
          WHERE client_metric_conversion_guid = lv_old_cmv_pk;
       END IF;
      
      --  Insert a new transaction row for an new Client Metric conversion and score
--      
      insert_into_transaction_Log (pi_session_guid,
                                   lv_request_guid, 
                                   lv_request_timestamp, 
                                   lv_score_owning_guid, 
                                   'client_metric_conversion', 
                                   lv_new_cmv_pk, 
                                   'Inserting new client conversion score for grade range = ' ||  grades_arr(i),
                                   lv_transaction_log_pk);
--                                   
         IF  grades_arr(i) = 'A' THEN
           lv_range_score := pi_A_score;
         ELSIF grades_arr(i) = 'B' THEN
           lv_range_score := pi_B_score;
         ELSIF  grades_arr(i) = 'C' THEN
           lv_range_score := pi_C_score;
         ELSIF grades_arr(i) = 'D' THEN
           lv_range_score := pi_D_score;
         ELSIF grades_arr(i) = 'F' THEN
           lv_range_score := pi_F_score;
         ELSE 
           NULL;
         END IF;
         
         IF lv_bigger_is_better
         THEN 
           CASE 
             WHEN grades_arr(I) = 'A' THEN lv_temp_gte := pi_ab_breakpoint; lv_temp_lt := lv_max;
             WHEN grades_arr(I) = 'B' THEN lv_temp_gte := pi_bc_breakpoint; lv_temp_lt := pi_ab_breakpoint;
             WHEN grades_arr(I) = 'C' THEN lv_temp_gte := pi_cd_breakpoint; lv_temp_lt := pi_bc_breakpoint;
             WHEN grades_arr(I) = 'D' THEN lv_temp_gte := pi_df_breakpoint; lv_temp_lt := pi_cd_breakpoint;
             WHEN grades_arr(I) = 'F' THEN lv_temp_gte := lv_min;           lv_temp_lt := pi_df_breakpoint;
         END CASE;  
         ELSE
           CASE 
             WHEN grades_arr(I) = 'A' THEN lv_temp_gte := lv_max;           lv_temp_lt := pi_ab_breakpoint;
             WHEN grades_arr(I) = 'B' THEN lv_temp_gte := pi_ab_breakpoint; lv_temp_lt := pi_bc_breakpoint;
             WHEN grades_arr(I) = 'C' THEN lv_temp_gte := pi_bc_breakpoint; lv_temp_lt := pi_cd_breakpoint;
             WHEN grades_arr(I) = 'D' THEN lv_temp_gte := pi_cd_breakpoint; lv_temp_lt := pi_df_breakpoint;
             WHEN grades_arr(I) = 'F' THEN lv_temp_gte := pi_df_breakpoint; lv_temp_lt := lv_min;
           END CASE;  
      
         END IF;
       
  
        INSERT INTO client_metric_conversion
          (client_metric_conversion_guid,  
           greater_than_or_equal, 
           less_than,
           range_grade, 
           range_score, 
           last_txn_guid,
           effective_date, 
           created_by_username,
           metric_id, 
           client_guid)
         VALUES
          (lv_new_cmv_pk, 
           lv_temp_gte, 
           lv_temp_lt,
           grades_arr(i),
           lv_range_score,
           lv_transaction_log_pk,
           lv_effective_date_in,
           pi_username,
           pi_metric_id, 
           lv_score_owning_guid );    
                
     END LOOP;  
  END IF;
/* Commit or rollback must be done by caller. */
    
/* ToDo - proper error handling */

END SET_ALL_METRIC_CONVERSION;

PROCEDURE get_supplier_scorecard_comment (pi_login_guid IN RAW,
                                          pi_as_of_date_utc IN DATE  DEFAULT trunc(sys_extract_utc(systimestamp)),
                                          po_comments OUT VARCHAR)
  IS
  lv_comments  VARCHAR2(4000);
  lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
  lv_last_effective_date date;
  
    BEGIN

     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);     

   BEGIN

     SELECT comments
       INTO lv_comments 
     FROM supplier_scorecard_comments
   WHERE client_guid = lv_score_owning_guid
   and TRUNC(effective_date) = pi_as_of_date_utc;

EXCEPTION WHEN no_data_found THEN

    SELECT max (TRUNC (effective_date))        
       INTO lv_last_effective_date
       FROM supplier_scorecard_comments
      WHERE client_guid =  lv_score_owning_guid
        AND TRUNC (effective_date) <= pi_as_of_date_utc;  

   SELECT comments
       INTO lv_comments 
     FROM supplier_scorecard_comments
   WHERE client_guid = lv_score_owning_guid
       AND TRUNC(effective_date) = lv_last_effective_date;

END;

  po_comments := lv_comments;

END get_supplier_scorecard_comment;


PROCEDURE set_supplier_scorecard_comment (pi_login_guid IN RAW,
                                          pi_username IN VARCHAR,
                                          pi_session_guid IN RAW,
                                          pi_comments  IN VARCHAR)
IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_effective_date_in  date := trunc(SYS_EXTRACT_UTC(SYSTIMESTAMP));
   lv_ssc_comment_pk          RAW(16) :=  SYS_GUID;   
   lv_count number := 0;
   lv_request_timestamp TIMESTAMP := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   lv_old_ssc_cmnt_pk          RAW(16);
   lv_new_ssc_cmnt_pk          RAW(16);
   lv_transaction_log_pk  RAW(16);
   lv_request_guid        RAW(16) :=  SYS_GUID;
   lv_first_time_insert  NUMBER := 0;
BEGIN


  lv_score_owning_guid := get_score_owning_guid(pi_login_guid);       

  SELECT COUNT(*)
   INTO lv_count
  FROM supplier_scorecard_comments
 WHERE  client_guid = lv_score_owning_guid 
   and trunc(last_txn_date)  =  lv_effective_date_in; 

--brand new customer comment
  IF lv_count = 0 THEN 
  
     lv_new_ssc_cmnt_pk := SYS_GUID; 
  
     insert_into_transaction_Log (pi_session_guid,
                                  lv_request_guid, 
                                  lv_request_timestamp, 
                                  lv_score_owning_guid, 
                                  'supplier_scorecard_comments', 
                                  lv_new_ssc_cmnt_pk, 
                                  'Inserting new Supplier Scorecard comment.',
                                  lv_transaction_log_pk);
                                   
 
     INSERT INTO supplier_scorecard_comments (  
        CLIENT_COMMENT_GUID,
        CLIENT_GUID,
        LAST_TXN_GUID,
        LAST_TXN_DATE,
        CREATED_BY_USERNAME,
        COMMENTS,
        EFFECTIVE_DATE       
     )
     VALUES(lv_new_ssc_cmnt_pk,
            lv_score_owning_guid,
            lv_transaction_log_pk, 
            sys_extract_utc(systimestamp),             
            pi_username,
            pi_comments,
            lv_effective_date_in
            );

  ELSE  -- existing client update the comment and date
    BEGIN
    SELECT client_comment_guid
      INTO lv_old_ssc_cmnt_pk
      FROM supplier_scorecard_comments
     WHERE  client_guid = lv_score_owning_guid 
       AND effective_date  =  lv_effective_date_in; 
   
   EXCEPTION WHEN no_data_found THEN
     lv_first_time_insert := 1;
   END;
            
  IF  lv_first_time_insert <> 0 THEN
    insert_into_transaction_Log (pi_session_guid,
                                   lv_request_guid, 
                                   lv_request_timestamp, 
                                   lv_score_owning_guid, 
                                   'supplier_scorecard_comments', 
                                   lv_old_ssc_cmnt_pk, 
                                   'End Date Old and Inserting new Supplier Scorecard comment.',
                                   lv_transaction_log_pk);
    
       UPDATE supplier_scorecard_comments
         SET last_txn_guid =  lv_transaction_log_pk, 
             last_txn_date = sys_extract_utc(systimestamp),             
             termination_date  = lv_effective_date_in
       WHERE client_comment_guid = lv_old_ssc_cmnt_pk;
   
  END IF;
      
  UPDATE supplier_scorecard_comments
    SET comments               = pi_comments,
        created_by_username    = pi_username
  WHERE client_guid = lv_score_owning_guid
    AND effective_date =  lv_effective_date_in ;
    
  END IF;  

END set_supplier_scorecard_comment;

--   Please make sure the follwoing two procs are removed once msvc-3166 is deployed which suppose to use
--   SET_ALL_METRIC_CONVERSION  which is a combination of metric conversion and metric score.

procedure SET_CLIENT_METRIC_CONVERSION(pi_login_guid IN RAW,
                                       pi_metric_id IN NUMBER,
                                       pi_username IN VARCHAR,
                                       pi_session_guid IN RAW,
                                       pi_AB_breakpoint IN NUMBER,
                                       pi_BC_breakpoint IN NUMBER,
                                       pi_CD_breakpoint IN NUMBER,
                                       pi_DF_breakpoint IN NUMBER,
                                       pi_comments IN VARCHAR2
)  IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_metric_coefficient CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE;
   lv_request_timestamp TIMESTAMP := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   lv_old_cmv_pk          RAW(16);
   lv_transaction_log_pk  RAW(16);
   lv_request_guid        RAW(16) :=  SYS_GUID;
   lv_new_cmv_pk          RAW(16);
   TYPE grades_arr_type IS VARRAY(5) OF VARCHAR2(1);
   grades_arr grades_arr_type := grades_arr_type('A','B','C','D','F');
   empty_set grades_arr_type;   
   lv_bigger_is_better BOOLEAN;
   lv_range_score NUMBER;
   lv_temp_gte    NUMBER;
   lv_temp_lt     NUMBER;
   lv_max         NUMBER;
   lv_min         NUMBER;
   ln_cnt         NUMBER;
   lv_effective_date_in   DATE := CAST(sys_extract_utc(systimestamp) AS DATE); 
  
   
  BEGIN
  
     initialize_logger;
     
     -- Update the transaction log for an existing change to Client Metric Coefficient
     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);
          
     IF  pi_AB_breakpoint > pi_DF_breakpoint THEN 
         lv_bigger_is_better := TRUE;
     ELSE lv_bigger_is_better := FALSE; 
     END IF;
  
     FOR i in grades_arr.FIRST .. grades_arr.LAST 
     LOOP 
     
       lv_new_cmv_pk := SYS_GUID; 
       
      SELECT  CLIENT_METRIC_CONVERSION_GUID, range_score, greater_than_or_equal, less_than
        INTO lv_old_cmv_pk, lv_range_score, lv_temp_gte, lv_temp_lt     
        FROM  client_metric_conversion
       WHERE client_guid = lv_score_owning_guid
         AND metric_id = pi_metric_id
         AND range_grade = grades_arr(i) 
         AND termination_date IS NULL;
              
      IF grades_arr(i) = 'A' THEN
         IF lv_bigger_is_better THEN
             lv_max := lv_temp_lt;
         ELSE
             lv_max := lv_temp_gte;
         END IF;
      END IF;
      
        
        IF grades_arr(i) = 'F' THEN
         IF lv_bigger_is_better THEN
             lv_min := lv_temp_gte;
         ELSE
             lv_min := lv_temp_lt;
         END IF;
      END IF;


      insert_into_transaction_Log (pi_session_guid,
                                   lv_request_guid, 
                                   lv_request_timestamp, 
                                   lv_score_owning_guid, 
                                   'client_metric_conversion', 
                                   lv_old_cmv_pk, 
                                   'End dating old client metric conversion row for grade range = ' ||  grades_arr(i),
                                   lv_transaction_log_pk);
                                             
      UPDATE client_metric_conversion
         SET last_txn_guid =  lv_transaction_log_pk, 
             last_txn_date = sys_extract_utc(systimestamp),             
             termination_date  = lv_effective_date_in
       WHERE client_metric_conversion_guid = lv_old_cmv_pk;
      
      --  Insert a new transaction row for an new Client Metric Coefficient
      
      insert_into_transaction_Log (pi_session_guid,
                                   lv_request_guid, 
                                   lv_request_timestamp, 
                                   lv_score_owning_guid, 
                                   'client_metric_conversion', 
                                   lv_new_cmv_pk, 
                                   'Inserting new client conversion row for grade range = ' ||  grades_arr(i),
                                   lv_transaction_log_pk);
                                   
      
    IF lv_bigger_is_better
    THEN 
       CASE 
        WHEN grades_arr(I) = 'A' THEN lv_temp_gte := pi_ab_breakpoint; lv_temp_lt := lv_max;
        WHEN grades_arr(I) = 'B' THEN lv_temp_gte := pi_bc_breakpoint; lv_temp_lt := pi_ab_breakpoint;
        WHEN grades_arr(I) = 'C' THEN lv_temp_gte := pi_cd_breakpoint; lv_temp_lt := pi_bc_breakpoint;
        WHEN grades_arr(I) = 'D' THEN lv_temp_gte := pi_df_breakpoint; lv_temp_lt := pi_cd_breakpoint;
        WHEN grades_arr(I) = 'F' THEN lv_temp_gte := lv_min;           lv_temp_lt := pi_df_breakpoint;
      end case;  
      ELSE
      CASE 
        WHEN grades_arr(I) = 'A' THEN lv_temp_gte := lv_max;           lv_temp_lt := pi_ab_breakpoint;
        WHEN grades_arr(I) = 'B' THEN lv_temp_gte := pi_ab_breakpoint; lv_temp_lt := pi_bc_breakpoint;
        WHEN grades_arr(I) = 'C' THEN lv_temp_gte := pi_bc_breakpoint; lv_temp_lt := pi_cd_breakpoint;
        WHEN grades_arr(I) = 'D' THEN lv_temp_gte := pi_cd_breakpoint; lv_temp_lt := pi_df_breakpoint;
        WHEN grades_arr(I) = 'F' THEN lv_temp_gte := pi_df_breakpoint; lv_temp_lt := lv_min;
      end case;  
      
      END IF;
      
        
       INSERT INTO client_metric_conversion
          (client_metric_conversion_guid,  
           greater_than_or_equal, 
           less_than,
           range_grade, 
           range_score, 
           last_txn_guid,
           effective_date, 
           created_by_username,
           metric_id, 
           client_guid)
        VALUES
          (lv_new_cmv_pk, 
           lv_temp_gte, 
           lv_temp_lt,
           grades_arr(i),
           lv_range_score,
           lv_transaction_log_pk,
           lv_effective_date_in + interval '1' second,
           pi_username,
           pi_metric_id, 
           lv_score_owning_guid );    
        
  
  END LOOP;

  COMMIT;
              
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    logger_pkg.error(pi_message => 'Set procedure failed.' || SQLERRM,
                     pi_transaction_result => 'ROLLBACK',
                     pi_error_code => SQLCODE);
    RAISE;
    
  END set_client_metric_conversion; 

procedure SET_CLIENT_METRIC_SCORE (pi_login_guid IN RAW,
                                   pi_metric_id IN NUMBER,                                     
                                   pi_username IN VARCHAR,
                                   pi_session_guid IN RAW,
                                   pi_A_score IN NUMBER,
                                   pi_B_score IN NUMBER,
                                   pi_C_score IN NUMBER,
                                   pi_D_score IN NUMBER,
                                   pi_F_score IN NUMBER
                                   )
IS
   lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
   lv_metric_coefficient CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE;
   lv_request_timestamp TIMESTAMP := SYS_EXTRACT_UTC(SYSTIMESTAMP);
   lv_old_cmv_pk          RAW(16);
   lv_transaction_log_pk  RAW(16);
   lv_request_guid        RAW(16) :=  SYS_GUID;
   lv_new_cmv_pk          RAW(16);
   TYPE grades_arr_type IS VARRAY(5) OF VARCHAR2(1);
   grades_arr grades_arr_type := grades_arr_type('A','B','C','D','F');
   empty_set grades_arr_type;   
   lv_effective_date_in   DATE := CAST(sys_extract_utc(systimestamp) AS DATE); 
   lv_range_score NUMBER;
   lv_temp_gte    NUMBER;
   lv_temp_lt     NUMBER;


BEGIN
     initialize_logger;
     
     -- Update the transaction log for an existing change to Client Metric Coefficient
     lv_score_owning_guid := get_score_owning_guid(pi_login_guid);
               
     FOR i in grades_arr.FIRST .. grades_arr.LAST 
     LOOP 
      lv_new_cmv_pk := SYS_GUID; 
       
      SELECT  CLIENT_METRIC_CONVERSION_GUID, range_score, greater_than_or_equal, less_than
        INTO lv_old_cmv_pk, lv_range_score, lv_temp_gte, lv_temp_lt     
        FROM  client_metric_conversion
       WHERE client_guid = lv_score_owning_guid
         AND metric_id = pi_metric_id
         AND range_grade = grades_arr(i) 
         AND termination_date IS NULL;
    
      insert_into_transaction_Log (pi_session_guid,
                                   lv_request_guid, 
                                   lv_request_timestamp, 
                                   lv_score_owning_guid, 
                                   'client_metric_conversion', 
                                   lv_old_cmv_pk, 
                                   'End dating old client metric conversion score for grade range = ' ||  grades_arr(i),
                                   lv_transaction_log_pk);
                                             
      UPDATE client_metric_conversion
         SET last_txn_guid =  lv_transaction_log_pk, 
             last_txn_date = sys_extract_utc(systimestamp),             
             termination_date  = lv_effective_date_in
       WHERE client_metric_conversion_guid = lv_old_cmv_pk;
      
      --  Insert a new transaction row for an new Client Metric Coefficient
      
      insert_into_transaction_Log (pi_session_guid,
                                   lv_request_guid, 
                                   lv_request_timestamp, 
                                   lv_score_owning_guid, 
                                   'client_metric_conversion', 
                                   lv_new_cmv_pk, 
                                   'Inserting new client conversion score for grade range = ' ||  grades_arr(i),
                                   lv_transaction_log_pk);
                                   
       IF  grades_arr(i) = 'A' THEN
          lv_range_score := pi_A_score;
       ELSIF grades_arr(i) = 'B' THEN
          lv_range_score := pi_B_score;
       ELSIF  grades_arr(i) = 'C' THEN
          lv_range_score := pi_C_score;
       ELSIF grades_arr(i) = 'D' THEN
          lv_range_score := pi_D_score;
       ELSIF grades_arr(i) = 'F' THEN
          lv_range_score := pi_F_score;
       ELSE 
        NULL;
       END IF;
       
  
       INSERT INTO client_metric_conversion
          (client_metric_conversion_guid,  
           greater_than_or_equal, 
           less_than,
           range_grade, 
           range_score, 
           last_txn_guid,
           effective_date, 
           created_by_username,
           metric_id, 
           client_guid)
        VALUES
          (lv_new_cmv_pk, 
           lv_temp_gte, 
           lv_temp_lt,
           grades_arr(i),
           lv_range_score,
           lv_transaction_log_pk,
           lv_effective_date_in + interval '1' second,
           pi_username,
           pi_metric_id, 
           lv_score_owning_guid );    
                
  END LOOP;
  
  COMMIT;
              
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    logger_pkg.error(pi_message => 'Set procedure failed for SET_CLIENT_METRIC_SCORE.' || SQLERRM,
                     pi_transaction_result => 'ROLLBACK',
                     pi_error_code => SQLCODE);
    RAISE;

END SET_CLIENT_METRIC_SCORE;

PROCEDURE get_client_historical_data(pi_login_guid IN RAW,po_result_set OUT SYS_REFCURSOR)
IS
     lv_sql    CLOB;
     
     lv_score_owning_guid client_visibility_list.score_config_owner_guid%type;
     
BEGIN

    lv_score_owning_guid := get_score_owning_guid(pi_login_guid);
       
   -- Only show data if anything changed (category coefficient, metric coefficient and metric conversion) at 
   -- cateogry and metric name level as per requirement.  Initial version is not considered changed, the only
   -- exception as part of  msvc-3594 changed code to show comments regardless of inital status of metrics
   -- being changed.  It will show comments if one exists.

OPEN po_result_set FOR 
SELECT effective_date,
       changed_category_metric,
       created_by_username,                                       
       CASE
          WHEN ccd_ind = 'I' AND cmd_ind = 'I' AND mcod_ind = 'I'
          THEN
             'This date and version correlate to your program''s initial default metric values and scores.'
          ELSE
             comments
       END
          AS comments
  FROM (  SELECT COALESCE (ssc_data.client_guid, ssc.client_guid)
                    AS client_guid,
                 COALESCE (ssc_data.effective_date, ssc.effective_date)
                    AS effective_date,
                 changed_category_metric,
                 COALESCE (ssc_data.created_by_username,
                           ssc.created_by_username)
                    AS created_by_username,
                 ssc.comments,
                 ssc_data.ccd_ind,
                 ssc_data.cmd_ind,
                 ssc_data.mcod_ind
            FROM (WITH client_ctgy_coefficient_data
                       AS (SELECT client_guid,
                                  metric_category,
                                  TRUNC (effective_date) AS effective_date,
                                  category_coefficient,
                                  created_by_username,
                                  CASE
                                     WHEN old_category_coefficient IS NULL
                                     THEN
                                        'I'
                                     WHEN category_coefficient <>
                                             old_category_coefficient
                                     THEN
                                        'Y'
                                     ELSE
                                        'N'
                                  END
                                     change_indicator
                             FROM (SELECT client_guid,
                                          ccc.metric_category,
                                          category_coefficient,
                                          TRUNC (effective_date)
                                             AS effective_date,
                                          LAG (
                                             metric_category)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_category
                                             ORDER BY effective_date)
                                             AS old_metric_category,
                                          LAG (
                                             category_coefficient)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_category
                                             ORDER BY effective_date)
                                             AS old_category_coefficient,
                                          created_by_username
                                     FROM client_category_coefficient ccc
                                    WHERE client_guid = lv_score_owning_guid                                            
                                  )),      
                       client_metric_coefficient_data
                       AS (SELECT client_guid,
                                  metric_id,
                                  TRUNC (effective_date) AS effective_date,
                                  metric_coefficient,
                                  created_by_username,
                                  CASE
                                     WHEN old_metric_coefficient IS NULL
                                     THEN
                                        'I'
                                     WHEN (    metric_id = old_metric_id
                                           AND metric_coefficient <>
                                                  old_metric_coefficient)
                                     THEN
                                        'Y'
                                     ELSE
                                        'N'
                                  END
                                     change_indicator
                             FROM (SELECT client_guid,
                                          metric_id,
                                          metric_coefficient,
                                          TRUNC (effective_date)
                                             AS effective_date,
                                          LAG (
                                             metric_id)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_id
                                             ORDER BY effective_date)
                                             AS old_metric_id,
                                          LAG (
                                             metric_coefficient)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_id
                                             ORDER BY effective_date)
                                             AS old_metric_coefficient,
                                          created_by_username
                                     FROM client_metric_coefficient
                                    WHERE client_guid =  lv_score_owning_guid                                             
                                  )),
                       client_conversion_data
                       AS (SELECT client_guid,
                                  metric_id,
                                  effective_date,
                                  range_score,
                                  range_grade,
                                  greater_than_or_equal,
                                  less_than,
                                  created_by_username,
                                  CASE
                                     WHEN old_range_score IS NULL
                                     THEN
                                        'I'
                                     WHEN    (    metric_id = old_metric_id
                                              AND range_score <>
                                                     old_range_score)
                                          OR (    metric_id = old_metric_id
                                              AND greater_than_or_equal <>
                                                     old_greater_than_or_equal)
                                          OR (    metric_id = old_metric_id
                                              AND less_than <> old_less_than)
                                     THEN
                                        'Y'
                                     ELSE
                                        'N'
                                  END
                                     change_indicator
                             FROM (SELECT client_guid,
                                          metric_id,
                                          range_score,
                                          greater_than_or_equal,
                                          less_than,
                                          range_grade,
                                          TRUNC (effective_date)
                                             AS effective_date,
                                          LAG (
                                             metric_id)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_id
                                             ORDER BY range_grade)
                                             AS old_metric_id,
                                          LAG (
                                             range_score)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_id,
                                                          range_grade
                                             ORDER BY effective_date)
                                             AS old_range_score,
                                          LAG (
                                             range_grade)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_id,
                                                          range_grade
                                             ORDER BY effective_date)
                                             AS old_range_grade,
                                          LAG (
                                             greater_than_or_equal)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_id,
                                                          range_grade
                                             ORDER BY effective_date)
                                             AS old_greater_than_or_equal,
                                          LAG (
                                             less_than)
                                          OVER (
                                             PARTITION BY client_guid,
                                                          metric_id,
                                                          range_grade
                                             ORDER BY effective_date)
                                             AS old_less_than,
                                          created_by_username,
                                          TRUNC (effective_date)
                                     FROM client_metric_conversion
                                    WHERE client_guid = lv_score_owning_guid                                             
                                  ))
                  SELECT DISTINCT
                         COALESCE (ccd.client_guid,
                                   cmd.client_guid,
                                   mcod.client_guid)
                            AS client_guid,
                         CASE
                            WHEN ccd.change_indicator = 'Y'
                            THEN
                               ccd.effective_date
                            WHEN cmd.change_indicator = 'Y'
                            THEN
                               cmd.effective_date
                            ELSE
                               mcod.effective_date
                         END
                            AS effective_date,
                         ccd.metric_category || ' - ' || m.metric_name
                            AS changed_category_metric,
                         CASE
                            WHEN ccd.change_indicator = 'Y'
                            THEN
                               ccd.created_by_username
                            WHEN cmd.change_indicator = 'Y'
                            THEN
                               cmd.created_by_username
                            ELSE
                               mcod.created_by_username
                         END
                            AS created_by_username,
                         ccd.change_indicator AS ccd_ind,
                         cmd.change_indicator AS cmd_ind,
                         mcod.change_indicator AS mcod_ind
                    FROM metric m,
                         client_ctgy_coefficient_data ccd,
                         client_metric_coefficient_data cmd,
                         client_conversion_data mcod
                   WHERE     ccd.client_guid = cmd.client_guid
                         AND cmd.client_guid = mcod.client_guid(+)
                         AND ccd.metric_category = m.metric_category(+)
                         AND m.metric_id = cmd.metric_id
                         AND cmd.metric_id = mcod.metric_id
                         AND ((
                                ccd.change_indicator = 'I' AND
                                cmd.change_indicator = 'I' AND
                                mcod.change_indicator = 'I')
                              OR (   ccd.change_indicator = 'Y'
                                  OR cmd.change_indicator = 'Y'
                                  OR mcod.change_indicator = 'Y'
                                  ))) ssc_data,
                           supplier_scorecard_comments ssc
           WHERE  ssc_data.client_guid = ssc.client_guid(+)
             AND ssc_data.effective_date = ssc.effective_date(+)
        ORDER BY effective_date DESC); 

      
EXCEPTION  WHEN OTHERS THEN
   logger_pkg.error(pi_message => 'Error getting historical data in get_client_historical_data procedure.' || SQLERRM,
                     pi_transaction_result =>  NULL,
                     pi_error_code => SQLCODE);
    RAISE;

END get_client_historical_data;

END client_metric_settings_util;
/
