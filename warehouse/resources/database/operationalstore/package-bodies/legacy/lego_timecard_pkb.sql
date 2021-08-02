create or replace PACKAGE BODY lego_timecard
/******************************************************************************
 * Name: lego_timecard
 * Desc: This package contains all the procedures required to
 *       load timecard event and entry data
 *
 * Author        Date        Version   History
 * -----------------------------------------------------------------
 * jpullifrone   08/30/2016  Initial
 * jpullifrone   04/04/2017  IQN-37312 hint no_index on SQL in load_timecard_event
 *                           to get max(event_date).  Skip scan is too slow and not
 *                           sure yet why Oracle wants to use it.  FTS is much faster.
 * jpullifrone   05/08/2017  IQN-37583 - hint no_index on CTAS to load_timecard_event.
 ******************************************************************************/
AS
  gc_curr_schema              CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
  g_source                    CONSTANT VARCHAR2(30) := 'LEGO_TIMECARD';
  g_oc_tc_job_name            CONSTANT VARCHAR2(30) := 'OCL'; --will be suffix to object_name - stands for Off-Cycle Load
  gv_error_stack              VARCHAR2(1000);  
  g_null_partition_name       CONSTANT VARCHAR2(30) := 'P_NULL'; 
  gv_timecard_lookback_months PLS_INTEGER := NVL(lego_tools.get_lego_parameter_num_value('timecard_reprocess_lookback_months'),24);
  



  FUNCTION get_bus_orgs (pi_src_name_short IN lego_source.source_name_short%TYPE)
  
  RETURN getorgrow PIPELINED IS
  
  c sys_refcursor;
  v_tbl getorgrow;
  sql_string varchar2 (4000);
       
  BEGIN
    
    sql_string := 
         'SELECT buyer_enterprise_bus_org_id, trim(regexp_substr(part_list,''[^,]+'', 1, LEVEL) ) buyer_org_id
            FROM buyer_by_ent_part_list_'||pi_src_name_short||'
         CONNECT BY regexp_substr(part_list, ''[^,]+'', 1, LEVEL) IS NOT NULL
             AND PRIOR buyer_enterprise_bus_org_id =  buyer_enterprise_bus_org_id 
             AND PRIOR SYS_GUID() IS NOT NULL
           ORDER BY buyer_enterprise_bus_org_id';   
      --'SELECT bo.enterprise_bus_org_id AS buyer_enterprise_bus_org_id, 
      --        bo.bus_org_id            AS buyer_org_id
      --   FROM bus_org_'||pi_src_name_short||' bo, buyer_by_ent_part_list_'||pi_src_name_short||' bepl
      --  WHERE bo.enterprise_bus_org_id = bepl.buyer_enterprise_bus_org_id
      --    AND bo.parent_bus_org_id IS NOT NULL';
      
        
    OPEN c FOR sql_string;
    
    LOOP
      FETCH c BULK COLLECT INTO v_tbl;
      FOR i IN 1..v_tbl.COUNT
        LOOP
          PIPE ROW (v_tbl (i) );
        END LOOP;
       EXIT WHEN c%notfound;
    END LOOP;
    
    CLOSE c;
    
    RETURN;
  
  END get_bus_orgs;
  
  PROCEDURE index_maint (pi_object_name   IN lego_object.object_name%TYPE,
                         pi_process_stage IN VARCHAR2) IS
                         
  --PI_PROCESS_STAGE: BEGIN, MAINT, END
  
  v_source            VARCHAR2(61) := g_source || '.index_maint';
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('index_maint');
    
    IF pi_object_name = 'LEGO_TIMECARD_EVENT' THEN
      
      BEGIN
        CASE UPPER(pi_process_stage)
          WHEN 'BEGIN' THEN 
            logger_pkg.info('Dropping index lego_timecard_event_n01 on '||pi_object_name);
            EXECUTE IMMEDIATE 'DROP INDEX lego_timecard_event_n01';
            logger_pkg.info('Successfully dropped index lego_timecard_event_n01 on '||pi_object_name,TRUE);
          WHEN 'MAINT' THEN NULL;
          WHEN 'END'   THEN 
            logger_pkg.info('Creating index lego_timecard_event_n01 on '||pi_object_name);
            EXECUTE IMMEDIATE 'CREATE INDEX lego_timecard_event_n01 ON '||pi_object_name||' (timecard_id, buyer_enterprise_bus_org_id, source_name)';
            logger_pkg.info('Successfully created index lego_timecard_event_n01 on '||pi_object_name,TRUE);
        ELSE NULL;
        END CASE;   
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
      
      logger_pkg.info('Gathering stats on '||pi_object_name);
      dbms_stats.gather_table_stats(ownname          => gc_curr_schema,
                                    tabname          => pi_object_name,
                                    degree           => 4);   
      logger_pkg.info('Successfully gathered stats on '||pi_object_name,TRUE);                                    
    
    ELSIF pi_object_name = 'LEGO_TIMECARD_ENTRY' THEN
    
      logger_pkg.info('Gathering stats on '||pi_object_name);
      dbms_stats.gather_table_stats(ownname          => gc_curr_schema,
                                    tabname          => pi_object_name,
                                    degree           => 4);     
      logger_pkg.info('Successfully gathered stats on '||pi_object_name,TRUE);                                    
    
    ELSE
      NULL;
    END IF;
    
    logger_pkg.unset_source(v_source); 
    
  END index_maint;
  
  PROCEDURE parse_partition_values (pi_object_name IN lego_object.object_name%TYPE,
                                    pi_source      IN lego_object.source_name%TYPE) IS
  
  v_source            VARCHAR2(61) := g_source || '.parse_partition_values';
  TYPE varchar2_table IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
  lv_delim VARCHAR2(5) := ', ';
  lv_string VARCHAR2(32767);
  lv_nfields PLS_INTEGER := 1;
  lv_table varchar2_table;    
  lv_delimpos PLS_INTEGER;
  lv_delimlen PLS_INTEGER := LENGTH(lv_delim);
  lv_load_date DATE := SYSDATE;
    
  CURSOR tab_part_list_vals IS
    SELECT buyer_enterprise_bus_org_id,
           part_name,
           part_list
      FROM lego_part_by_enterprise_gtt
     WHERE object_name = pi_object_name;             
    
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('parse_partition_values'); 
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE lego_part_by_enterprise_gtt';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE lego_part_by_ent_buyer_org_gtt';
    
    logger_pkg.info('Insert into partition GTT to hold data associated with existing partitions.');
    /* Note: if you want to get or store high_value from user_tab_partitions, you have to convert
       it to a LOB, TO_LOB(high_value). */  
    
    INSERT INTO lego_part_by_enterprise_gtt
      SELECT pi_object_name                 object_name,
             pi_source                      source_name,
             TO_NUMBER(SUBSTR(partition_name,3)) buyer_enterprise_bus_org_id, 
             partition_name                 part_name, 
             TO_LOB(high_value)             part_list,
             SYSDATE                        load_date
       FROM user_tab_partitions
      WHERE table_name = pi_object_name
        AND partition_name != g_null_partition_name;   
    
    logger_pkg.info('Successfully inserted into partition GTT to hold existing partitions.'||SQL%ROWCOUNT||' records inserted.',TRUE);
    COMMIT;
    
    logger_pkg.info('Loop through records in lego_part_by_enterprise_gtt, parsing the partition values.');
    FOR r1 IN tab_part_list_vals LOOP
      
      lv_delimpos := INSTR(r1.part_list,lv_delim);
      lv_string := TO_CHAR(r1.part_list); --must be stored as CLOB 
      lv_delimlen := LENGTH(lv_delim);
      
      WHILE lv_delimpos > 0
      LOOP
        lv_table(lv_nfields) := SUBSTR(lv_string,1,lv_delimpos-1);
        lv_string := SUBSTR(lv_string,lv_delimpos+lv_delimlen);
        lv_nfields := lv_nfields+1;
        lv_delimpos := INSTR(lv_string, lv_delim);
      END LOOP;
      
      lv_table(lv_nfields) := lv_string;         
      
      FOR x IN 1..lv_nfields LOOP
    
        INSERT INTO lego_part_by_ent_buyer_org_gtt VALUES(pi_object_name, pi_source, r1.buyer_enterprise_bus_org_id, lv_table(x), r1.part_name, lv_load_date);
      
      END LOOP;
      COMMIT;
      
   END LOOP;
   logger_pkg.info('Successfully parsed all partition values in lego_part_by_enterprise_gtt.', TRUE);
   
   logger_pkg.unset_source(v_source);
   
  END parse_partition_values;
 
  PROCEDURE off_cycle_timecard_load (pi_object_name IN lego_object.object_name%TYPE,
                                     pi_source      IN lego_object.source_name%TYPE,
                                     pi_start_ts    IN TIMESTAMP DEFAULT SYSTIMESTAMP) AS
  
  v_source            VARCHAR2(61) := g_source || '.off_cycle_timecard_load';
  lv_job_str          VARCHAR2(2000);
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('off_cycle_timecard_load');  
  
    lv_job_str :=
      'BEGIN
        logger_pkg.instantiate_logger;
        logger_pkg.set_source('''||pi_object_name||'_'||g_oc_tc_job_name||''');
        lego_timecard.timecard_load('''||pi_object_name||''','''||pi_source||'''); 
      EXCEPTION
        WHEN OTHERS THEN                                       
          logger_pkg.unset_source('''||pi_object_name||'_'||g_oc_tc_job_name||''');                                       
      END;';

    logger_pkg.info(lv_job_str);
    
    DBMS_SCHEDULER.CREATE_JOB (
          job_name             => pi_object_name||'_'||g_oc_tc_job_name,
          job_type             => 'PLSQL_BLOCK',
          job_action           => lv_job_str,
          start_date           => pi_start_ts,
          enabled              => TRUE,
          comments             => 'Manually populate '||pi_object_name||'-this will take a while');
  
    logger_pkg.unset_source(v_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.unset_source(v_source);
      RAISE;
  
  END off_cycle_timecard_load;   
  
  PROCEDURE reload_timecards (pi_object_name    IN lego_object.object_name%TYPE,
                             pi_source          IN lego_object.source_name%TYPE,
                             pi_start_ts        IN TIMESTAMP DEFAULT SYSTIMESTAMP,
                             pi_drop_partition  IN BOOLEAN   DEFAULT FALSE) AS
  
  /******************************WARNING****************************************
  
  THIS PROCEDURE WILL TRUNCATE EVERYTHING AND START OVER.  ONLY RUN THIS 
  PROCEDURE IF THAT IS YOUR INTENTION.
  
   ******************************WARNING***************************************/ 
  
  
  v_source            VARCHAR2(61) := g_source || '.reload_timecards';
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('reload_timecards'); 
  
    IF pi_drop_partition THEN
    
      /* Do not drop the NULL partition.  Otherwise you would have to drop 
         the entire table. Instead of using a DEFAULT partition, we will use a NULL
         partition.  Reason is, we need a "first" partition when creating the table,
         upon which all the other partitions can be added.  If we were to create the 
         table with a DEFAULT partition, we cannot then create other partitions since
         it will raise ORA-14323.  No records, however, should go into the NULL 
         partition since the column, buyer_enterprise_bus_org_id, is defined as NOT NULL.
         */
      FOR p1 IN (SELECT partition_name
                   FROM user_tab_partitions
                  WHERE table_name = pi_object_name
                    AND partition_name != g_null_partition_name
                  ORDER BY partition_position DESC) LOOP
                
        logger_pkg.info('Dropping partition on '||pi_object_name||': '||p1.partition_name);
        EXECUTE IMMEDIATE 'ALTER TABLE '||pi_object_name||' DROP PARTITION '||p1.partition_name;
        logger_pkg.info('Sucessfully dropped partition on '||pi_object_name||': '||p1.partition_name);
    
      END LOOP;
    
    ELSE
    
      logger_pkg.info('Truncating table, '||pi_object_name||', with reuse storage');      
      EXECUTE IMMEDIATE 'TRUNCATE TABLE '||pi_object_name||' REUSE STORAGE';
      logger_pkg.info('Sucessfully truncated table, '||pi_object_name||', with reuse storage', TRUE);    
  
    END IF;
    
    logger_pkg.info('Truncating table, lego_timecard_extr_tracker, with reuse storage');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE lego_timecard_extr_tracker REUSE STORAGE';
    logger_pkg.info('Sucessfully truncated table, lego_timecard_extr_tracker, with reuse storage', TRUE);    
    
    index_maint (pi_object_name   => pi_object_name,
                 pi_process_stage => 'BEGIN');
    
    IF pi_source = 'ALL' THEN
    --run for all sources
      FOR src IN (SELECT DISTINCT source_name 
                    FROM lego_timecard_extr_tracker) LOOP
                      
        off_cycle_timecard_load (pi_object_name => pi_object_name,
                                 pi_source      => src.source_name,
                                 pi_start_ts    => pi_start_ts);
        
      END LOOP;  
        
    ELSE
      --run for just one
      off_cycle_timecard_load (pi_object_name => pi_object_name,
                               pi_source      => pi_source,
                               pi_start_ts    => pi_start_ts);     
    END IF;          
    
    logger_pkg.unset_source(v_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.unset_source(v_source);
      RAISE;  
  
  END reload_timecards;
  
  PROCEDURE reload_part_timecard (pi_object_name          IN lego_object.object_name%TYPE,
                                  pi_source               IN lego_object.source_name%TYPE,
                                  pi_start_ts             IN TIMESTAMP DEFAULT SYSTIMESTAMP,
                                  pi_buyer_ent_bus_org_id IN lego_timecard_extr_tracker.buyer_enterprise_bus_org_id%TYPE) AS
                                         
  v_source            VARCHAR2(61) := g_source || '.reload_part_timecard';
  lv_partition_name   VARCHAR2(30);
  lv_alter_sql        VARCHAR2(200);
  lv_part_count       PLS_INTEGER;

  /*****************************************************************************
  
   Run this procedure if you want to target a particular partition for removal
   and reload.  The routine will automatically reload the data into the same
   partition as well as anything else that is ready to be loaded.
   
   Since there are multiple sources inside a partition, you will have to reload
   the data for earch source.  
   
   Note that a partition name is consistently named, 
   'P_'||buyer_enterprise_bus_org_id.
   ****************************************************************************/ 
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('reload_part_timecard'); 
  
    IF pi_buyer_ent_bus_org_id IS NOT NULL THEN          
      
      BEGIN
      
        SELECT UPPER(partition_name)
          INTO lv_partition_name
          FROM user_tab_partitions
         WHERE table_name = pi_object_name
           AND partition_name = 'P_'||pi_buyer_ent_bus_org_id;
               
        logger_pkg.info('Remove records in lego_timecard_extr_tracker which are associated with partition: '||lv_partition_name);
        
        --Do not need to specify source_name in the where clause here because
        --all sources will be part of the partition when it gets dropped.
        --Therefore, both sources will need to be loaded if you want both
        --back in the table.  Specify which of the sources you want loaded 
        --back automatically, or simply specify the value of 'ALL' and it will
        --load all of them.
        DELETE FROM lego_timecard_extr_tracker
         WHERE buyer_enterprise_bus_org_id = pi_buyer_ent_bus_org_id
           AND object_name = pi_object_name;
                                                     
        logger_pkg.info('Successfully removed records in lego_timecard_extr_tracker which are associated with partition: '||lv_partition_name||' Records deleted: '||SQL%ROWCOUNT, TRUE);                                                     
              
        lv_alter_sql := 'ALTER TABLE '||pi_object_name||' DROP PARTITION '||lv_partition_name;
        logger_pkg.info('Dropping partition on '||pi_object_name||': '||lv_alter_sql);
             
        EXECUTE IMMEDIATE lv_alter_sql;
      
        logger_pkg.info('Sucessfully dropped partition on '||pi_object_name||': '||lv_partition_name, TRUE);   
  
        COMMIT; --commit only after the partition is dropped      
      
        --general off-cycle load 
        IF pi_source = 'ALL' THEN
          --run for all sources
          FOR src IN (SELECT DISTINCT source_name 
                        FROM lego_object
                       WHERE object_name = pi_object_name
                         AND enabled = 'Y') LOOP
                      
            off_cycle_timecard_load (pi_object_name => pi_object_name,
                                     pi_source      => src.source_name,
                                     pi_start_ts    => pi_start_ts);
        
          END LOOP;  
        
        ELSE
          --run for just one
          off_cycle_timecard_load (pi_object_name => pi_object_name,
                                   pi_source      => pi_source,
                                   pi_start_ts    => pi_start_ts);     
        END IF;
        
        
    
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          logger_pkg.warn('Partition, '||lv_partition_name||', is not a valid partition name for '||pi_object_name);
        WHEN OTHERS THEN
          ROLLBACK;
          RAISE;
      END;
    
    ELSE
    
      logger_pkg.warn('No value for pi_partition_name was passed in.  Please pass in a valid partition name for '||pi_object_name);
  
    END IF;

    logger_pkg.unset_source(v_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.warn('When others exception occurred '||pi_source||' : '||pi_start_ts||' : '||lv_partition_name||' : '||pi_object_name,TRUE);
      logger_pkg.unset_source(v_source);
      RAISE;  
                                         
  END reload_part_timecard; 

  
  PROCEDURE drop_oc_timecard_job (pi_object_name lego_object.object_name%TYPE) AS
  
  v_source   VARCHAR2(61) := g_source || '.drop_oc_timecard_job';
  
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('drop_oc_timecard_job'); 
  
    logger_pkg.info('Dropping job, '||pi_object_name||'_'||g_oc_tc_job_name);
    
    DBMS_SCHEDULER.DROP_JOB(pi_object_name||'_'||g_oc_tc_job_name,TRUE);  
    
    logger_pkg.unset_source(v_source); 
    
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.warn('When others exception occurred in '||v_source,TRUE);
      logger_pkg.unset_source(v_source);
      RAISE;      
  
  END drop_oc_timecard_job;
 
  PROCEDURE tc_tracker_ins (pi_object_name     IN lego_object.object_name%TYPE,
                            pi_source          IN lego_object.source_name%TYPE,
                            pi_ent_bus_org_id  IN lego_timecard_extr_tracker.buyer_enterprise_bus_org_id%TYPE,
                            pi_min_week_ending_date  IN lego_timecard_event.week_ending_date%TYPE,
                            pi_max_week_ending_date  IN lego_timecard_event.week_ending_date%TYPE) IS
                            
  lv_source         VARCHAR2(61) := g_source || '.tc_tracker_ins'; 
  
  BEGIN
  
    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('tc_tracker_ins');   
  
    /* Here is how this works.  Given the inputs above, insert a row into the 
       tracker table for every possible quarter start and end date that exists
       between the dates of pi_min_week_ending_date and pi_max_week_ending_date.
       
       Example:  For org 1, there are events ranging from the week ending date of
                 2/23/2014 and 09/17/2016.  For that org and that range of week
                 ending dates, the following rows would be inserted (not all columns
                 are represented):
                 
                 ORG_ID QTR_START_DATE  QTR_END_DATE
                 -----------------------------------
                    1    01/01/2014      03/31/2014
                    1    04/01/2014      06/30/2014
                    1    07/01/2014      09/30/2014
                    1    10/01/2014      12/31/2014
                    1    01/01/2015      03/31/2015
                    1    04/01/2015      06/30/2015
                    1    07/01/2015      09/30/2015
                    1    10/01/2015      12/31/2015
                    1    01/01/2016      03/31/2016
                    1    04/01/2016      06/30/2016
                    1    07/01/2016      09/30/2016

    */
     
    logger_pkg.info('Inserting into lego_timecard_extr_tracker...');    
    
    --Only new Orgs with new calendar quarter dates will be inserted here
    INSERT INTO lego_timecard_extr_tracker
      SELECT pi_object_name    AS   object_name,
             pi_source         AS   source_name,
             pi_ent_bus_org_id AS   buyer_enterprise_bus_org_id,
             ADD_MONTHS(TRUNC(pi_min_week_ending_date, 'Q'), 3*(LEVEL-1))  AS qtr_start_date,
             ADD_MONTHS(TRUNC(pi_min_week_ending_date, 'Q'), 3*(LEVEL)) -1 AS qtr_end_date,
             NULL              AS   max_event_date,
             NULL              AS   load_date,
             NULL              AS   load_time_sec,
             NULL              AS   records_loaded            
        FROM dual
     CONNECT BY ADD_MONTHS( TRUNC(pi_min_week_ending_date, 'Q'), 3*(LEVEL-1) ) <= pi_max_week_ending_date
     MINUS
     SELECT object_name,
            source_name,
            buyer_enterprise_bus_org_id,
            qtr_start_date,
            qtr_end_date,
            NULL max_event_date,
            NULL load_date,
            NULL load_time_sec,
            NULL records_loaded                                    
       FROM lego_timecard_extr_tracker;                     

    COMMIT;
    
    IF SQL%ROWCOUNT > 0 THEN
      logger_pkg.info('Successfully inserted into lego_timecard_extr_tracker '||SQL%ROWCOUNT,TRUE); 
    ELSE
      logger_pkg.info('Nothing to insert',TRUE); 
    END IF;

    logger_pkg.unset_source(lv_source);
  
  END tc_tracker_ins;
  
  
  PROCEDURE load_timecard_event (pi_object_name    IN lego_object.object_name%TYPE,
                                 pi_source         IN lego_object.source_name%TYPE,
                                 pi_db_link_name   IN lego_source.db_link_name%TYPE,
                                 pi_src_name_short IN lego_source.source_name_short%TYPE) AS
  
  v_source               VARCHAR2(61) := g_source || '.load_timecard_event';
  lv_insert_sql          CLOB;  
  lv_ctas_sql            CLOB;
  lv_load_date           lego_timecard_extr_tracker.load_date%TYPE;     
  lv_load_time_sec       lego_timecard_extr_tracker.load_time_sec%TYPE;
  lv_records_loaded      VARCHAR2(30);
  lc_beginning_of_time   CONSTANT DATE := TO_DATE('10/28/1974','MM/DD/YYYY');
  lv_max_event_date      lego_timecard_extr_tracker.max_event_date%TYPE;
  lv_buyer_org_id_list   VARCHAR2(4000);
  
  /* The value of lv_beginning_of_time will be used when the Org-Quarter is new.
   After the records for that Org-Quarter are loaded into LEGO_TIMECARD_EVENT,
   this field will take the value of MAX(event_date) for that ORG-QUARTER.  
   Note that the MAX(event_date) may be greater than the qtr_end_date.  That
   is because we are inserting into LEGO_TIMECARD_EVENT based on the events
   within a week_ending_date.  Therefore, it is likely that events will occur
   on a timecard after the week_ending_date.  The event records are loaded by
   week_ending_date for 2 reasons:
   1. It's faster to query the FO tables by the timecard's week_ending_date.
   2. I believe this will aid in finding and loading timecard_entry records, 
      which is a separate process that will likely be based on the events loaded
      here. 
      
  Records in the cursor will pickup new ORG-QUARTERs where the load_date IS NULL
  or the value of max_event_date is >= gv_timecard_lookback_months months in the past.
  I think it is prudent to look back 24 months and find any events that correspond 
  to timecard adjustments, which I have seen occur.  Records in the cursor are
  sorted by load_date DESC first so that new ORG-QUARTERS are loaded before 
  existing ones are refreshed.
      
  */
      
  CURSOR c_new_det 
  IS
    SELECT object_name,
           source_name,
           buyer_enterprise_bus_org_id,
           qtr_start_date,
           qtr_end_date,
           NVL(max_event_date,lc_beginning_of_time) max_event_date
      FROM lego_timecard_extr_tracker 
     WHERE object_name = pi_object_name
       AND source_name = pi_source
       AND (load_date IS NULL OR -- CASE 1: a brand new ORG-QUARTER 
            qtr_start_date >= ADD_MONTHS(TRUNC(SYSDATE),- gv_timecard_lookback_months)) -- CASE 2: ORG-QUARTERs within last x months (defined by gv_timecard_lookback_months)             
     ORDER BY load_date DESC, buyer_enterprise_bus_org_id DESC, qtr_start_date;  
  
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('load_timecard_event');  
  
    FOR r_new_det IN c_new_det LOOP
    
      BEGIN   
      
      lv_load_date := SYSDATE;
      
      EXECUTE IMMEDIATE 'SELECT part_list
                           FROM buyer_by_ent_part_list_'||pi_src_name_short||'
                          WHERE buyer_enterprise_bus_org_id = '||r_new_det.buyer_enterprise_bus_org_id
                           INTO lv_buyer_org_id_list;     
      
        BEGIN
          logger_pkg.info('Dropping table, timecard_event_tmp_'||pi_source);
          EXECUTE IMMEDIATE 'DROP TABLE timecard_event_tmp_'||pi_source||' PURGE';
          logger_pkg.info('Successfully dropped table, timecard_event_tmp_'||pi_source,TRUE);
        EXCEPTION
          WHEN OTHERS THEN 
          logger_pkg.info('Failed to drop table, timecard_event_tmp_'||pi_source,TRUE);
        END;                                                       
        
        lv_ctas_sql :=  
        'CREATE TABLE timecard_event_tmp_'||pi_source||' AS
           SELECT /*+NO_INDEX(ed EVENT_DESCRIPTION_N1)*/
                  '||r_new_det.buyer_enterprise_bus_org_id||'    buyer_enterprise_bus_org_id,
                  bfr.business_org_fk                            buyer_org_id,                  
                  ted.timecard_fk                                timecard_id,
                  ed.identifier                                  event_id,
                  en.value                                       event_name_id,
                  en.event_name                                  event_name,
                  ted.before_state_code                          before_state_id,
                  ted.after_state_code                           after_state_id,
                  t.week_ending_date                             week_ending_date,
                  ed.timestamp                                   event_date,
                  '''||pi_source||'''                            source_name,'||CHR(10)                 
                 ||'TO_DATE('''||TO_CHAR(lv_load_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'') load_date       
            FROM event_description@'||pi_db_link_name||'          ed,
                 event_name@'||pi_db_link_name||'                 en,
                 timecard_event_description@'||pi_db_link_name||' ted,
                 timecard@'||pi_db_link_name||'                   t,
                 assignment_continuity@'||pi_db_link_name||'      ac,                 
                 firm_role@'||pi_db_link_name||'                  bfr
           WHERE t.assignment_continuity_fk       = ac.assignment_continuity_id
             AND ted.timecard_fk                  = t.timecard_id 
             AND ted.identifier                   = ed.identifier
             AND ed.event_name_fk                 = en.value
             AND ac.owning_buyer_firm_fk          = bfr.firm_id                          
             AND en.value IN (22000, 22001, 22003, 22004, 22005, 22006, 22007, 22008, 22011, 22012, 22013)              
             AND bfr.business_org_fk IN ('||lv_buyer_org_id_list||')
             AND ed.timestamp > TO_DATE('''||TO_CHAR(r_new_det.max_event_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'')
             AND t.week_ending_date BETWEEN TO_DATE('''||TO_CHAR(r_new_det.qtr_start_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'') AND
                                            TO_DATE('''||TO_CHAR(r_new_det.qtr_end_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'')';
                 
        lv_insert_sql :=
        'INSERT INTO lego_timecard_event
           SELECT * 
             FROM timecard_event_tmp_'||pi_source;
          
        logger_pkg.info('Creating temp table for buyer_enterprise_bus_org_id = '||r_new_det.buyer_enterprise_bus_org_id||
                        ', qtr_start_date = '||r_new_det.qtr_start_date||', qtr_end_date = '||r_new_det.qtr_end_date||
                        ', max_event_date = '||r_new_det.max_event_date||CHR(10)||lv_ctas_sql); 
                        
        EXECUTE IMMEDIATE lv_ctas_sql;
        
        logger_pkg.info('Successfully loaded records into temp table for buyer_enterprise_bus_org_id = '||r_new_det.buyer_enterprise_bus_org_id||
                        ', qtr_start_date = '||r_new_det.qtr_start_date||', qtr_end_date = '||r_new_det.qtr_end_date||', max_event_date = '||r_new_det.max_event_date,TRUE);        
                      
        logger_pkg.info('Loading of records into '||pi_object_name||' for buyer_enterprise_bus_org_id = '||r_new_det.buyer_enterprise_bus_org_id||
                        ', qtr_start_date = '||r_new_det.qtr_start_date||', qtr_end_date = '||r_new_det.qtr_end_date||
                        ', max_event_date = '||r_new_det.max_event_date||CHR(10)||lv_insert_sql);         
        
        EXECUTE IMMEDIATE lv_insert_sql;
        
        lv_load_time_sec := ROUND(86400 * (SYSDATE - lv_load_date),2);
        
        lv_records_loaded := SQL%ROWCOUNT;
        
        IF SQL%ROWCOUNT > 0 THEN
          logger_pkg.info('Successfully loaded records for buyer_enterprise_bus_org_id = '||r_new_det.buyer_enterprise_bus_org_id||
                           ', qtr_start_date = '||r_new_det.qtr_start_date||', qtr_end_date = '||r_new_det.qtr_end_date||', max_event_date = '||r_new_det.max_event_date||
                           ' Number of records inserted: '||lv_records_loaded||' Load time in seconds: '||lv_load_time_sec,TRUE);
        ELSE
          logger_pkg.info('Nothing to insert for buyer_enterprise_bus_org_id = '||r_new_det.buyer_enterprise_bus_org_id||
                           ', qtr_start_date = '||r_new_det.qtr_start_date||', qtr_end_date = '||r_new_det.qtr_end_date||', max_event_date = '||r_new_det.max_event_date||
                           ' Number of records inserted: '||lv_records_loaded||' Load time in seconds: '||lv_load_time_sec,TRUE);
        END IF;
      
        logger_pkg.info('Geting MAX(event_date) from lego_timecard_event...'); 
        
        SELECT /*+NO_INDEX(te LEGO_TIMECARD_EVENT_N01)*/
		       MAX(te.event_date) max_event_date
          INTO lv_max_event_date
          FROM lego_timecard_event te
         WHERE te.source_name  = pi_source
           AND te.buyer_enterprise_bus_org_id = r_new_det.buyer_enterprise_bus_org_id
           AND te.week_ending_date BETWEEN r_new_det.qtr_start_date AND r_new_det.qtr_end_date;  
           
        logger_pkg.info('Successfully retrieved MAX(event_date): '||lv_max_event_date,TRUE);
        
        logger_pkg.info('Updating lego_timecard_extr_tracker...'); 
        /* lego_timecard_extr_tracker holds a record for every ORG-QUARTER.  This means
           that when an ORG-QUARTER is "re-examined" for new events, the values for
           max_event_date, records_loaded, and load_time_sec are updated. */
        UPDATE lego_timecard_extr_tracker
           SET load_date        = lv_load_date,
               max_event_date   = NVL(lv_max_event_date, r_new_det.qtr_end_date), --*arbitrary, but makes sense. 
               records_loaded   = NVL(records_loaded,0) + lv_records_loaded, 
               load_time_sec    = NVL(load_time_sec,0)  + lv_load_time_sec 
         WHERE object_name                 = pi_object_name
           AND source_name                 = pi_source
           AND buyer_enterprise_bus_org_id = r_new_det.buyer_enterprise_bus_org_id
           AND qtr_start_date              = r_new_det.qtr_start_date
           AND qtr_end_date                = r_new_det.qtr_end_date;
           
        --* If there are no events for this quarter now, there still could be some in the future. 
        --  Therefore, if the max_event_date is NULL, instead, store the qtr_end_date.
        --  In this way, the process will keep trying to find more events until the 
        --  lc_months_in_refresh value is reached.
        logger_pkg.info('Successfully updated lego_timecard_extr_tracker',TRUE);
         
        COMMIT;
        
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          logger_pkg.warn('Failed to load records for buyer_enterprise_bus_org_id = '||r_new_det.buyer_enterprise_bus_org_id||
                         ' qtr_start_date = '||r_new_det.qtr_start_date||' qtr_end_date = '||r_new_det.qtr_end_date||', max_event_date = '||r_new_det.max_event_date||
                         CHR(10)|| SQLERRM || chr(10) || dbms_utility.format_error_backtrace||' - '||lv_ctas_sql||' - '||lv_insert_sql);
      END;
    
    END LOOP;     
    
    logger_pkg.unset_source(v_source); 
   
  END load_timecard_event;
  
  PROCEDURE load_timecard_entry (pi_object_name      IN lego_object.object_name%TYPE,
                                 pi_source           IN lego_object.source_name%TYPE,
                                 pi_db_link_name     IN lego_source.db_link_name%TYPE,
                                 pi_src_name_short   IN lego_source.source_name_short%TYPE,
                                 pi_dependent_object IN lego_object.object_name%TYPE) AS
  
  v_source               VARCHAR2(61) := g_source || '.load_timecard_entry';
  lv_insert_sql          CLOB;  
  lv_ctas_sql            CLOB;
  lv_part_swap_sql       VARCHAR2(300);
  lv_load_date           lego_timecard_extr_tracker.load_date%TYPE;     
  lv_load_time_sec       lego_timecard_extr_tracker.load_time_sec%TYPE;
  lv_records_loaded      PLS_INTEGER;
  lc_beginning_of_time   CONSTANT DATE := TO_DATE('10/28/1974','MM/DD/YYYY');
  lv_max_event_date      lego_timecard_extr_tracker.max_event_date%TYPE;
  lv_part_name           lego_part_by_enterprise_gtt.part_name%TYPE;
  lv_buyer_org_id_list   VARCHAR2(4000);

  
  CURSOR c_new_ent 
  IS
    SELECT entr.object_name,
           entr.source_name,
           entr.buyer_enterprise_bus_org_id,
           entr.qtr_start_date,
           entr.qtr_end_date,
           NVL(entr.max_event_date,lc_beginning_of_time) max_event_date,
           evnt.max_event_date event_max_event_date
      FROM lego_timecard_extr_tracker entr, lego_timecard_extr_tracker evnt
     WHERE entr.source_name                 = evnt.source_name
       AND entr.buyer_enterprise_bus_org_id = evnt.buyer_enterprise_bus_org_id
       AND entr.qtr_start_date              = evnt.qtr_start_date
       AND entr.qtr_end_date                = evnt.qtr_end_date       
       AND entr.object_name                 = pi_object_name
       AND entr.source_name                 = pi_source
       AND evnt.object_name                 = pi_dependent_object
       AND evnt.load_date                   IS NOT NULL
       AND (entr.load_date IS NULL OR -- CASE 1: a brand new ORG-QUARTER 
            entr.qtr_start_date >= ADD_MONTHS(TRUNC(SYSDATE),- gv_timecard_lookback_months)) -- CASE 2: ORG-QUARTERs within last x months (defined by gv_timecard_lookback_months)             
     ORDER BY entr.load_date DESC, entr.buyer_enterprise_bus_org_id DESC, entr.qtr_start_date; 
  
  
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('load_timecard_entry');  
  
    FOR r_new_ent IN c_new_ent LOOP
    
      BEGIN   
      
        lv_load_date := SYSDATE;
        
        EXECUTE IMMEDIATE 'SELECT part_name, part_list
                             FROM buyer_by_ent_part_list_'||pi_src_name_short||'
                            WHERE buyer_enterprise_bus_org_id = '||r_new_ent.buyer_enterprise_bus_org_id
                             INTO lv_part_name, lv_buyer_org_id_list;             
      
        BEGIN
          logger_pkg.info('Dropping table, timecard_event_tmp_'||pi_source);
          EXECUTE IMMEDIATE 'DROP TABLE timecard_entry_tmp_'||pi_source||' PURGE';
          logger_pkg.info('Successfully dropped table, timecard_entry_tmp_'||pi_source,TRUE);
        EXCEPTION
          WHEN OTHERS THEN 
          logger_pkg.info('Failed to drop table, timecard_entry_tmp_'||pi_source,TRUE);
        END;                                                     
        
        lv_ctas_sql :=  
        'CREATE TABLE timecard_entry_tmp_'||pi_source||'( 
             buyer_enterprise_bus_org_id    NOT NULL,
             buyer_org_id                   NOT NULL,
             supplier_org_id                NOT NULL,
             timecard_entry_id              NOT NULL,
             timecard_id                    NOT NULL,
             assignment_continuity_id       NOT NULL,
             wk_date                        NOT NULL,
             week_ending_date               NOT NULL,
             tc_create_date                 NOT NULL,
             tc_last_update_date,
             tce_create_date                NOT NULL,
             timecard_number,
             timecard_type                  NOT NULL,
             is_break,
             hours,
             change_to_hours,
             state_code                     NOT NULL,
             timecard_approval_workflow_id,
             timecard_approver_id,
             tc_udf_collection_id,
             tce_udf_collection_id,
             cac1_id,
             cac2_id,
             source_name,
             load_date)        
         AS
           SELECT CAST('||r_new_ent.buyer_enterprise_bus_org_id||' AS NUMBER(38)) buyer_enterprise_bus_org_id,
                  CAST(bfr.business_org_fk AS NUMBER(38)),
                  CAST(sfr.business_org_fk AS NUMBER(38)),
                  CAST(te.timecard_entry_id AS NUMBER(38)),
                  CAST(t.timecard_id AS NUMBER(38)),
                  CAST(ac.assignment_continuity_id AS NUMBER(38)),
                  CAST(te.wk_date AS DATE),
                  CAST(t.week_ending_date AS DATE),
                  CAST(t.create_date AS DATE),
                  CAST(t.last_update_date AS DATE),
                  CAST(te.time_created AS DATE),
                  CAST(t.timecard_number AS VARCHAR2(256 CHAR)),
                  CAST(t.timecard_type AS VARCHAR2(24 CHAR)),
                  CAST(te.is_break AS NUMBER(1)),
                  CAST(te.hours AS NUMBER(38,2)),
                  CAST(te.change_to_hours AS NUMBER(38,2)),
                  CAST(t.state_code AS NUMBER(38)),
                  CAST(ae.timecard_approval_workflow_fk AS NUMBER(38)),
                  CAST(ae.timecard_approver_fk AS NUMBER(38)),
                  CAST(t.udf_collection_fk AS NUMBER(38)),
                  CAST(te.udf_collection_fk AS NUMBER(38)),
                  CAST(te.cac1_fk AS NUMBER(38)),
                  CAST(te.cac2_fk AS NUMBER(38)),                  
                  CAST('''||pi_source||''' AS VARCHAR2(6 CHAR)),'||CHR(10)                 
                  ||'CAST(TO_DATE('''||TO_CHAR(lv_load_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'') AS DATE)       
            FROM timecard_entry@'||pi_db_link_name||'             te,
                 timecard@'||pi_db_link_name||'                   t,
                 assignment_continuity@'||pi_db_link_name||'      ac,
                 assignment_edition@'||pi_db_link_name||'         ae,
                 firm_role@'||pi_db_link_name||'                  bfr,
                 firm_role@'||pi_db_link_name||'                  sfr
           WHERE te.timecard_fk                   = t.timecard_id
             AND t.assignment_continuity_fk       = ac.assignment_continuity_id
             AND ac.assignment_continuity_id      = ae.assignment_continuity_fk
             AND ac.current_edition_fk            = ae.assignment_edition_id
             AND ac.owning_buyer_firm_fk          = bfr.firm_id 
             AND ac.owning_supply_firm_fk         = sfr.firm_id
             AND t.state_code != 7
             AND ABS(NVL(te.hours,0)) + ABS(NVL(te.change_to_hours,0)) != 0
             AND CASE WHEN te.change_to_hours <= 0 THEN 1
                   ELSE NVL (te.change_to_hours, 0) 
                 END
                 >
                 CASE WHEN timecard_type = ''Timecard Adjustment'' THEN 0
                   ELSE -1 
                 END
             AND bfr.business_org_fk IN ('||lv_buyer_org_id_list||')
             AND t.week_ending_date BETWEEN TO_DATE('''||TO_CHAR(r_new_ent.qtr_start_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'') AND
                                            TO_DATE('''||TO_CHAR(r_new_ent.qtr_end_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'')';        
        
        logger_pkg.info('Creating temp table for buyer_enterprise_bus_org_id = '||r_new_ent.buyer_enterprise_bus_org_id||
                        ', qtr_start_date = '||r_new_ent.qtr_start_date||', qtr_end_date = '||r_new_ent.qtr_end_date||
                        ', max_event_date = '||r_new_ent.max_event_date||CHR(10)||lv_ctas_sql); 
                        
        EXECUTE IMMEDIATE lv_ctas_sql;
        
        logger_pkg.info('Successfully loaded records into temp table for buyer_enterprise_bus_org_id = '||r_new_ent.buyer_enterprise_bus_org_id||
                        ', qtr_start_date = '||r_new_ent.qtr_start_date||', qtr_end_date = '||r_new_ent.qtr_end_date||', max_event_date = '||r_new_ent.max_event_date,TRUE);        
                      
        IF r_new_ent.max_event_date != lc_beginning_of_time THEN --this is an ORG-QUARTER refresh, so partition swap it
              
          EXECUTE IMMEDIATE 
            'SELECT COUNT(*)
               FROM timecard_entry_tmp_'||pi_source
              INTO lv_records_loaded;
        
          lv_part_swap_sql := 'ALTER TABLE lego_timecard_entry EXCHANGE SUBPARTITION '||lv_part_name||'_P_Q'||TO_CHAR(r_new_ent.qtr_end_date,'Q_YYYY')||' WITH TABLE timecard_entry_tmp_'||pi_source||' WITHOUT VALIDATION';    
          logger_pkg.info('Subpartition exchange: '||lv_part_swap_sql);         
          EXECUTE IMMEDIATE lv_part_swap_sql;
          logger_pkg.info('Subpartition exchange: '||lv_part_swap_sql,TRUE);
          
          lv_load_time_sec := ROUND(86400 * (SYSDATE - lv_load_date),2);
          
        ELSE   
   
          logger_pkg.info('Loading of records into '||pi_object_name||' for buyer_enterprise_bus_org_id = '||r_new_ent.buyer_enterprise_bus_org_id||
                          ', qtr_start_date = '||r_new_ent.qtr_start_date||', qtr_end_date = '||r_new_ent.qtr_end_date||
                          ', max_event_date = '||r_new_ent.max_event_date||CHR(10)||lv_insert_sql);         
        
          lv_insert_sql := 
            'INSERT INTO lego_timecard_entry 
               SELECT * FROM timecard_entry_tmp_'||pi_source;    
             
          EXECUTE IMMEDIATE lv_insert_sql;
        
          lv_load_time_sec := ROUND(86400 * (SYSDATE - lv_load_date),2);
        
          lv_records_loaded := SQL%ROWCOUNT;
        
          IF SQL%ROWCOUNT > 0 THEN
            logger_pkg.info('Successfully loaded records for buyer_enterprise_bus_org_id = '||r_new_ent.buyer_enterprise_bus_org_id||
                            ', qtr_start_date = '||r_new_ent.qtr_start_date||', qtr_end_date = '||r_new_ent.qtr_end_date||', max_event_date = '||r_new_ent.max_event_date||
                            ' Number of records inserted: '||lv_records_loaded||' Load time in seconds: '||lv_load_time_sec,TRUE);
          ELSE
            logger_pkg.info('Nothing to insert for buyer_enterprise_bus_org_id = '||r_new_ent.buyer_enterprise_bus_org_id||
                            ', qtr_start_date = '||r_new_ent.qtr_start_date||', qtr_end_date = '||r_new_ent.qtr_end_date||', max_event_date = '||r_new_ent.max_event_date||
                            ' Number of records inserted: '||lv_records_loaded||' Load time in seconds: '||lv_load_time_sec,TRUE);
          END IF;
          
       END IF;

        logger_pkg.info('Updating lego_timecard_extr_tracker...'); 
        /* lego_timecard_extr_tracker holds a record for every ORG-QUARTER.  This means
           that when an ORG-QUARTER is "re-examined" for new events, the values for
           max_event_date, records_loaded, and load_time_sec are updated. */
        UPDATE lego_timecard_extr_tracker
           SET load_date        = lv_load_date,
               max_event_date   = NVL(r_new_ent.event_max_event_date, r_new_ent.qtr_end_date), --*arbitrary, but makes sense. 
               records_loaded   = NVL(records_loaded,0) + lv_records_loaded, 
               load_time_sec    = NVL(load_time_sec,0)  + lv_load_time_sec 
         WHERE object_name                 = pi_object_name
           AND source_name                 = pi_source
           AND buyer_enterprise_bus_org_id = r_new_ent.buyer_enterprise_bus_org_id
           AND qtr_start_date              = r_new_ent.qtr_start_date
           AND qtr_end_date                = r_new_ent.qtr_end_date;
           
        --* If there are no events for this quarter now, there still could be some in the future. 
        --  Therefore, if the max_event_date is NULL, instead, store the qtr_end_date.
        --  In this way, the process will keep trying to find more events until the 
        --  lc_months_in_refresh value is reached.
        logger_pkg.info('Successfully updated lego_timecard_extr_tracker',TRUE);
         
        COMMIT;
        
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          logger_pkg.warn('Failed to load records for buyer_enterprise_bus_org_id = '||r_new_ent.buyer_enterprise_bus_org_id||
                         ' qtr_start_date = '||r_new_ent.qtr_start_date||' qtr_end_date = '||r_new_ent.qtr_end_date||', max_event_date = '||r_new_ent.max_event_date||
                         CHR(10)|| SQLERRM || chr(10) || dbms_utility.format_error_backtrace||' - '||lv_ctas_sql||' - '||lv_insert_sql);
      END;
    
    END LOOP;    
    
    logger_pkg.unset_source(v_source); 
    
  END load_timecard_entry;   
  
  PROCEDURE timecard_load (pi_object_name lego_object.object_name%TYPE,
                           pi_source      lego_object.source_name%TYPE) AS
  
  v_source                 VARCHAR2(61) := g_source || '.timecard_load';
  lv_db_link_name          lego_source.db_link_name%TYPE;
  lv_src_name_short        VARCHAR2(30);
  lv_load_date             lego_timecard_extr_tracker.load_date%TYPE := SYSDATE;
  lv_load_time_sec         lego_timecard_extr_tracker.load_time_sec%TYPE;
  lv_records_loaded        VARCHAR2(30);
  lv_org_qtrs_sql          CLOB;
  lv_alter_tbl_part_sql    VARCHAR2(4000);
  lv_part_name             VARCHAR2(30);
  lv_part_list             VARCHAR2(4000);
  lv_org_qtr_cur           SYS_REFCURSOR;
  lv_buyer_ent_bus_org_id  lego_timecard_event.buyer_enterprise_bus_org_id%TYPE;
  lv_buyer_org_id          lego_timecard_event.buyer_org_id%TYPE;  
  lv_min_week_ending_date  lego_timecard_event.week_ending_date%TYPE;
  lv_max_week_ending_date  lego_timecard_event.week_ending_date%TYPE;

 
  CURSOR c_new_part 
  IS 
      SELECT DISTINCT buyer_enterprise_bus_org_id
        FROM lego_timecard_extr_tracker 
       MINUS
      SELECT buyer_enterprise_bus_org_id
        FROM lego_part_by_enterprise_gtt;
      
  CURSOR c_chg_part 
  IS
   WITH chg_ents AS (  --all partitioned ents that already exist that may or may not have changed
      SELECT pbe.buyer_enterprise_bus_org_id, 
             pbe.part_name
        FROM lego_part_by_enterprise_gtt pbe)
    
      SELECT chg_ents.buyer_enterprise_bus_org_id, chg_ents.part_name, buyer_org_id 
        FROM chg_ents,
             --all possible values for which there are timecard events
            (
            SELECT 'P_'||bye.buyer_enterprise_bus_org_id part_name, bye.buyer_enterprise_bus_org_id, bo.buyer_org_id
              FROM lego_timecard_extr_tracker bye, TABLE(get_bus_orgs(lv_src_name_short)) bo 
             WHERE bye.buyer_enterprise_bus_org_id = bo.buyer_enterprise_bus_org_id
              MINUS   
             --those values already in partitions
             SELECT iedp.part_name, iedp.buyer_enterprise_bus_org_id, iedp.buyer_org_id
               FROM lego_part_by_ent_buyer_org_gtt iedp 
               ) new_vals
       WHERE chg_ents.buyer_enterprise_bus_org_id = new_vals.buyer_enterprise_bus_org_id;
    
  BEGIN
    --logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location(LOWER('TIMECARD_LOAD_'||pi_object_name||'_'||pi_source));    
    
    /* get the actual dblink based on the input value of pi_source */
    lv_db_link_name := lego_tools.get_db_link_name(pi_source);
    
    /* get source_name_short from lego_source to append to lego tables */
    lv_src_name_short := lego_tools.get_src_name_short(pi_source);           
        
    /* Cursor below represents an ORG-QUARTER:  for each organization, get the 
       min(week_ending_date) and max(week_ending_date) for all timecards */        
    OPEN lv_org_qtr_cur FOR 
      'SELECT bo_parent.business_organization_id     AS buyer_enterprise_bus_org_id,
              MIN(t.week_ending_date) AS min_week_ending_date,
              MAX(t.week_ending_date) AS max_week_ending_date
         FROM timecard@'||lv_db_link_name||' t, 
              assignment_continuity@'||lv_db_link_name||' ac, 
              firm_role@'||lv_db_link_name||' bfr,
              business_organization@'||lv_db_link_name||' b,
              bus_org_lineage@'||lv_db_link_name||' bol,
              business_organization@'||lv_db_link_name||' bo_parent
        WHERE t.assignment_continuity_fk = ac.assignment_continuity_id
          AND ac.owning_buyer_firm_fk = bfr.firm_id
          AND bfr.business_org_fk = b.business_organization_id
          AND bol.ancestor_bus_org_fk = bo_parent.business_organization_id
          AND bo_parent.parent_business_org_fk IS NULL
          AND bol.descendant_bus_org_fk = b.business_organization_id
        GROUP BY bo_parent.business_organization_id';
    
    LOOP
      FETCH lv_org_qtr_cur INTO lv_buyer_ent_bus_org_id, 
                            lv_min_week_ending_date, 
                            lv_max_week_ending_date;
      EXIT WHEN lv_org_qtr_cur%NOTFOUND;    
      
      tc_tracker_ins (pi_object_name           => pi_object_name,
                      pi_source                => pi_source,
                      pi_ent_bus_org_id        => lv_buyer_ent_bus_org_id,
                      pi_min_week_ending_date  => lv_min_week_ending_date,
                      pi_max_week_ending_date  => lv_max_week_ending_date);
    
    END LOOP;
    
    CLOSE lv_org_qtr_cur;
    
    /* Call procedure to get all partitions and partition values for the target table, converting from concatenated string to table.
       This table will be used to determine if new partitions or partition values are needed. */
    parse_partition_values (pi_object_name => pi_object_name,
                            pi_source      => pi_source);
    
    FOR r_new_part IN c_new_part 
    LOOP
    /* Which enterprises are new that need to have partitions added for each of them? */
      BEGIN   
      
        EXECUTE IMMEDIATE 'SELECT part_name, part_list
                             FROM buyer_by_ent_part_list_'||lv_src_name_short||'
                            WHERE buyer_enterprise_bus_org_id = '||r_new_part.buyer_enterprise_bus_org_id
                             INTO lv_part_name, lv_part_list;
      
        lv_alter_tbl_part_sql := 'ALTER TABLE '||pi_object_name||' ADD PARTITION '||lv_part_name||' VALUES ('||lv_part_list ||')';
        logger_pkg.info('Create new partition: '||lv_alter_tbl_part_sql);
        
        EXECUTE IMMEDIATE lv_alter_tbl_part_sql;
        
        logger_pkg.info('Successfully created new partition: '||lv_alter_tbl_part_sql,TRUE);
  
      EXCEPTION
        WHEN OTHERS THEN
          logger_pkg.warn('Failed to create new partition: '||SQLERRM || chr(10) || dbms_utility.format_error_backtrace||chr(10)||lv_alter_tbl_part_sql);
      END;
      
    END LOOP;
    
    FOR r_chg_part IN c_chg_part
    LOOP
    /* The query associated with this cursor represents the enterprise orgs that alredy exist
       in user_tab_partitions.  What we are trying to do is check to see if any new buyer_org_id
       values have been discovered as part of the enterprise, so that we can add those values to
       the List Partition with MODIFIY PARTITION ADD VALUES. 
      
       For each enterprise in the loop (those that already have partitions) MINUS the buyer
       org IDs to determine which are newly added based on new invoices.  Then loop through
       those, adding them to the already existing List Partition. */
    
      BEGIN       
      
        lv_alter_tbl_part_sql := 'ALTER TABLE '||pi_object_name||' MODIFY PARTITION '||r_chg_part.part_name ||' ADD VALUES ('||r_chg_part.buyer_org_id||')';
        logger_pkg.info('Add new value: '||r_chg_part.part_name||' to partition: '||r_chg_part.buyer_org_id);
        
        EXECUTE IMMEDIATE lv_alter_tbl_part_sql;
        
        logger_pkg.info('Successfully created new value for partition: '||lv_alter_tbl_part_sql,TRUE);
    
      EXCEPTION
        WHEN OTHERS THEN
          logger_pkg.warn('Failed to add new value to partition: '||SQLERRM || chr(10) || dbms_utility.format_error_backtrace||chr(10)||lv_alter_tbl_part_sql);
      END;    
    
    
    END LOOP;
        
    --There may be no new invoices but still have invoices waiting in lego_invoice_approved with detail_load_date = NULL
    IF pi_object_name = 'LEGO_TIMECARD_EVENT' THEN
      
      load_timecard_event (pi_object_name    => pi_object_name,
                           pi_source         => pi_source,
                           pi_db_link_name   => lv_db_link_name,
                           pi_src_name_short => lv_src_name_short);
     
      
    ELSIF pi_object_name = 'LEGO_TIMECARD_ENTRY' THEN
     
       load_timecard_entry (pi_object_name      => pi_object_name,
                            pi_source           => pi_source,
                            pi_db_link_name     => lv_db_link_name,
                            pi_src_name_short   => lv_src_name_short,
                            pi_dependent_object => 'LEGO_TIMECARD_EVENT');
    
    ELSE
      NULL;
      
    END IF;
    
    logger_pkg.info('Timecard Load for '||pi_object_name||', '||pi_source||' Complete!');
    logger_pkg.info('Timecard Load for '||pi_object_name||', '||pi_source||' Complete!', TRUE);
    logger_pkg.unset_source(v_source);
    
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;     
      gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('ROLLBACK', SQLCODE, 'Error loading timecard events ' || SQLERRM);      
      logger_pkg.unset_source(v_source);
      RAISE;
  
  END timecard_load;
  
END lego_timecard;
/