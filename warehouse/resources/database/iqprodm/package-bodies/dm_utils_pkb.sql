CREATE OR REPLACE PACKAGE BODY dm_utils
AS
/******************************************************************************
NAME:       DM_UTILS
PURPOSE:    To perform utilify functions and procedures of a general nature.
          
Ver    Date        Author       Description
-----  ----------  -----------  ------------------------------------     
1.0                             Initial creation.
1.1    07/09/2016  jpullifrone  Add enable/disable procs, and alter chain.
       08/01/2016  jpullifrone  IQN-33792 Nothing changed here in this proc but noting that
                                          reference to this proc has been removed from FO
                                          Legacy deploy scripts.
1.2    08/05/2016  jpulliforne IQN-33877 Added refresh_mv procedure.                                      
       09/12/2016  jpullifrone IQN-34535 package was overwritten during 16.10 release.  Nothing changing here.     
 ******************************************************************************/
  gc_curr_schema             CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
  gc_source                  CONSTANT VARCHAR2(30) := 'DM_UTILS';
  
  PROCEDURE refresh_mv (pi_mv_name  VARCHAR2,
                        pi_method   VARCHAR2,
                        pi_start_ts TIMESTAMP DEFAULT SYSTIMESTAMP) IS
                        
  lv_source           VARCHAR2(61) := gc_source || '.refresh_mv';
  lv_job_name         VARCHAR2(30) := SUBSTR('MV_'||UPPER(pi_mv_name),1,30);
  lv_job_str          VARCHAR2(3000);
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('refresh_mv');  
  
    lv_job_str :=
      'BEGIN
        logger_pkg.instantiate_logger;
        logger_pkg.set_source('''||lv_job_name||''');
        DBMS_MVIEW.REFRESH('''||pi_mv_name||''','''||pi_method||''');
        logger_pkg.unset_source('''||lv_job_name||''');
      EXCEPTION
        WHEN OTHERS THEN                                       
          logger_pkg.unset_source('''||lv_job_name||''');                                       
      END;';

    logger_pkg.info(lv_job_str);
    
    DBMS_SCHEDULER.CREATE_JOB (
          job_name             => lv_job_name,
          job_type             => 'PLSQL_BLOCK',
          job_action           => lv_job_str,
          start_date           => pi_start_ts,
          enabled              => TRUE,
          comments             => 'Refresh Materialized View, '||pi_mv_name||' - Refresh method = '||pi_method);
  
    logger_pkg.unset_source(lv_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.unset_source(lv_source);
      RAISE;                        
                        
  END refresh_mv;
  
  --------------------------------------------------------------------------------
  PROCEDURE enable_refresh_job (pi_job_name VARCHAR2) IS
  BEGIN
    dbms_scheduler.enable(NAME => pi_job_name);
  END enable_refresh_job;

  --------------------------------------------------------------------------------
  PROCEDURE disable_refresh_job (pi_job_name VARCHAR2) IS
  BEGIN
    dbms_scheduler.disable(NAME => pi_job_name);
  END disable_refresh_job;
  
  --------------------------------------------------------------------------------  
  PROCEDURE alter_chain (pi_chain_name VARCHAR2,
                         pi_step_name  VARCHAR2,
                         pi_attribute  VARCHAR2,
                         pi_value      BOOLEAN) AS

  BEGIN  
  
    DBMS_SCHEDULER.ALTER_CHAIN (
       chain_name              => pi_chain_name,
       step_name               => pi_step_name,
       attribute               => pi_attribute,
       value                   => pi_value);

  END alter_chain;
  
  --------------------------------------------------------------------------------  
  PROCEDURE alter_chain (pi_chain_name VARCHAR2,
                         pi_step_name  VARCHAR2,
                         pi_attribute  VARCHAR2,
                         pi_value      VARCHAR2) AS

  BEGIN  
  
    DBMS_SCHEDULER.ALTER_CHAIN (
       chain_name              => pi_chain_name,
       step_name               => pi_step_name,
       attribute               => pi_attribute,
       char_value              => pi_value);

  END alter_chain;  
  
    FUNCTION get_std_title
    (
        p_fo_title    IN VARCHAR2
      , p_buyerorg_id IN NUMBER
      , p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
      , p_type        IN VARCHAR2 DEFAULT 'DESC'
    )
    RETURN VARCHAR2
    IS
          v_std_title           dm_job_titles.std_job_title_desc%TYPE;
          v_std_job_title_id    dm_job_titles.std_job_title_id%TYPE;
    BEGIN
          SELECT std_job_title_desc
                 ,std_job_title_id
            INTO v_std_title
                ,v_std_job_title_id
            FROM (
                   SELECT t.std_job_title_desc
                          ,t.std_job_title_id
                          , ROW_NUMBER() OVER (ORDER BY m.job_id DESC) AS rnk
                     FROM dm_fo_title_map m, dm_job_titles t
                    WHERE m.job_title = UPPER(RTRIM(LTRIM(p_fo_title)))
                      AND m.buyerorg_id = p_buyerorg_id
                      AND m.data_source_code = p_source_code
                      AND t.std_job_title_id = m.std_job_title_id
                      AND t.is_deleted = 'N'
                      AND t.std_job_category_id > 0
                 )
           WHERE rnk = 1;
         
          RETURN(CASE WHEN p_type ='DESC' THEN  v_std_title ELSE v_std_job_title_id END);
    EXCEPTION
          WHEN OTHERS THEN RETURN(CASE WHEN p_type ='DESC' THEN 'UNMAPPED' ELSE '0' END);
    END get_std_title;

    FUNCTION get_std_category
    (
        p_fo_title    IN VARCHAR2
      , p_buyerorg_id IN NUMBER
      , p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
      , p_type        IN VARCHAR2 DEFAULT 'DESC'
    )
    RETURN VARCHAR2
    IS
          v_std_category dm_job_category.std_job_category_desc%TYPE;
          v_std_category_id dm_job_category.std_job_category_id%TYPE;
    BEGIN
          SELECT std_job_category_desc
                 ,std_job_category_id
            INTO v_std_category
                 ,v_std_category_id
            FROM (
                   SELECT c.std_job_category_desc
                          ,c.std_job_category_id
                          , ROW_NUMBER() OVER (ORDER BY m.job_id DESC) AS rnk
                     FROM dm_fo_title_map m, dm_job_titles t, dm_job_category c
                    WHERE m.job_title = UPPER(RTRIM(LTRIM(p_fo_title)))
                      AND m.buyerorg_id = p_buyerorg_id
                      AND m.data_source_code = p_source_code
                      AND t.std_job_title_id = m.std_job_title_id
                      AND t.is_deleted = 'N'
                      AND t.std_job_category_id > 0
                      AND c.std_job_category_id = t.std_job_category_id
                 )
           WHERE rnk = 1;

          RETURN(CASE WHEN p_type ='DESC' THEN  v_std_category ELSE v_std_category_id END);
    EXCEPTION
          WHEN OTHERS THEN RETURN(CASE WHEN p_type ='DESC' THEN 'UNMAPPED' ELSE '0' END);
    END get_std_category;

    PROCEDURE send_email
    (
        sender    IN VARCHAR2
      , recipient IN VARCHAR2
      , subject   IN VARCHAR2
      , message   IN VARCHAR2
    )
    IS
        mail_conn UTL_SMTP.CONNECTION;
        mesg      VARCHAR2(32676);
        mailhost  VARCHAR2(16) := 'mailhost';
        comma_loc NUMBER := 0; 
        start_loc NUMBER := 1; 
        more_rcpt VARCHAR2(1) := 'Y';
        v_addr    VARCHAR2(128);
        v_env    VARCHAR2(16);
        v_suser  VARCHAR2(16);
        v_role   VARCHAR2(16);
    BEGIN
        SELECT sys_context('USERENV','SESSION_USER'), sys_context('USERENV','DB_NAME'), sys_context('USERENV', 'DATABASE_ROLE')
          INTO v_suser, v_env, v_role
          FROM DUAL;
        
        mail_conn := utl_smtp.open_connection(mailhost);
        UTL_SMTP.HELO(mail_conn, mailhost);
        UTL_SMTP.MAIL(mail_conn, sender);
  
        /*
        ** Following loop handles multiple
        ** recipients with e-mail addresses separated by comma
        */
        WHILE (more_rcpt = 'Y')
        LOOP
             comma_loc := INSTR(recipient, ',', start_loc);
             IF (comma_loc = 0) 
                THEN
                      more_rcpt := 'N';
                      v_addr := SUBSTR(recipient, start_loc);
                ELSE
                      v_addr := SUBSTR(recipient, start_loc, comma_loc - start_loc);
                      start_loc := comma_loc + 1;
             END IF;
             UTL_SMTP.RCPT(mail_conn, v_addr);
        END LOOP;
  
        mesg := 'Subject: ' || subject || '- ' || v_env || c_crlf || 'Process Timestamp = ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') || c_crlf || 'Oracle User ID = ' || v_suser || '@' || v_env || '(' || v_role || ')' || c_crlf || message;
  
        utl_smtp.data(mail_conn, mesg);
        utl_smtp.quit(mail_conn);
    END send_email;

--    FUNCTION weekend_days_between
--    (
--        p_start_date IN DATE
--      , p_end_date   IN DATE
--    )
--    RETURN NUMBER
--    IS
--        wend_days NUMBER := 0;
--    BEGIN
--        IF (p_start_date IS NULL OR p_end_date IS NULL OR (p_start_date > p_end_date))
--           THEN
--                RETURN(0);
--        END IF;
--        wend_days := TRUNC((TRUNC(p_end_date,'D')-TRUNC(p_start_date,'D'))/7)*2;
--
--        /* Adjust for ending date on a saturday */
--        IF TO_CHAR(p_end_date,'D') = '7'
--           THEN
--                wend_days := wend_days + 1;
--        END IF;
--
--        /* Adjust for starting date on a sunday */
--        IF TO_CHAR(p_start_date,'D') = '1'
--           THEN
--                wend_days := wend_days + 1;
--        END IF;
--        RETURN(wend_days);
--    END weekend_days_between;

    FUNCTION bdays
    (
        start_date IN DATE
      , end_date   IN DATE
      , region     IN VARCHAR2 DEFAULT 'USA'
    ) 
    RETURN NUMBER 
    IS
          retval         NUMBER(15,7);
          new_start_date DATE;
          new_end_date   DATE;
          bdaystart      NUMBER(15,15);
          bdayend        NUMBER(15,15);
    BEGIN
          new_start_date := start_date;
          new_end_date   := end_date;

          -- set defaults for business day start and end. Can be overridden per region
          bdaystart := 7/24;
          bdayend   := 17/24;

          IF (region ='Europe')
             THEN
                  new_start_date := new_start_date + 9/24;
                  new_end_date   := new_end_date   + 9/24;
                  bdaystart      := 9/24;
                  bdayend        := 18.5/24;
          END IF;
          IF (region = 'Asia-Pac')
             THEN
                  new_start_date := new_start_date + 15/24;
                  new_end_date   := new_end_date   + 15/24;
          END IF;

          --Start After end of day, make start be start of next day
          IF (new_start_date - TRUNC(new_start_date) > bdayend)
             THEN
                  new_start_date := TRUNC(new_start_date+1) + bdaystart;
          END IF;

          --Start before start of day, make start be start of same day
          IF (new_start_date-TRUNC(new_start_date) < bdaystart)
             THEN
                  new_start_date := TRUNC(new_start_date) + bdaystart;
          END IF;

          --Start Saturday, make start be Monday start of day
          IF (TO_CHAR(new_start_date, 'D') = 7)
             THEN
                  new_start_date := TRUNC(new_start_date+2) + bdaystart;  
          END IF;

          --Start Sunday, make start be Monday start of day
          IF (TO_CHAR(new_start_date, 'D') = 1)
             THEN
                  new_start_date := TRUNC(new_start_date+1) + bdaystart;
          END IF;

          -- end after end of day, make end be end of day same day
          IF (new_end_date-TRUNC(new_end_date) > bdayend)
             THEN
                  new_end_date := TRUNC(new_end_date) + bdayend;
          END IF;

          -- end before start of day, make end be start of day the same day
          IF (new_end_date-trunc(new_end_date) < bdaystart)
             THEN
                  new_end_date := TRUNC(new_end_date) + bdaystart;
          END IF;

          --end on Saturday, make it be the end of the day on Friday
          IF (TO_CHAR(new_end_date, 'D') =7)
             THEN
                  new_end_date := TRUNC(new_end_date-1) + bdayend;
          END IF;

          --end on Sunday, make it be the end of the day on Friday
          IF (TO_CHAR(new_end_date,'D') = 1)
             THEN
                  new_end_date := trunc(new_end_date-2) + bdayend;
          END IF;

          --factor out weekend days
          retval := new_end_date - new_start_date -
                    ((TRUNC(new_end_date,'D') - TRUNC(new_start_date,'D'))/7)*2;

          -- if holidays were to be calculated, the calculation would go here

          -- if end is during nonbusiness hours, difference could be negative
          IF (retval < 0)
             THEN
                  retval := 0;
          END IF;

          RETURN(retval);
END;

END dm_utils;
/