CREATE OR REPLACE PACKAGE BODY dm_geographic_rate_process
/********************************************************************
 * Name: dm_geographic_rate_process
 * Desc: This package contains all the procedures required to
 *       get the regional avaerage rates and percentiles
 *
 * Author   Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   01/20/10     Initial
 * sajeev  11/11/11     Changed from dba_jobs to user_jobs
 ********************************************************************/
AS
  PROCEDURE p_rate_process(id_run_date         IN DATE,
                           iv_period_type      IN VARCHAR2,
                           iv_geographic_level IN VARCHAR2,
                           in_region_type      IN NUMBER,
                           iv_new_assign_flag  IN VARCHAR2,
                           in_msg_id           IN NUMBER,
                           id_ytd_date         IN DATE,
                           on_err_num         OUT NUMBER,
                           ov_err_msg         OUT VARCHAR2)
  IS
    le_exception          EXCEPTION;
    ln_start_month_number NUMBER;
    ln_end_month_number   NUMBER;
    ln_region_id          NUMBER;
    ln_job_title_id       NUMBER;
    lv_proc_name          VARCHAR2(100)           := 'dm_geographic_rate_process.p_rate_process' ;
    lv_app_err_msg        VARCHAR2(2000)          := NULL;
    lv_db_err_msg         VARCHAR2(2000)          := NULL;
    lv_cmsa_code          VARCHAR2(6);
    ld_date               DATE                    := SYSDATE;


  BEGIN
         on_err_num := 0;
         on_err_num := NULL;
         --
         -- Get the start month number and end month number/ Period number and Types
         --
         IF iv_period_type     = 'Q'   THEN -- Quarter
           ln_start_month_number := to_number(to_char(TRUNC(id_run_date,'Q'),'YYYYMM'));
           ln_end_month_number   := to_number(to_char(id_run_date,'YYYYMM'));
         ELSIF iv_period_type  =  'Y'  THEN -- Year
           ln_start_month_number := to_number(to_char(id_run_date,'YYYY')||'01');

           IF to_number(to_char(id_run_date,'YYYY')) = to_number(to_char(id_ytd_date,'YYYY')) THEN

           ln_end_month_number   := to_number(to_char(id_ytd_date,'YYYYMM'));
           ELSE
            ln_end_month_number   :=to_number(to_char(id_run_date,'YYYY')||'12');
           END IF;
         ELSE -- Month
           ln_start_month_number := to_number(to_char(id_run_date,'YYYYMM'));
           ln_end_month_number   := to_number(to_char(id_run_date,'YYYYMM'));
         END IF;

         --
         -- Assign the appropriate values to the variables depending on the geographic level
         --
         IF iv_geographic_level = 'N' THEN -- National
            lv_cmsa_code    := 'USA';
            ln_region_id    := 9999;
         ELSIF iv_geographic_level like 'R%' THEN -- Regional
            lv_cmsa_code    := 'USA';
         ELSIF iv_geographic_level = 'JCN' THEN -- Job category (National)
            lv_cmsa_code    := 'USA';
            ln_region_id    := 9999;
            ln_job_title_id := 9999;
         ELSIF iv_geographic_level = 'JCC' THEN -- Job category cmsa
            ln_job_title_id := 9999;
         ELSIF iv_geographic_level like 'JCR%' THEN -- Job Category Regional
            lv_cmsa_code    := 'USA';
            ln_job_title_id := 9999;
         END IF;

         --
         -- Run the sql statement to insert the geographic rates data.
         --

         BEGIN
           IF iv_new_assign_flag = 'N' THEN -- not used for new assignment hot spots
            INSERT
              INTO dm_geographic_rates_summary_t
                   (geographic_level,
                    new_assignment_flag,
                    std_region_id,
                    cmsa_code,
                    period_number,
                    period_type,
                    std_job_title_id,
                    std_job_category_id,
                    assignment_count,
                    assignment_data_points,
                    assignment_activity_count,
                    avg_reg_bill_rate,
                    avg_reg_pay_rate,
                    reg_bill_rate_10_pctl,
                    reg_pay_rate_10_pctl,
                    reg_bill_rate_25_pctl,
                    reg_pay_rate_25_pctl,
                    reg_bill_rate_50_pctl,
                    reg_pay_rate_50_pctl,
                    reg_bill_rate_75_pctl,
                    reg_pay_rate_75_pctl,
                    reg_bill_rate_90_pctl,
                    reg_pay_rate_90_pctl,
                    currency_description,
                    load_key,
                    last_update_date
                   )
            SELECT iv_geographic_level,
                   iv_new_assign_flag,
                   a.std_region_id,
                   a.cmsa_code,
                   a.period_number,
                   iv_period_type,
                   a.std_job_title_id,
                   a.std_job_category_id,
                   count(distinct a.assignment_count)                                assignment_count,
                   count(distinct a.assignment_data_points)                          assignment_data_points,
                   count(distinct a.assignment_activity_count)                       assignment_activity_count,
                   (sum(a.reg_bill_rate)/count(distinct a.assignment_data_points))   avg_reg_bill_rate,
                   (sum(a.reg_pay_rate)/count(distinct a.assignment_data_points))    avg_reg_pay_rate,
                   a.reg_bill_rate_10_pctl,
                   a.reg_pay_rate_10_pctl,
                   a.reg_bill_rate_25_pctl,
                   a.reg_pay_rate_25_pctl,
                   a.reg_bill_rate_50_pctl,
                   a.reg_pay_rate_50_pctl,
                   a.reg_bill_rate_75_pctl,
                   a.reg_pay_rate_75_pctl,
                   a.reg_bill_rate_90_pctl,
                   a.reg_pay_rate_90_pctl,
                   a.currency_description,
                   in_msg_id,
                   ld_date
              FROM
                   (
                    SELECT CASE
                           WHEN iv_geographic_level IN ('N','JCN') THEN -- national or job category level
                            ln_region_id
                           ELSE
                            rm.std_region_id
                           END                                                                     std_region_id,
                           CASE
                           WHEN iv_geographic_level IN ('C','JCC') THEN -- cmsa level
                            w.cmsa_code
                           ELSE
                            lv_cmsa_code
                           END                                                                     cmsa_code,
                           CASE
                           WHEN iv_period_type  = 'Q' THEN
                             to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                           WHEN iv_period_type  = 'Y' THEN
                             to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                           ELSE
                             w.month_number
                           END                                                                     period_number,
                           CASE
                           WHEN iv_geographic_level like 'JC%' THEN --job category level
                            ln_job_title_id
                           ELSE
                            w.std_job_title_id
                           END                                                                     std_job_title_id,
                           w.std_job_category_id,
                           w.reg_bill_rate                                                         reg_bill_rate,
                           w.reg_pay_rate                                                          reg_pay_rate,
                           w.data_source_code||w.assignment_id                                     assignment_count,
                           w.data_source_code||w.assignment_id||w.assignment_seq_number||w.month_number            assignment_data_points,
                           w.data_source_code||w.assignment_id||w.reg_bill_rate                    assignment_activity_count,
                           percentile_cont (0.1)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_bill_rate_10_pctl,
                           percentile_cont (0.1)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_pay_rate_10_pctl,
                           percentile_cont (0.25)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                          w.std_job_category_id)    reg_bill_rate_25_pctl,
                           percentile_cont (0.25)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                          w.std_job_category_id)    reg_pay_rate_25_pctl,
                           percentile_cont (0.5)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_bill_rate_50_pctl,
                           percentile_cont (0.5)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_pay_rate_50_pctl,
                           percentile_cont (0.75)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                          w.std_job_category_id)    reg_bill_rate_75_pctl,
                           percentile_cont (0.75)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                          w.std_job_category_id)    reg_pay_rate_75_pctl,
                           percentile_cont (0.9)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_bill_rate_90_pctl,
                           percentile_cont (0.9)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           rm.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_period_type  = 'Q' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYYQ'))
                                                                         WHEN iv_period_type  = 'Y' THEN
                                                                           to_number(to_char(to_date(w.month_number,'YYYYMM'),'YYYY'))
                                                                         ELSE
                                                                           w.month_number
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_pay_rate_90_pctl,
                           w.currency_description
                      FROM dm_weighted_rate_events w,
                           dm_region_place_map rm,
                           dm_regions          r
                     WHERE w.month_number between ln_start_month_number and ln_end_month_number
                       AND rm.std_place_id = w.std_place_id
                       AND rm.std_region_id = r.std_region_id
                       AND r.std_region_type_id = in_region_type
                   ) a
             GROUP
                BY iv_geographic_level,
                   iv_new_assign_flag,
                   a.std_region_id,
                   a.cmsa_code,
                   a.period_number,
                   iv_period_type,
                   a.std_job_title_id,
                   a.std_job_category_id,
                   a.reg_bill_rate_10_pctl,
                   a.reg_pay_rate_10_pctl,
                   a.reg_bill_rate_25_pctl,
                   a.reg_pay_rate_25_pctl,
                   a.reg_bill_rate_50_pctl,
                   a.reg_pay_rate_50_pctl,
                   a.reg_bill_rate_75_pctl,
                   a.reg_pay_rate_75_pctl,
                   a.reg_bill_rate_90_pctl,
                   a.reg_pay_rate_90_pctl,
                   a.currency_description,
                   in_msg_id,
                   ld_date;
           ELSE
            --
            -- New assignmnts hot spots ( Run only for monthly)
            --
            INSERT
              INTO dm_geographic_rates_summary_t
                   (geographic_level,
                    new_assignment_flag,
                    std_region_id,
                    cmsa_code,
                    period_number,
                    period_type,
                    std_job_title_id,
                    std_job_category_id,
                    assignment_count,
                    assignment_data_points,
                    assignment_activity_count,
                    avg_reg_bill_rate,
                    avg_reg_pay_rate,
                    reg_bill_rate_10_pctl,
                    reg_pay_rate_10_pctl,
                    reg_bill_rate_25_pctl,
                    reg_pay_rate_25_pctl,
                    reg_bill_rate_50_pctl,
                    reg_pay_rate_50_pctl,
                    reg_bill_rate_75_pctl,
                    reg_pay_rate_75_pctl,
                    reg_bill_rate_90_pctl,
                    reg_pay_rate_90_pctl,
                    currency_description,
                    load_key,
                    last_update_date
                   )
            SELECT iv_geographic_level,
                   iv_new_assign_flag,
                   a.std_region_id,
                   a.cmsa_code,
                   a.period_number,
                   iv_period_type,
                   a.std_job_title_id,
                   a.std_job_category_id,
                   count(distinct a.assignment_count)                                assignment_count,
                   count(distinct a.assignment_data_points)                          assignment_data_points,
                   count(distinct a.assignment_activity_count)                       assignment_activity_count,
                   (sum(a.reg_bill_rate)/count(distinct a.assignment_data_points))   avg_reg_bill_rate,
                   (sum(a.reg_pay_rate)/count(distinct a.assignment_data_points))    avg_reg_pay_rate,
                   a.reg_bill_rate_10_pctl,
                   a.reg_pay_rate_10_pctl,
                   a.reg_bill_rate_25_pctl,
                   a.reg_pay_rate_25_pctl,
                   a.reg_bill_rate_50_pctl,
                   a.reg_pay_rate_50_pctl,
                   a.reg_bill_rate_75_pctl,
                   a.reg_pay_rate_75_pctl,
                   a.reg_bill_rate_90_pctl,
                   a.reg_pay_rate_90_pctl,
                   a.currency_description,
                   in_msg_id,
                   ld_date
              FROM
                   (
                    SELECT CASE
                           WHEN iv_geographic_level IN ('N','JCN') THEN -- national or job category level
                            ln_region_id
                           ELSE
                            w.std_region_id
                           END                                                                     std_region_id,
                           CASE
                           WHEN iv_geographic_level IN ('C','JCC') THEN -- cmsa level
                            w.cmsa_code
                           ELSE
                            lv_cmsa_code
                           END                                                                     cmsa_code,
                           w.month_number                                                          period_number,
                           CASE
                           WHEN iv_geographic_level like 'JC%' THEN --job category level
                            ln_job_title_id
                           ELSE
                            w.std_job_title_id
                           END                                                                     std_job_title_id,
                           w.std_job_category_id,
                           w.reg_bill_rate                                                         reg_bill_rate,
                           w.reg_pay_rate                                                          reg_pay_rate,
                           w.data_source_code||w.assignment_id                                     assignment_count,
                           w.data_source_code||w.assignment_id||w.assignment_seq_number||w.month_number   assignment_data_points,
                           w.data_source_code||w.assignment_id||w.reg_bill_rate                    assignment_activity_count,
                           percentile_cont (0.1)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_bill_rate_10_pctl,
                           percentile_cont (0.1)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_pay_rate_10_pctl,
                           percentile_cont (0.25)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                          w.std_job_category_id)    reg_bill_rate_25_pctl,
                           percentile_cont (0.25)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                          w.std_job_category_id)    reg_pay_rate_25_pctl,
                           percentile_cont (0.5)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_bill_rate_50_pctl,
                           percentile_cont (0.5)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_pay_rate_50_pctl,
                           percentile_cont (0.75)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC')  THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                          w.std_job_category_id)    reg_bill_rate_75_pctl,
                           percentile_cont (0.75)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                          w.std_job_category_id)    reg_pay_rate_75_pctl,
                           percentile_cont (0.9)within group (order by w.reg_bill_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN')  THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_bill_rate_90_pctl,
                           percentile_cont (0.9)within group (order by w.reg_pay_rate)
                                                       over(partition by CASE
                                                                         WHEN iv_geographic_level IN ('N','JCN') THEN
                                                                          ln_region_id
                                                                         ELSE
                                                                           w.std_region_id
                                                                         END,
                                                                         CASE
                                                                         WHEN iv_geographic_level IN ('C','JCC') THEN
                                                                           w.cmsa_code
                                                                         ELSE
                                                                           lv_cmsa_code
                                                                         END,
                                                                         w.month_number,
                                                                         CASE
                                                                         WHEN iv_geographic_level like 'JC%' THEN
                                                                           ln_job_title_id
                                                                         ELSE
                                                                           w.std_job_title_id
                                                                         END,
                                                                         w.std_job_category_id)    reg_pay_rate_90_pctl,
                           w.currency_description
                      FROM  (WITH initial_assign_list AS
                                   (SELECT assignment_id,data_source_code,min(month_number) first_month_number
                                      FROM dm_weighted_rate_events
                                     WHERE month_number between ln_start_month_number and ln_end_month_number
                                     GROUP
                                        BY assignment_id,data_source_code)
                             SELECT rm.std_region_id,wr.cmsa_code,wr.month_number,wr.assignment_seq_number,
                                    wr.std_job_title_id,wr.std_job_category_id,wr.reg_bill_rate,wr.reg_pay_rate,
                                    wr.data_source_code,wr.assignment_id,wr.currency_description
                               FROM dm_weighted_rate_events wr,
                                    dm_region_place_map rm,
                                    dm_regions          r,
                                    initial_assign_list ia
                              WHERE wr.month_number between ln_start_month_number and ln_end_month_number
                                AND rm.std_place_id       = wr.std_place_id
                                AND rm.std_region_id = r.std_region_id
                                AND r.std_region_type_id = in_region_type
                                AND ia.assignment_id      = wr.assignment_id
                                AND ia.data_source_code   = wr.data_source_code
                                AND ia.first_month_number = wr.month_number) w
                   ) a
             GROUP
                BY iv_geographic_level,
                   iv_new_assign_flag,
                   a.std_region_id,
                   a.cmsa_code,
                   a.period_number,
                   iv_period_type,
                   a.std_job_title_id,
                   a.std_job_category_id,
                   a.reg_bill_rate_10_pctl,
                   a.reg_pay_rate_10_pctl,
                   a.reg_bill_rate_25_pctl,
                   a.reg_pay_rate_25_pctl,
                   a.reg_bill_rate_50_pctl,
                   a.reg_pay_rate_50_pctl,
                   a.reg_bill_rate_75_pctl,
                   a.reg_pay_rate_75_pctl,
                   a.reg_bill_rate_90_pctl,
                   a.reg_pay_rate_90_pctl,
                   a.currency_description,
                   in_msg_id,
                   ld_date;

           END IF;
         EXCEPTION
           WHEN OTHERS THEN
             lv_db_err_msg  := SQLERRM;
             lv_app_err_msg := 'Unable to insert the' ||iv_period_type|| '-'|| to_char(id_run_date,'DD-MON-YYYY') ||' for Level '||iv_geographic_level||' (Assignment Flag = '||iv_new_assign_flag||'!';
             RAISE le_exception;
         END;

  EXCEPTION
    WHEN le_exception THEN
      --
      -- user defined exception, Log and raise the application error.
      --
      on_err_num := DM_UTIL_LOG.f_log_error(in_msg_id,
                                            lv_app_err_msg,
                                            lv_db_err_msg,
                                            lv_proc_name);

      ov_err_msg := lv_app_err_msg;
    WHEN OTHERS THEN
      --
      -- Unknown exception, Log and raise the application error.
      --
      Rollback;
      lv_app_err_msg := 'Unknown Error !';
      lv_db_err_msg  := SQLERRM;
      on_err_num     := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                lv_app_err_msg,
                                                lv_db_err_msg,
                                                lv_proc_name);
      ov_err_msg     := lv_app_err_msg;
  END p_rate_process;

  PROCEDURE p_main(id_run_date      IN DATE DEFAULT (SYSDATE-1),id_start_date IN DATE DEFAULT '01-JAN-2008' )
  IS
     ln_msg_id             NUMBER;
     ln_count              NUMBER;
     ln_err_num            NUMBER;
     ln_sub_seq_no         NUMBER;
     ld_run_date           DATE;
     lv_err_msg            VARCHAR2(4000)  := NULL;
     lv_period_type        VARCHAR2(3);
     gv_process            VARCHAR2(30) := 'DM_GEOGRAPHIC_RATE_PROCESS';
     gv_proc_name          user_jobs.what%TYPE := 'DM_GEOGRAPHIC_RATE_PROCESS.P_MAIN';
     gv_app_err_msg        VARCHAR2(2000)  := NULL;
     gv_db_err_msg         VARCHAR2(2000)  := NULL;
     gv_err_msg            VARCHAR2(4000)  := NULL;
     ge_exception          EXCEPTION;
     email_sender          VARCHAR2(32) := 'mart_processing@iqnavigator.com';
     email_recipients      VARCHAR2(64) := 'pkattula@iqnavigator.com,mgopalkrishnan@iqnavigator.com';
     email_subject         VARCHAR2(64) := 'Regional Rate Process';
     CURSOR geolevel
     IS
     SELECT geo_level,region_type
       FROM ( SELECT 'N'  geo_level, 6 region_type from dual
              UNION ALL
              select distinct 'R'||std_region_type_id, std_region_type_id region_type from dm_regions where std_region_type_id <> 1
              UNION ALL
              SELECT 'C'  geo_level, 6 region_type  from dual
              UNION ALL
              SELECT 'JCN' geo_level, 6 region_type  from dual
              UNION ALL
              SELECT 'JCC' geo_level, 6 region_type  from dual
              UNION ALL
              select distinct 'JCR'||std_region_type_id, std_region_type_id region_type from dm_regions where std_region_type_id <> 1
            );
  BEGIN

 dm_cube_utils.make_indexes_visible;

     --
     -- Get the sequence reuired for logging messages
     --
     SELECT dm_msg_log_seq.NEXTVAL INTO ln_msg_id FROM dual;

     --
     -- Check if the previous job still running
     --
  /*   BEGIN
       SELECT count(*)
         INTO ln_count
         FROM user_jobs dj,
              dba_jobs_running djr
        WHERE dj.job      = djr.job
          AND dj.log_user = USER
          AND dj.what     = gv_proc_name;
     EXCEPTION
       WHEN OTHERS THEN
         --
         -- Unable to read user_jobs status log and exit
         --
         dm_util_log.p_log_msg(ln_msg_id,0, gv_process || ' - ERROR IN GETTING RUNNING JOB STATUS',gv_proc_name,'I');
         dm_util_log.p_log_msg(ln_msg_id,0,NULL,NULL,'U');
     END; */

ln_count := dm_cube_utils.get_job_status('DM_GEOGRAPHIC_RATE_PROCESS.P_MAIN;');

     IF ln_count > 0 THEN
         --
         -- previous job still running log and exit
         --
         dm_util_log.p_log_msg(ln_msg_id,0,gv_process|| ' - PREVIOUS JOB STILL RUNNING',gv_proc_name,'I');
         dm_util_log.p_log_msg(ln_msg_id,0,NULL,NULL,'U');
     ELSE

         --
         --Log initial load status
         --

         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'DW','STARTED',NULL,'I');

         --
         -- Truncate DM_GEOGRAPHIC_RATES_SUMMARY_T first
         --
         BEGIN
           EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_geographic_rates_summary_t';
         EXCEPTION
           WHEN OTHERS THEN
	    gv_app_err_msg := 'Errors occured in truncating the geographic rate summary temp table!';
	    gv_db_err_msg  := SQLERRM;
	    RAISE ge_exception;
         END;

         ln_sub_seq_no := 0;
         FOR c1 IN ( select range_month_end from (
                              select x.range_month_end
                 ,x.row_level
                 ,ROW_NUMBER() OVER  ( ORDER BY COUNT(*)) month_order
             from (select level row_level
                         ,TRUNC(ADD_MONTHS(id_start_date, +(level-1)), 'MONTH')+1 range_month_end
                     from dual
                  connect by level < (months_between(TRUNC(id_run_date,'MM'),id_start_date) + 2)
                    order by level asc) x
            group by x.range_month_end
                    , x.row_level
                 order by x.row_level asc))
         LOOP
           --
           -- Run monthly for the various Geographic levels
           --
           FOR geolevel_rec IN geolevel
           LOOP
             ln_sub_seq_no := ln_sub_seq_no +1;
             dm_util_log.p_log_msg(ln_msg_id,ln_sub_seq_no, 'Insert into Geographic rate summary for level '||geolevel_rec.geo_level||' for the month '||to_char(c1.range_month_end,'YYYYMM'),gv_proc_name,'I');

             p_rate_process(c1.range_month_end,
	                     'M',
	                     geolevel_rec.geo_level,
	                     geolevel_rec.region_type,
	                     'N',
	                     ln_msg_id,
	                     id_run_date,
	                     ln_err_num,
                             lv_err_msg);


             --
	     --  check for any errors returned after executing the procedure
	     --
	     IF ln_err_num > 0 THEN
	        gv_app_err_msg := 'Errors occured in the procedure to process Geographic rate summary for level '||geolevel_rec.geo_level||' for the month '||to_char(c1.range_month_end,'YYYYMM');
	        gv_db_err_msg  := lv_err_msg||' '||SQLERRM;
	        RAISE ge_exception;
             END IF;

             dm_util_log.p_log_msg(ln_msg_id,ln_sub_seq_no, NULL,NULL,'U');

             --
             -- Monthly Hot spots for new assignments ( this section is only run for monthly)
             --

             ln_sub_seq_no := ln_sub_seq_no +1;
             dm_util_log.p_log_msg(ln_msg_id,ln_sub_seq_no, 'Insert into Geographic rate summary for level '||geolevel_rec.geo_level||' for the month '||to_char(c1.range_month_end,'YYYYMM')||' New Assignment hot spots',gv_proc_name,'I');

             p_rate_process(c1.range_month_end,
	                     'M',
	                     geolevel_rec.geo_level,
	                     geolevel_rec.region_type,
	                     'Y',                           -- New assignment hot spot flag
	                     ln_msg_id,
	                     id_run_date,
	                     ln_err_num,
                             lv_err_msg);


             --
	     --  check for any errors returned after executing the procedure
	     --
	     IF ln_err_num > 0 THEN
	        gv_app_err_msg := 'Errors occured in the procedure to process Geographic rate summary for level '||geolevel_rec.geo_level||' for the month '||to_char(c1.range_month_end,'YYYYMM')||' New Assignment hot spots!';
	        gv_db_err_msg  := lv_err_msg||' '||SQLERRM;
	        RAISE ge_exception;
             END IF;

             dm_util_log.p_log_msg(ln_msg_id,ln_sub_seq_no, NULL,NULL,'U');


           END LOOP;

         --
         -- Run Quarterly if the month is 03,06,09 or 12
         --
         IF to_char(c1.range_month_end,'MM') IN ('03','06','09','12') THEN
            --
            -- Run the Quarter for the various Geographic levels
            --
            FOR geolevel_rec IN geolevel
            LOOP
             ln_sub_seq_no := ln_sub_seq_no +1;
             dm_util_log.p_log_msg(ln_msg_id,ln_sub_seq_no, 'Insert into Geographic rate summary for level '||geolevel_rec.geo_level||' for the Quarter'||to_char(c1.range_month_end,'YYYYQ'),gv_proc_name,'I');

             p_rate_process(c1.range_month_end,
	    	             'Q',
	    	             geolevel_rec.geo_level,
	    	             geolevel_rec.region_type,
	    	             'N',
	    	             ln_msg_id,
	    	             id_run_date,
	    	             ln_err_num,
                             lv_err_msg);


             --
	     --  check for any errors returned after executing the procedure
	     --
	     IF ln_err_num > 0 THEN
	        gv_app_err_msg := 'Errors occured in the procedure to process Geographic rate summary for level '||geolevel_rec.geo_level||' for the Quarter'||to_char(c1.range_month_end,'YYYYQ');
	        gv_db_err_msg  := lv_err_msg||' '||SQLERRM;
	       RAISE ge_exception;
             END IF;

             dm_util_log.p_log_msg(ln_msg_id,ln_sub_seq_no, NULL,NULL,'U');
            END LOOP;
         END IF;

         END LOOP;

         --
         -- Run Yearly or YTDs second
         --
         FOR c1 IN ( select DISTINCT TRUNC(range_month_end,'YYYY') range_month_end from (
                              select x.range_month_end
                 ,x.row_level
                 ,ROW_NUMBER() OVER  ( ORDER BY COUNT(*)) month_order
             from (select level row_level
                         ,TRUNC(ADD_MONTHS(id_start_date, +(level-1)), 'MONTH')+1 range_month_end
                     from dual
                  connect by level < (months_between(TRUNC(id_run_date,'MM'),id_start_date) + 2)
                    order by level asc) x
            group by x.range_month_end
                    , x.row_level
                 order by x.row_level asc))
         LOOP
            --
            -- Run the year/ytd for various geographic levels
            --
            FOR geolevel_rec IN geolevel
            LOOP
             ln_sub_seq_no := ln_sub_seq_no +1;
             dm_util_log.p_log_msg(ln_msg_id,ln_sub_seq_no, 'Insert into Geographic rate summary for level '||geolevel_rec.geo_level||' for the Year/YTD'||to_char(c1.range_month_end,'YYYY'),gv_proc_name,'I');

             p_rate_process(c1.range_month_end,
	 	    	     'Y',
	 	    	     geolevel_rec.geo_level,
	 	    	     geolevel_rec.region_type,
	 	    	     'N',
	 	    	     ln_msg_id,
	 	    	     id_run_date,
	 	    	     ln_err_num,
                             lv_err_msg);
             --
	     --  check for any errors returned after executing the procedure
	     --
	     IF ln_err_num > 0 THEN
	        gv_app_err_msg := 'Errors occured in the procedure to process Geographic rate summary for level '||geolevel_rec.geo_level||' for the Year/YTD'||to_char(c1.range_month_end,'YYYY');
	        gv_db_err_msg  := lv_err_msg||' '||SQLERRM;
	        RAISE ge_exception;
             END IF;

             dm_util_log.p_log_msg(ln_msg_id,ln_sub_seq_no, NULL,NULL,'U');
           END LOOP;

         END LOOP;

         Commit;

         --
         -- Truncate the main table DM_GEOGRAPHIC_RATES_SUMMARY
         --
         BEGIN
           EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_geographic_rates_summary';
         EXCEPTION
           WHEN OTHERS THEN
	    gv_app_err_msg := 'Errors occured in truncating the geographic rate summary table!';
	    gv_db_err_msg  := SQLERRM;
	    RAISE ge_exception;
         END;

         --
         -- Insert into the main table from the temp table
         --
         BEGIN
         INSERT
           INTO dm_geographic_rates_summary
         SELECT *
           FROM dm_geographic_rates_summary_t;
         EXCEPTION
           WHEN OTHERS THEN
	    gv_app_err_msg := 'Errors occured in inserting into the geographic rate summary table from temp table!';
	    gv_db_err_msg  := SQLERRM;
	    RAISE ge_exception;
         END;
         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'DW','COMPLETE',0,'U');


     END IF;
  EXCEPTION
     WHEN ge_exception THEN
          Rollback;
          DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'DM_REGIONAL_RATE_PROCESS-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
          DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
          ln_err_num  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                 gv_app_err_msg ,
                                                 gv_db_err_msg,
                                                 gv_proc_name);
          DM_UTIL_LOG.p_log_load_status(ln_msg_id, gv_process,'DW','FAILED',0,'U');
         -- SEND_EMAIL(email_sender, email_recipients, email_subject, ' Process failed due to the following ' || c_crlf || gv_app_err_msg || c_crlf || gv_db_err_msg || c_crlf);
     WHEN OTHERS THEN
          Rollback;
          gv_db_err_msg := SQLERRM;
          gv_app_err_msg := 'Unable to insert the data!';
          DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'DM_REGIONAL_RATE_PROCESS-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
          DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
          ln_err_num  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                 gv_app_err_msg ,
                                                 gv_db_err_msg,
                                                 gv_proc_name);
          DM_UTIL_LOG.p_log_load_status(ln_msg_id, gv_process,'DW','FAILED',0,'U');
          --SEND_EMAIL(email_sender, email_recipients, email_subject, ' Process failed due to the following ' || c_crlf || gv_app_err_msg || c_crlf || gv_db_err_msg || c_crlf);
  END p_main;

END dm_geographic_rate_process;
/