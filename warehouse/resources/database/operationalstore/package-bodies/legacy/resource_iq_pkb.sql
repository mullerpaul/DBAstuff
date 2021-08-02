CREATE OR REPLACE PACKAGE BODY resource_iq
/******************************************************************************
     NAME:      RESOURCE_IQ
     PURPOSE:   This package contains all the procedures related to ResourceIQ
  
     REVISIONS: 
     Ver     Date        Author        Description
     ------  ----------  ------------  ------------------------------------
     1.0     06/09/2014  pkattula      Initial Version
     2.0     07/29/2014  pkattula      Enhancements to perform search/scoring
                                       based on OracleText Multi-ColumnIndex
     3.0     08/04/2014  mdunlap       Revamp base query with all-inclusive 
                                       lego_cand_search (get_candidate_list2)
									   Keep original for benchmarking.
******************************************************************************/
AS
PROCEDURE get_candidate_list
(
    p_buyerorg_id             IN  lego_buyer_org_vw.buyer_org_id%TYPE
  , p_days_till_end           IN  lego_assignment_vw.days_until_assignment_end%TYPE
  , p_months_since_completed  IN  lego_assignment_vw.days_until_assignment_end%TYPE
  , p_manager_id              IN  lego_assignment_vw.hiring_mgr_person_id%TYPE
  , p_job_title               IN  lego_cand_search.job_position_title%TYPE
  , p_title_words             IN  lego_cand_search.job_position_title%TYPE
  , p_candidate_list          OUT SYS_REFCURSOR
)
AS 
    v_sql         VARCHAR2(4096);
    v_title_words VARCHAR2(1000);
    v_job_title   VARCHAR2(1000);
BEGIN 
    -- Remove Any single quotes and Strip Anything after 1000 Chars
    v_title_words := SUBSTR(REPLACE(p_title_words, ''''), 1, 1000);
    v_job_title   := SUBSTR(REPLACE(p_job_title,   ''''), 1, 1000);

    IF (UPPER(v_title_words) = 'NULL')
       THEN v_title_words := NULL;
    END IF;

    IF (UPPER(v_job_title) = 'NULL')
       THEN v_job_title   := NULL;
    END IF;

    v_sql := 'SELECT   lbo.buyer_name 
                     , lso.supplier_name
                     , lav.contractor_person_id
                     , pc.contractor_name
                     , lav.assignment_start_dt
                     , lav.assignment_actual_end_dt 
                     , lav.reg_bill_rate
                     , lav.reg_pay_rate
                     , lav.rate_type
                     , lav.assignment_currency
                     , lav.assign_job_title
                     , lav.hiring_mgr_person_id
                     , hm.hiring_mgr_name
                     , ad.city || NVL2(ad.city, '', '', NULL) || ad.state || NVL2(ad.state, '', '', NULL) || ad.country AS work_location
                     , j.job_position_title
                     , j.job_description
                     , j.jc_description
                     , j.job_level_desc';

    IF (v_title_words IS NULL AND v_job_title IS NULL)
       THEN
            v_sql := v_sql || ', 0 AS match_score';
       ELSE
            v_sql := v_sql || ', SCORE(1) AS match_score';
    END IF;

    v_sql := v_sql ||
      ' FROM   lego_buyer_org_vw lbo
             , lego_assignment_vw lav
             , lego_person_contractor_vw pc
             , lego_person_hiring_mgr_vw hm
             , lego_address_vw ad
             , lego_job_vw j
             , lego_supplier_org_vw  lso';

    IF (v_title_words IS NOT NULL OR v_job_title IS NOT NULL)
       THEN
            v_sql := v_sql || ', lego_cand_search lcs';
    END IF;

    v_sql := v_sql ||
     ' WHERE lbo.buyer_org_id = :B1
         AND lav.buyer_org_id = lbo.buyer_org_id
         AND ( (lav.assignment_state IN (''Effective'', ''Effective - On Board'', ''Awaiting Start Date'')
               AND lav.days_until_assignment_end <= :B2)
               OR
               (lav.assignment_state = ''Completed'' AND lav.assignment_actual_end_dt > ADD_MONTHS(SYSDATE, -:B3))
             )
         AND pc.contractor_person_id = lav.contractor_person_id
         AND pc.contractor_do_not_rehire_flag = ''N''
         AND hm.hiring_mgr_person_id = lav.hiring_mgr_person_id
         AND ad.address_guid (+) = lav.address_guid
         AND j.job_id(+) = lav.job_id
         AND lso.supplier_org_id = lav.supplier_org_id';

    IF (v_title_words IS NOT NULL OR v_job_title IS NOT NULL)
       THEN
            v_sql := v_sql || ' AND lcs.assignment_continuity_id = lav.assignment_continuity_id
                     AND CONTAINS(lcs.job_position_title,';
    
            IF (v_job_title IS NOT NULL)
               THEN v_sql := v_sql || '''((' || v_job_title || ') WITHIN (job_position_title))*' || c_jt_weight; 
            END IF;

            IF (v_title_words IS NOT NULL)
               THEN 
                    IF (v_job_title IS NOT NULL)
                       THEN
                            v_sql := v_sql || ' ACCUM ';
                       ELSE
                            v_sql := v_sql || '''';
                    END IF;
                    v_sql := v_sql ||  '((' || v_title_words || ') WITHIN (job_description))*' || c_jd_weight ||
						   ' ACCUM ((' || v_title_words || ') WITHIN (job_level_desc))*' || c_jl_weight ||
                           ' ACCUM ((' || v_title_words || ') WITHIN (skill_list))*' || c_js_weight || ''', 1) > 0';
               ELSE 
                    v_sql := v_sql || ''', 1) > 0';
            END IF;
    END IF;

    -- Query to include all sub-orgs
    --      SELECT LEVEL org_level, buyer_org_id, buyer_name
    --        FROM lego_buyer_org_vw
    --       START WITH buyer_org_id = :B1
    --     CONNECT BY PRIOR buyer_org_id = buyer_parent_bus_org_id
    --       ORDER BY LEVEL

    IF (p_manager_id IS NOT NULL)
       THEN
             v_sql := v_sql || ' AND lav.hiring_mgr_person_id = :B4';
             IF (v_title_words IS NOT NULL)
                THEN
                     v_sql := v_sql || ' ORDER BY SCORE(1) DESC';
             END IF;
             --INSERT INTO pk_sql VALUES(v_sql); COMMIT;
             OPEN p_candidate_list FOR v_sql USING p_buyerorg_id, p_days_till_end, p_months_since_completed, p_manager_id;
       ELSE
             IF (v_title_words IS NOT NULL)
                THEN
                     v_sql := v_sql || ' ORDER BY SCORE(1) DESC';
             END IF;
             --INSERT INTO pk_sql VALUES(v_sql); COMMIT;
             OPEN p_candidate_list FOR v_sql USING p_buyerorg_id, p_days_till_end, p_months_since_completed;
    END IF;

END get_candidate_list;

PROCEDURE get_candidate_list2
(
    p_buyerorg_id             IN  lego_buyer_org_vw.buyer_org_id%TYPE
  , p_days_till_end           IN  lego_assignment_vw.days_until_assignment_end%TYPE
  , p_months_since_completed  IN  lego_assignment_vw.days_until_assignment_end%TYPE
  , p_manager_id              IN  lego_assignment_vw.hiring_mgr_person_id%TYPE
  , p_job_title               IN  lego_cand_search.job_position_title%TYPE
  , p_title_words             IN  lego_cand_search.job_position_title%TYPE
  , p_candidate_list          OUT SYS_REFCURSOR
)
AS 
    v_sql         VARCHAR2(4096);
    v_title_words VARCHAR2(1000);
    v_job_title   VARCHAR2(1000);
   
    --> Error Steps and potential logging.  
    v_step          VARCHAR2(40);
    v_param_filter  VARCHAR2(3000);
    v_locale        VARCHAR(30);
    v_locale_id     NUMBER;
    v_personid      NUMBER;
    ov_err_msg      VARCHAR2(4000);
    on_err_no       NUMBER;
    
BEGIN 
    -- Remove Any single quotes and OTS Reserved Characters and Strip Everything after 1000 Chars    
    v_job_title     := SUBSTR(REGEXP_REPLACE(p_job_title, '[^a-zA-Z0-9/\ ]'), 1, 1000);
    v_title_words   := SUBSTR(REPLACE(p_title_words,   ''''), 1, 1000);
    v_title_words   := SUBSTR(REGEXP_REPLACE(p_title_words, '[^a-zA-Z0-9,/\ ]'), 1, 1000);
    
    --> Remove reserved words from Job Title and Keyword variables:  Left in AND, OR 
    v_job_title := REGEXP_REPLACE(v_job_title,
   'ABOUT,|ACCUM,|BT,|BTG,|BTI,|BTP,|EQUIV,|FUZZY,|HASPATH,|INPATH,|MDATA,|MINUS,|NEAR,|NOT,|NT,|NTG,|NTI,|NTP,|PT,|RT,|SQE,|SYN,|TR,|TRSYN,|TT,|WITHIN,|ABOUT|ACCUM|BT|BTG|BTI|BTP|EQUIV|FUZZY|HASPATH|INPATH|MDATA|MINUS|NEAR|NOT|NT|NTG|NTI|NTP|PT|RT|SQE|SYN|TR|TRSYN|TT|WITHIN');
    v_title_words := REGEXP_REPLACE(v_title_words,
   'ABOUT,|ACCUM,|BT,|BTG,|BTI,|BTP,|EQUIV,|FUZZY,|HASPATH,|INPATH,|MDATA,|MINUS,|NEAR,|NOT,|NT,|NTG,|NTI,|NTP,|PT,|RT,|SQE,|SYN,|TR,|TRSYN,|TT,|WITHIN,|ABOUT|ACCUM|BT|BTG|BTI|BTP|EQUIV|FUZZY|HASPATH|INPATH|MDATA|MINUS|NEAR|NOT|NT|NTG|NTI|NTP|PT|RT|SQE|SYN|TR|TRSYN|TT|WITHIN');
    --> Remove consecutive comas.  
    v_title_words  := REGEXP_REPLACE(REGEXP_REPLACE(v_title_words, ', | ,', ','), ',{1,}', ',');
    --> remove Leading and Trailing Comas...
    v_title_words  := TRIM(BOTH ',' from v_title_words) ;

    --> Set parameters via system context
    select NVL(iqn_session_context_pkg.get_current_locale_string() ,'EN_US')
    into v_locale
    from dual;
    
    select NVL(iqn_session_context_pkg.get_current_locale_preference(), 0)
    into v_locale_id
    from dual;
    
    select iqn_session_context_pkg.get_current_user() 
    into v_personid
    from dual;

    IF (UPPER(v_title_words) = 'NULL')
       THEN v_title_words := NULL;
    END IF;

    IF (UPPER(v_job_title) = 'NULL')
       THEN v_job_title   := NULL;
    END IF;
    
    v_step := 'Start Building Query';
    v_sql := 'SELECT   lcs.buyer_name 
                     , lcs.supplier_name
                     , lcs.contractor_person_id
                     , lcs.contractor_name
                     , lcs.assignment_start_dt
                     , lcs.assignment_actual_end_dt 
                     , lcs.reg_bill_rate
                     , lcs.reg_pay_rate
                     , lcs.rate_type
                     , lcs.assignment_currency
                     , lcs.hiring_mgr_person_id
                     , lcs.hiring_mgr_name
                     , lcs.assignment_state
                     , lcs.current_phase
                     , lcs.work_location
                     , lcs.job_position_title assign_job_title
                     , lcs.job_position_title
                     , lcs.jc_description
                     , lcs.job_description
                     , lcs.job_level_desc
                     , lcs.linkedin_url
                     , lcs.assignment_continuity_id assignment_id
                     , lcs.job_id  
                     , lcs.candidate_id   ';

    IF (v_title_words IS NULL AND v_job_title IS NULL)
       THEN
            v_step := 'Option No Scoring';
            v_sql := v_sql || ', 
            0 AS match_score';
       ELSE
            v_step := 'Include Scoring';
            v_sql := v_sql || '
            , SCORE(1) AS match_score
            ';
    END IF;

    v_step := 'Add Base Table';
    v_sql := v_sql ||
      ' FROM lego_cand_search lcs 
      ';
    v_step := 'Add Where Clause';
    v_sql := v_sql ||
     ' WHERE lcs.buyer_org_id = :B1  
         AND lcs.locale_id = '||v_locale_id ||'
         AND ( (lcs.assignment_state_id IN (8, 9, 3)
               AND NVL(lcs.days_until_assignment_end,ABS(TRUNC(assignment_actual_end_dt-sysdate))) <= :B2) 
               OR
               (lcs.assignment_state_id = 7 AND lcs.assignment_actual_end_dt > ADD_MONTHS(SYSDATE, -:B3)) 
             )';

    IF (v_title_words IS NOT NULL OR v_job_title IS NOT NULL)
       THEN
            v_step := 'Add Contains Clause';
            v_sql := v_sql || '
                     AND CONTAINS(lcs.job_position_title,';
    
            IF (v_job_title IS NOT NULL)
               THEN 
                   v_step := 'Include Job Title Search';
                   v_sql := v_sql || '''((' || v_job_title || ') WITHIN (job_position_title))*' || c_jt_weight; 
            END IF;

            IF (v_title_words IS NOT NULL)
               THEN 
                    IF (v_job_title IS NOT NULL)
                       THEN
                            v_step := 'Include Job Title, Keyword Search';
                            v_sql := v_sql || ' ACCUM ';
                       ELSE
                            v_step := 'Only Job Title Search';
                            v_sql := v_sql || '''';
                    END IF;
                    
                    v_step := 'Include Descr, Skill, Level';
                    v_sql := v_sql ||  '((' || v_title_words || ') WITHIN (job_description))*' || c_jd_weight ||
                           ' ACCUM ((' || v_title_words || ') WITHIN (job_position_title))*' || c_jt_weight ||
                           ' ACCUM ((' || v_title_words || ') WITHIN (job_level_desc))*' || c_jl_weight ||
                           ' ACCUM ((' || v_title_words || ') WITHIN (skill_list))*' || c_js_weight || ''', 1) > 0';
               ELSE 
                    v_step := 'Score must be greater than 0';
                    v_sql := v_sql || ''', 1) > 0';
            END IF;
    END IF;
    
    v_param_filter := 'BuyerOrg: '||p_buyerorg_id||' | '||
                      'DaysTillAssgnEnd: '|| p_days_till_end||' | '|| 
                      'MonSinceAssgnCompl:' || p_months_since_completed||' | '||
                      'HiringMgrID: ' ||p_manager_id ||' | ' ||
                      'JobTitleInput: '||v_job_title||' | '||
                      'Locale:'|| v_locale_id || ' | ' ||
                      'Person ID: ' || v_personid || ' | ' ||
                      'KeywordsInput: '||v_title_words;


    IF (p_manager_id IS NOT NULL)
       THEN
             v_step := 'Include HM Filter';
             v_sql := v_sql || ' AND lcs.hiring_mgr_person_id = :B4';
             IF (v_title_words IS NOT NULL)
                THEN
                     v_step := 'Order Result Set';
                     v_sql := v_sql || ' ORDER BY SCORE(1) DESC';
             END IF;
             --INSERT INTO pk_sql VALUES(v_sql); COMMIT;
             v_step := 'Return Ref_Cursor with 4 param';
             OPEN p_candidate_list FOR v_sql USING p_buyerorg_id, p_days_till_end, p_months_since_completed, p_manager_id;
       ELSE
             IF (v_title_words IS NOT NULL)
                THEN
                     v_step := 'Order Result Set';
                     v_sql := v_sql || ' ORDER BY SCORE(1) DESC';
             END IF;
             --INSERT INTO pk_sql VALUES(v_sql); COMMIT;
             v_step := 'Return Ref_Cursor with 3 param';
             OPEN p_candidate_list FOR v_sql USING p_buyerorg_id, p_days_till_end, p_months_since_completed;
    END IF;
    
    load_usage_data(p_buyerorg_id, p_manager_id, p_job_title, p_title_words, v_personid, v_param_filter ); 

EXCEPTION WHEN OTHERS THEN
     ov_err_msg := SUBSTR(SQLERRM,1,4000);
     load_usage_data(p_buyerorg_id, p_manager_id, p_job_title, p_title_words, 'Error on: '||v_param_filter);
     on_err_no  := RPT_UTIL_LOG.f_log_error ('When others exception', ov_err_msg, v_step||' - '||v_param_filter||' with 
          '||v_sql);
     ROLLBACK;
     RAISE;  

END get_candidate_list2;

PROCEDURE load_usage_data ( p_buyerorg_id             IN  lego_buyer_org_vw.buyer_org_id%TYPE DEFAULT NULL
                          , p_manager_id              IN  lego_assignment_vw.hiring_mgr_person_id%TYPE DEFAULT NULL
                          , p_job_title               IN  lego_cand_search.job_position_title%TYPE DEFAULT NULL
                          , p_title_words             IN  lego_cand_search.job_position_title%TYPE DEFAULT NULL
                          , p_personid                IN  lego_assignment_vw.hiring_mgr_person_id%TYPE DEFAULT NULL
                          , v_param_filter            IN  VARCHAR2 DEFAULT NULL 
        )               
      AS                   
     PRAGMA AUTONOMOUS_TRANSACTION;
     
     v_started_ts timestamp;

  BEGIN
        SELECT systimestamp 
          INTO v_started_ts
          FROM dual;
          
        INSERT INTO LEGO_RESOURCEIQ_USE 
           (BUYER_ORG_ID, 
            STARTTIME, 
            JOB_TITLE, 
            HIRING_MGR_ID, 
            KEYWORDS, 
            PARAMVALPASS, 
            PERSON_ID)
        VALUES
           (p_buyerorg_id, 
            v_started_ts,
            p_job_title, 
            p_manager_id, 
            p_title_words, 
            v_param_filter,
            p_personid);
            
        COMMIT;                          
     
  END load_usage_data;

PROCEDURE load_scoring_weights
IS
   CURSOR c_score_weights IS
          SELECT parameter_name, number_value
            FROM lego_parameter
           WHERE parameter_name LIKE 'ResIQ%WEIGHT';
BEGIN
      FOR weight_rec IN c_score_weights
      LOOP
           CASE (weight_rec.parameter_name)
              WHEN 'ResIQ_JT_WEIGHT' THEN c_jt_weight   := weight_rec.number_value;
              WHEN 'ResIQ_JD_WEIGHT' THEN c_jd_weight   := weight_rec.number_value;
              WHEN 'ResIQ_JL_WEIGHT' THEN c_jl_weight   := weight_rec.number_value;
              WHEN 'ResIQ_JS_WEIGHT' THEN c_js_weight   := weight_rec.number_value;
              ELSE NULL;
           END CASE;
      END LOOP;

      --DBMS_OUTPUT.PUT_LINE('c_jt_weight     : ' || c_jt_weight);
      --DBMS_OUTPUT.PUT_LINE('c_jd_weight     : ' || c_jd_weight);
      --DBMS_OUTPUT.PUT_LINE('c_jl_weight     : ' || c_jl_weight);
      --DBMS_OUTPUT.PUT_LINE('c_js_weight     : ' || c_js_weight);

      -- If Any Parameters are missing in lego table
      -- apply defaults
      IF (c_jt_weight IS NULL)
         THEN
               c_jt_weight := 10;
      END IF;
      IF (c_jd_weight IS NULL)
         THEN
               c_jd_weight := 9;
      END IF;
      IF (c_jl_weight IS NULL)
         THEN
               c_jl_weight := 2;
      END IF;
      IF (c_js_weight IS NULL)
         THEN
               c_js_weight := 9;
      END IF;
END load_scoring_weights;

BEGIN
    load_scoring_weights;
END resource_iq;
/



