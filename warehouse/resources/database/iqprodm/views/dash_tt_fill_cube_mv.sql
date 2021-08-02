DROP MATERIALIZED VIEW DASH_TT_FILL_CUBE_MV;

CREATE MATERIALIZED VIEW DASH_TT_FILL_CUBE_MV
TABLESPACE MART_USERS50M
LOGGING
BUILD IMMEDIATE
USING INDEX TABLESPACE MART_USERS50M
REFRESH FORCE ON DEMAND
WITH PRIMARY KEY
ENABLE QUERY REWRITE
AS 
select /*+ FULL(f) FULL(b) FULL(s) FULL(d) FULL(d1) FULL(d2) FULL(d3) FULL(d4) FULL(d5) FULL(d6) FULL(d7) FULL(d8) FULL(d9) FULL(d10) FULL(d11) PARALLEL(f,8) */ 
       NVL(b.ORG_ID,-1)                                              buyer_org_id,
       NVL(b.ORG_NAME,'NONE')                                        buyer_org_name,
       NVL(s.ORG_ID ,-1)                                             supplier_org_id,
       NVL(s.ORG_NAME,'NONE')                                        supplier_org_name,
       NVL(d.year_id_disp,'NONE')                                    time_period_cal_yr,
       NVL(NVL(d.fiscal_year_id_disp,d.year_id_disp),'NONE')         time_period_fis_yr,
       CASE
          WHEN d.quarter_name IS NOT NULL AND d.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         time_period_cal_qtr,
       CASE
          WHEN NVL(d.fiscal_quarter_name,d.quarter_name) IS NOT NULL AND NVL(d.fiscal_year_id_disp,d.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   time_period_fis_qtr,
       CASE
           WHEN d.month_name IS NOT NULL AND d.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d.month_name), 1, 3) || '-' || d.year_id_disp
           ELSE
                'NONE'
           END                                                  time_period_cal_mon,
       CASE
           WHEN NVL(d.fiscal_month_name,d.month_name) IS NOT NULL AND NVL(d.fiscal_year_id_disp,d.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d.fiscal_month_name,d.month_name)), 1, 3) || '-' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
           ELSE
                'NONE'
        END                                                     time_period_fis_mon,
         NVL(d1.year_id_disp,'NONE')                                    job_approval_cal_yr,
       NVL(NVL(d1.fiscal_year_id_disp,d1.year_id_disp),'NONE')         job_approval_fis_yr,
       CASE
          WHEN d1.quarter_name IS NOT NULL AND d1.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d1.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d1.year_id_disp
              WHEN UPPER(d1.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d1.year_id_disp
              WHEN UPPER(d1.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d1.year_id_disp
              WHEN UPPER(d1.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d1.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         job_approval_cal_qtr,
       CASE
          WHEN NVL(d1.fiscal_quarter_name,d1.quarter_name) IS NOT NULL AND NVL(d1.fiscal_year_id_disp,d1.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d1.fiscal_quarter_name,d1.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d1.fiscal_year_id_disp,d1.year_id_disp)
              WHEN UPPER(NVL(d1.fiscal_quarter_name,d1.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d1.fiscal_year_id_disp,d1.year_id_disp)
              WHEN UPPER(NVL(d1.fiscal_quarter_name,d1.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d1.fiscal_year_id_disp,d1.year_id_disp)
              WHEN UPPER(NVL(d1.fiscal_quarter_name,d1.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d1.fiscal_year_id_disp,d1.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   job_approval_fis_qtr,
       CASE
           WHEN d1.month_name IS NOT NULL AND d1.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d1.month_name), 1, 3) || '-' || d1.year_id_disp
           ELSE
                'NONE'
           END                                                  job_approval_cal_mon,
       CASE
           WHEN NVL(d1.fiscal_month_name,d1.month_name) IS NOT NULL AND NVL(d1.fiscal_year_id_disp,d1.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d1.fiscal_month_name,d1.month_name)), 1, 3) || '-' || NVL(d1.fiscal_year_id_disp,d1.year_id_disp)
           ELSE
                'NONE'
        END                                                     job_approval_fis_mon,
           NVL(d2.year_id_disp,'NONE')                                    job_create_cal_yr,
       NVL(NVL(d2.fiscal_year_id_disp,d2.year_id_disp),'NONE')         job_create_fis_yr,
       CASE
          WHEN d2.quarter_name IS NOT NULL AND d2.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d2.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d2.year_id_disp
              WHEN UPPER(d2.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d2.year_id_disp
              WHEN UPPER(d2.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d2.year_id_disp
              WHEN UPPER(d2.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d2.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         job_create_cal_qtr,
       CASE
          WHEN NVL(d2.fiscal_quarter_name,d2.quarter_name) IS NOT NULL AND NVL(d2.fiscal_year_id_disp,d2.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d2.fiscal_quarter_name,d2.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d2.fiscal_year_id_disp,d2.year_id_disp)
              WHEN UPPER(NVL(d2.fiscal_quarter_name,d2.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d2.fiscal_year_id_disp,d2.year_id_disp)
              WHEN UPPER(NVL(d2.fiscal_quarter_name,d2.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d2.fiscal_year_id_disp,d2.year_id_disp)
              WHEN UPPER(NVL(d2.fiscal_quarter_name,d2.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d2.fiscal_year_id_disp,d2.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   job_create_fis_qtr,
       CASE
           WHEN d2.month_name IS NOT NULL AND d2.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d2.month_name), 1, 3) || '-' || d2.year_id_disp
           ELSE
                'NONE'
           END                                                  job_create_cal_mon,
       CASE
           WHEN NVL(d2.fiscal_month_name,d2.month_name) IS NOT NULL AND NVL(d2.fiscal_year_id_disp,d2.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d2.fiscal_month_name,d2.month_name)), 1, 3) || '-' || NVL(d2.fiscal_year_id_disp,d2.year_id_disp)
           ELSE
                'NONE'
        END                                                     job_create_fis_mon,
           NVL(d3.year_id_disp,'NONE')                                    job_release_supp_cal_yr,
       NVL(NVL(d3.fiscal_year_id_disp,d3.year_id_disp),'NONE')         job_release_supp_fis_yr,
       CASE
          WHEN d3.quarter_name IS NOT NULL AND d3.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d3.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d3.year_id_disp
              WHEN UPPER(d3.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d3.year_id_disp
              WHEN UPPER(d3.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d3.year_id_disp
              WHEN UPPER(d3.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d3.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         job_release_to_supp_cal_qtr,
       CASE
          WHEN NVL(d3.fiscal_quarter_name,d3.quarter_name) IS NOT NULL AND NVL(d3.fiscal_year_id_disp,d3.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d3.fiscal_quarter_name,d3.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d3.fiscal_year_id_disp,d3.year_id_disp)
              WHEN UPPER(NVL(d3.fiscal_quarter_name,d3.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d3.fiscal_year_id_disp,d3.year_id_disp)
              WHEN UPPER(NVL(d3.fiscal_quarter_name,d3.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d3.fiscal_year_id_disp,d3.year_id_disp)
              WHEN UPPER(NVL(d3.fiscal_quarter_name,d3.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d3.fiscal_year_id_disp,d3.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   job_release_to_supp_fis_qtr,
       CASE
           WHEN d3.month_name IS NOT NULL AND d3.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d3.month_name), 1, 3) || '-' || d3.year_id_disp
           ELSE
                'NONE'
           END                                                  job_release_to_supp_cal_mon,
       CASE
           WHEN NVL(d3.fiscal_month_name,d3.month_name) IS NOT NULL AND NVL(d3.fiscal_year_id_disp,d3.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d3.fiscal_month_name,d3.month_name)), 1, 3) || '-' || NVL(d3.fiscal_year_id_disp,d3.year_id_disp)
           ELSE
                'NONE'
        END                                                     job_release_to_supp_fis_mon,
           NVL(d4.year_id_disp,'NONE')                                    match_submitted_cal_yr,
       NVL(NVL(d4.fiscal_year_id_disp,d4.year_id_disp),'NONE')         match_submitted_fis_yr,
       CASE
          WHEN d4.quarter_name IS NOT NULL AND d4.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d4.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d4.year_id_disp
              WHEN UPPER(d4.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d4.year_id_disp
              WHEN UPPER(d4.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d4.year_id_disp
              WHEN UPPER(d4.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d4.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         match_submitted_cal_qtr,
       CASE
          WHEN NVL(d4.fiscal_quarter_name,d4.quarter_name) IS NOT NULL AND NVL(d4.fiscal_year_id_disp,d4.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d4.fiscal_quarter_name,d4.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d4.fiscal_year_id_disp,d4.year_id_disp)
              WHEN UPPER(NVL(d4.fiscal_quarter_name,d4.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d4.fiscal_year_id_disp,d4.year_id_disp)
              WHEN UPPER(NVL(d4.fiscal_quarter_name,d4.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d4.fiscal_year_id_disp,d4.year_id_disp)
              WHEN UPPER(NVL(d4.fiscal_quarter_name,d4.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d4.fiscal_year_id_disp,d4.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   match_submitted_fis_qtr,
       CASE
           WHEN d4.month_name IS NOT NULL AND d4.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d4.month_name), 1, 3) || '-' || d4.year_id_disp
           ELSE
                'NONE'
           END                                                  match_submitted_cal_mon,
       CASE
           WHEN NVL(d4.fiscal_month_name,d4.month_name) IS NOT NULL AND NVL(d4.fiscal_year_id_disp,d4.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d4.fiscal_month_name,d4.month_name)), 1, 3) || '-' || NVL(d4.fiscal_year_id_disp,d4.year_id_disp)
           ELSE
                'NONE'
        END                                                     match_submitted_fis_mon,
           NVL(d5.year_id_disp,'NONE')                                    fwd_to_hm_cal_yr,
       NVL(NVL(d5.fiscal_year_id_disp,d5.year_id_disp),'NONE')         fwd_to_hm_fis_yr,
       CASE
          WHEN d5.quarter_name IS NOT NULL AND d5.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d5.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d5.year_id_disp
              WHEN UPPER(d5.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d5.year_id_disp
              WHEN UPPER(d5.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d5.year_id_disp
              WHEN UPPER(d5.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d5.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         fwd_to_hm_cal_qtr,
       CASE
          WHEN NVL(d5.fiscal_quarter_name,d5.quarter_name) IS NOT NULL AND NVL(d5.fiscal_year_id_disp,d5.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d5.fiscal_quarter_name,d5.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d5.fiscal_year_id_disp,d5.year_id_disp)
              WHEN UPPER(NVL(d5.fiscal_quarter_name,d5.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d5.fiscal_year_id_disp,d5.year_id_disp)
              WHEN UPPER(NVL(d5.fiscal_quarter_name,d5.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d5.fiscal_year_id_disp,d5.year_id_disp)
              WHEN UPPER(NVL(d5.fiscal_quarter_name,d5.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d5.fiscal_year_id_disp,d5.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   fwd_to_hm_fis_qtr,
       CASE
           WHEN d5.month_name IS NOT NULL AND d5.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d5.month_name), 1, 3) || '-' || d5.year_id_disp
           ELSE
                'NONE'
           END                                                  fwd_to_hm_cal_mon,
       CASE
           WHEN NVL(d5.fiscal_month_name,d5.month_name) IS NOT NULL AND NVL(d5.fiscal_year_id_disp,d5.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d5.fiscal_month_name,d5.month_name)), 1, 3) || '-' || NVL(d5.fiscal_year_id_disp,d5.year_id_disp)
           ELSE
                'NONE'
        END                                                     fwd_to_hm_fis_mon,
           NVL(d6.year_id_disp,'NONE')                                    interview_sched_cal_yr,
       NVL(NVL(d6.fiscal_year_id_disp,d6.year_id_disp),'NONE')         interview_sched_fis_yr,
       CASE
          WHEN d6.quarter_name IS NOT NULL AND d6.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d6.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d6.year_id_disp
              WHEN UPPER(d6.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d6.year_id_disp
              WHEN UPPER(d6.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d6.year_id_disp
              WHEN UPPER(d6.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d6.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         inter_sched_cal_qtr,
       CASE
          WHEN NVL(d6.fiscal_quarter_name,d6.quarter_name) IS NOT NULL AND NVL(d6.fiscal_year_id_disp,d6.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d6.fiscal_quarter_name,d6.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d6.fiscal_year_id_disp,d6.year_id_disp)
              WHEN UPPER(NVL(d6.fiscal_quarter_name,d6.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d6.fiscal_year_id_disp,d6.year_id_disp)
              WHEN UPPER(NVL(d6.fiscal_quarter_name,d6.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d6.fiscal_year_id_disp,d6.year_id_disp)
              WHEN UPPER(NVL(d6.fiscal_quarter_name,d6.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d6.fiscal_year_id_disp,d6.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   inter_sched_fis_qtr,
       CASE
           WHEN d6.month_name IS NOT NULL AND d6.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d6.month_name), 1, 3) || '-' || d6.year_id_disp
           ELSE
                'NONE'
           END                                                  inter_sched_cal_mon,
       CASE
           WHEN NVL(d6.fiscal_month_name,d6.month_name) IS NOT NULL AND NVL(d6.fiscal_year_id_disp,d6.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d6.fiscal_month_name,d6.month_name)), 1, 3) || '-' || NVL(d6.fiscal_year_id_disp,d6.year_id_disp)
           ELSE
                'NONE'
        END                                                     inter_sched_fis_mon,
           NVL(d7.year_id_disp,'NONE')                                    wo_rel_supp_cal_yr,
       NVL(NVL(d7.fiscal_year_id_disp,d7.year_id_disp),'NONE')         wo_rel_supp_fis_yr,
       CASE
          WHEN d7.quarter_name IS NOT NULL AND d7.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d7.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d7.year_id_disp
              WHEN UPPER(d7.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d7.year_id_disp
              WHEN UPPER(d7.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d7.year_id_disp
              WHEN UPPER(d7.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d7.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         wo_rel_supp_cal_qtr,
       CASE
          WHEN NVL(d7.fiscal_quarter_name,d7.quarter_name) IS NOT NULL AND NVL(d7.fiscal_year_id_disp,d7.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d7.fiscal_quarter_name,d7.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d7.fiscal_year_id_disp,d7.year_id_disp)
              WHEN UPPER(NVL(d7.fiscal_quarter_name,d7.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d7.fiscal_year_id_disp,d7.year_id_disp)
              WHEN UPPER(NVL(d7.fiscal_quarter_name,d7.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d7.fiscal_year_id_disp,d7.year_id_disp)
              WHEN UPPER(NVL(d7.fiscal_quarter_name,d7.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d7.fiscal_year_id_disp,d7.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   wo_rel_supp_fis_qtr,
       CASE
           WHEN d7.month_name IS NOT NULL AND d7.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d7.month_name), 1, 3) || '-' || d7.year_id_disp
           ELSE
                'NONE'
           END                                                  wo_rel_supp_cal_mon,
       CASE
           WHEN NVL(d7.fiscal_month_name,d7.month_name) IS NOT NULL AND NVL(d7.fiscal_year_id_disp,d7.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d7.fiscal_month_name,d7.month_name)), 1, 3) || '-' || NVL(d7.fiscal_year_id_disp,d7.year_id_disp)
           ELSE
                'NONE'
        END                                                     wo_rel_supp_fis_mon,
           NVL(d8.year_id_disp,'NONE')                                    wo_accept_supp_cal_yr,
       NVL(NVL(d8.fiscal_year_id_disp,d8.year_id_disp),'NONE')         wo_accept_supp_fis_yr,
       CASE
          WHEN d8.quarter_name IS NOT NULL AND d8.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d8.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d8.year_id_disp
              WHEN UPPER(d8.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d8.year_id_disp
              WHEN UPPER(d8.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d8.year_id_disp
              WHEN UPPER(d8.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d8.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         wo_accept_supp_cal_qtr,
       CASE
          WHEN NVL(d8.fiscal_quarter_name,d8.quarter_name) IS NOT NULL AND NVL(d8.fiscal_year_id_disp,d8.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d8.fiscal_quarter_name,d8.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d8.fiscal_year_id_disp,d8.year_id_disp)
              WHEN UPPER(NVL(d8.fiscal_quarter_name,d8.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d8.fiscal_year_id_disp,d8.year_id_disp)
              WHEN UPPER(NVL(d8.fiscal_quarter_name,d8.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d8.fiscal_year_id_disp,d8.year_id_disp)
              WHEN UPPER(NVL(d8.fiscal_quarter_name,d8.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d8.fiscal_year_id_disp,d8.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   wo_accept_supp_fis_qtr,
       CASE
           WHEN d8.month_name IS NOT NULL AND d8.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d8.month_name), 1, 3) || '-' || d8.year_id_disp
           ELSE
                'NONE'
           END                                                  wo_accept_supp_cal_mon,
       CASE
           WHEN NVL(d8.fiscal_month_name,d8.month_name) IS NOT NULL AND NVL(d8.fiscal_year_id_disp,d8.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d8.fiscal_month_name,d8.month_name)), 1, 3) || '-' || NVL(d8.fiscal_year_id_disp,d8.year_id_disp)
           ELSE
                'NONE'
        END                                                     wo_accept_supp_fis_mon,
           NVL(d9.year_id_disp,'NONE')                                    assignment_created_cal_yr,
       NVL(NVL(d9.fiscal_year_id_disp,d9.year_id_disp),'NONE')         assignment_created_fis_yr,
       CASE
          WHEN d9.quarter_name IS NOT NULL AND d9.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d9.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d9.year_id_disp
              WHEN UPPER(d9.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d9.year_id_disp
              WHEN UPPER(d9.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d9.year_id_disp
              WHEN UPPER(d9.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d9.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         assignment_created_cal_qtr,
       CASE
          WHEN NVL(d9.fiscal_quarter_name,d9.quarter_name) IS NOT NULL AND NVL(d9.fiscal_year_id_disp,d9.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d9.fiscal_quarter_name,d9.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d9.fiscal_year_id_disp,d9.year_id_disp)
              WHEN UPPER(NVL(d9.fiscal_quarter_name,d9.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d9.fiscal_year_id_disp,d9.year_id_disp)
              WHEN UPPER(NVL(d9.fiscal_quarter_name,d9.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d9.fiscal_year_id_disp,d9.year_id_disp)
              WHEN UPPER(NVL(d9.fiscal_quarter_name,d9.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d9.fiscal_year_id_disp,d9.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   assignment_created_fis_qtr,
       CASE
           WHEN d9.month_name IS NOT NULL AND d9.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d9.month_name), 1, 3) || '-' || d9.year_id_disp
           ELSE
                'NONE'
           END                                                  assignment_created_cal_mon,
       CASE
           WHEN NVL(d9.fiscal_month_name,d9.month_name) IS NOT NULL AND NVL(d9.fiscal_year_id_disp,d9.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d9.fiscal_month_name,d9.month_name)), 1, 3) || '-' || NVL(d9.fiscal_year_id_disp,d9.year_id_disp)
           ELSE
                'NONE'
        END                                                     assignment_created_fis_mon,
           NVL(d10.year_id_disp,'NONE')                                    assignment_started_cal_yr,
       NVL(NVL(d10.fiscal_year_id_disp,d10.year_id_disp),'NONE')         assignment_started_fis_yr,
       CASE
          WHEN d10.quarter_name IS NOT NULL AND d10.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d10.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d10.year_id_disp
              WHEN UPPER(d10.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d10.year_id_disp
              WHEN UPPER(d10.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d10.year_id_disp
              WHEN UPPER(d10.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d10.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         assignment_started_cal_qtr,
       CASE
          WHEN NVL(d10.fiscal_quarter_name,d10.quarter_name) IS NOT NULL AND NVL(d10.fiscal_year_id_disp,d10.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d10.fiscal_quarter_name,d10.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d10.fiscal_year_id_disp,d10.year_id_disp)
              WHEN UPPER(NVL(d10.fiscal_quarter_name,d10.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d10.fiscal_year_id_disp,d10.year_id_disp)
              WHEN UPPER(NVL(d10.fiscal_quarter_name,d10.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d10.fiscal_year_id_disp,d10.year_id_disp)
              WHEN UPPER(NVL(d10.fiscal_quarter_name,d10.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d10.fiscal_year_id_disp,d10.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   assignment_started_fis_qtr,
       CASE
           WHEN d10.month_name IS NOT NULL AND d10.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d10.month_name), 1, 3) || '-' || d10.year_id_disp
           ELSE
                'NONE'
           END                                                  assignment_started_cal_mon,
       CASE
           WHEN NVL(d10.fiscal_month_name,d10.month_name) IS NOT NULL AND NVL(d10.fiscal_year_id_disp,d10.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d10.fiscal_month_name,d10.month_name)), 1, 3) || '-' || NVL(d10.fiscal_year_id_disp,d10.year_id_disp)
           ELSE
                'NONE'
        END                                                     assignment_started_fis_mon,
           NVL(d11.year_id_disp,'NONE')                                    assignment_effective_cal_yr,
       NVL(NVL(d11.fiscal_year_id_disp,d11.year_id_disp),'NONE')         assignment_effective_fis_yr,
       CASE
          WHEN d11.quarter_name IS NOT NULL AND d11.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d11.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d11.year_id_disp
              WHEN UPPER(d11.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d11.year_id_disp
              WHEN UPPER(d11.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d11.year_id_disp
              WHEN UPPER(d11.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d11.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         assignment_effective_cal_qtr,
       CASE
          WHEN NVL(d11.fiscal_quarter_name,d11.quarter_name) IS NOT NULL AND NVL(d11.fiscal_year_id_disp,d11.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d11.fiscal_quarter_name,d11.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d11.fiscal_year_id_disp,d11.year_id_disp)
              WHEN UPPER(NVL(d11.fiscal_quarter_name,d11.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d11.fiscal_year_id_disp,d11.year_id_disp)
              WHEN UPPER(NVL(d11.fiscal_quarter_name,d11.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d11.fiscal_year_id_disp,d11.year_id_disp)
              WHEN UPPER(NVL(d11.fiscal_quarter_name,d11.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d11.fiscal_year_id_disp,d11.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   assignment_effective_fis_qtr,
       CASE
           WHEN d11.month_name IS NOT NULL AND d11.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d11.month_name), 1, 3) || '-' || d11.year_id_disp
           ELSE
                'NONE'
           END                                                  assignment_effective_cal_mon,
       CASE
           WHEN NVL(d11.fiscal_month_name,d11.month_name) IS NOT NULL AND NVL(d11.fiscal_year_id_disp,d11.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d11.fiscal_month_name,d11.month_name)), 1, 3) || '-' || NVL(d11.fiscal_year_id_disp,d11.year_id_disp)
           ELSE
                'NONE'
        END                                                     assignment_effective_fis_mon,
       NVL(j.job_id,-1)                                              job_id,
       NVL(j.job_category_desc,'NONE')                               job_category,
       NVL(j.job_title,'NONE')                                       job_title,
       NVL(j.job_level_desc,'NONE')                                  job_level,
       NVL(j.job_category_id,-1)                                     job_category_id,
       NVL(j.job_level_id,-1)                                        job_level_id,
        NVL(f.TT_JOB_APPROVAL,0)                                     TT_JOB_APPROVAL,
          NVL(f.TT_JOB_RELEASED,0)                                      TT_JOB_RELEASED,
          NVL(f.TT_MATCH_FOR_SUPP,0)                                    TT_MATCH_FOR_SUPP,
          NVL(f.TT_FWD_TO_HM,0)                                       TT_FWD_TO_HM ,
         NVL(f.TT_CREATE_ASSIGNMENT,0)                                 TT_CREATE_ASSIGNMENT ,
          NVL(f.TT_START_ASSIGNMENT,0)                                  TT_START_ASSIGNMENT ,
          NVL(f.TT_EFFECTIVE_ASSIGNMENT,0)                                TT_EFFECTIVE_ASSIGNMENT ,
          NVL(f.TT_FILL_ASSIGNMENT,0)                                     TT_FILL_ASSIGNMENT
from   dm_tt_fill_fact f, 
       dm_buyer_dim b,  
       dm_supplier_dim s,
       dm_job_dim j,
       dm_date_dim d, 
       dm_date_dim d1, 
       dm_date_dim d2, 
       dm_date_dim d3, 
       dm_date_dim d4, 
       dm_date_dim d5, 
       dm_date_dim d6, 
       dm_date_dim d7, 
       dm_date_dim d8, 
       dm_date_dim d9, 
       dm_date_dim d10, 
       dm_date_dim d11
where   f.delete_flag = 'N'
and f.buyer_org_dim_id = b.org_dim_id
and f.supplier_org_dim_id = s.org_dim_id
and f.job_dim_id = j.job_dim_id(+)
and f.TIME_PERIOD_DATE_DIM_ID = d.date_dim_id(+)
and f.BUYER_JOB_APPR_DATE_DIM_ID = d1.date_dim_id(+)
and f.BUYER_JOB_CREATE_DATE_DIM_ID = d2.date_dim_id(+)
and f.JOB_RELEASE_SUPP_DATE_DIM_ID  = d3.date_dim_id(+)
and f.MATCH_SUBMITTED_DATE_DIM_ID  = d4.date_dim_id(+)
and f.fwd_hm_DATE_DIM_ID  = d5.date_dim_id(+)
and f.CAND_INTERVIEW_DATE_DIM_ID  = d6.date_dim_id(+)
and f.WO_RELEASE_TO_SUPP_DATE_DIM_ID  = d7.date_dim_id(+)
and f.WO_ACCEPT_BY_SUPP_DATE_DIM_ID  = d8.date_dim_id(+)
and f.ASSIGNMENT_CREATED_DATE_DIM_ID  = d9.date_dim_id(+)
and f.ASSIGNMENT_START_DATE_DIM_ID  = d10.date_dim_id(+)
and f.ASSIGNMENT_EFFECT_DATE_DIM_ID  = d11.date_dim_id(+)
/

