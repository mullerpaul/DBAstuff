CREATE OR REPLACE PACKAGE BODY dm_ratecard_dim_process AS

   g_pkg_name              VARCHAR2(35)         := 'DM_RATECARD_DIM_PROCESS';
   g_app_err_msg           VARCHAR2(512)       := NULL;
   g_db_err_msg            VARCHAR2(512)       := NULL;
   g_sub_id                NUMBER;

   g_exception             EXCEPTION;
   pragma                  exception_init(g_exception, -20001);
   g_last_process_date     DATE                 := TO_DATE('01-JAN-1999','DD-MON-YYYY');

   TYPE dm_currency_dim_tabtyp IS TABLE OF dm_currency_dim%ROWTYPE
     INDEX BY VARCHAR2(10);
   g_currency_dim_tab dm_currency_dim_tabtyp;

   ---------------------------------------------------------------------------
   -- Procedure Name : get_currency_dim_id
   -- Description    :  lookup values from dm_currency_dim
   ---------------------------------------------------------------------------
   FUNCTION get_currency_dim_id(in_currency_code IN VARCHAR2)
   RETURN NUMBER
   IS
     ln_currency_dim_id  NUMBER;
   BEGIN
     IF g_currency_dim_tab.EXISTS(in_currency_code) THEN 
        ln_currency_dim_id := g_currency_dim_tab(in_currency_code).currency_dim_id;
     ELSE
        ln_currency_dim_id := 0;
     END IF;
     RETURN ln_currency_dim_id;
   END get_currency_dim_id;

   ---------------------------------------------------------------------------
   -- Procedure Name : set_currency_dim_tab
   -- Description    : set up lookup values from dm_currency_dim
   ---------------------------------------------------------------------------
   PROCEDURE set_currency_dim_tab
     (in_msg_id                 IN NUMBER)
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.set_currency_dim_tab' ;
   BEGIN
     FOR currency_dim_rec IN (SELECT * FROM dm_currency_dim)
     LOOP
        g_currency_dim_tab(currency_dim_rec.currency_code) := currency_dim_rec;
     END LOOP;

   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := lv_proc_name||', unable to pull records from dm_currency_dim !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END set_currency_dim_tab;

   PROCEDURE delete_dups
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   )
   IS
          v_proc_name  VARCHAR2(100) := g_pkg_name || '.delete_dups' ;
          v_rec_count  NUMBER;
   BEGIN
          DELETE dm_ratecard_tmp
           WHERE ROWID IN
                 (
                   SELECT ROWID
                     FROM (
                            SELECT t.rowid
                                   , ROW_NUMBER() OVER ( PARTITION BY t.buyerorg_id, t.supplierorg_id, t.ratecard_identifier_id
                                                                      , t.job_template_id, t.data_source_code
                                                             ORDER BY NVL2(t.min_reg_bill_rate,1,0) DESC, ratecard_id DESC
                                                       ) AS rnk
                              FROM dm_ratecard_tmp t
                             WHERE t.data_source_code = p_source_code
                          )
                    WHERE rnk > 1
                 );

          v_rec_count := SQL%ROWCOUNT;
          COMMIT;

          g_sub_id := NVL(g_sub_id,0) + 1;
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, v_rec_count || ' duplicate records deleted from dm_ratecard_tmp', v_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');
   END delete_dups;

   PROCEDURE invalidate_fo_deleted
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   )
   IS
          v_proc_name  VARCHAR2(100) := g_pkg_name || '.invalidate_fo_deleted' ;
          v_rec_count  NUMBER;
   BEGIN
          UPDATE dm_ratecard_dim d
             SET   is_effective     = 'N'
                 , valid_to_date    = SYSDATE
                 , last_update_date = SYSDATE
           WHERE d.data_source_code = p_source_code
             AND d.valid_to_date IS NULL
             AND NOT EXISTS (
                              SELECT NULL 
                                FROM dm_ratecard_tmp t
                               WHERE t.data_source_code       = d.data_source_code
                                 AND t.buyerorg_id            = d.buyerorg_id
                                 AND t.ratecard_identifier_id = d.ratecard_identifier_id
                                 AND t.job_template_id        = d.job_template_id
                                 AND t.supplierorg_id         = d.supplierorg_id
                            );

          v_rec_count := SQL%ROWCOUNT;
          COMMIT;

          g_sub_id := NVL(g_sub_id,0) + 1;
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, v_rec_count || ' records invalidated as they no longer exist in FO', v_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');
   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := v_proc_name||', unable to invalidate records in dm_ratecard_dim that no longer exist in FO !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END invalidate_fo_deleted;

   ---------------------------------------------------------------------------
   -- Procedure Name : insert_dim_records
   -- Description    : Insert Initial(first time) dim records
   ---------------------------------------------------------------------------
   PROCEDURE insert_dim_records
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   )
   IS
     v_proc_name  VARCHAR2(100) := g_pkg_name||'.insert_dim_records' ;
     v_rec_count  NUMBER;
   BEGIN
          INSERT INTO dm_ratecard_dim x
          (
              ratecard_dim_id
            , data_source_code
            , version_id
            , buyerorg_id
            , ratecard_id
            , ratecard_identifier_id
            , job_template_id
            , supplierorg_id
            , ratecard_identifier
            , ratecard_type
            , currency_dim_id
            , min_reg_bill_rate
            , max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_cs_bill_rate
            , max_cs_bill_rate
            , min_reg_pay_rate
            , max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cs_pay_rate
            , max_cs_pay_rate
            , is_active
            , is_ratecard_range
            , is_ratecard_factor
            , min_reg_markup
            , max_reg_markup
            , min_ot_markup
            , max_ot_markup
            , min_dt_markup
            , max_dt_markup
            , min_cs_markup
            , max_cs_markup
            , buyer_firm_fk
            , supplier_firm_fk
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
            , is_effective
            , batch_id
            , last_update_date
            , valid_from_date
            , valid_to_date
          )
          SELECT
              dm_ratecard_dim_seq.NEXTVAL AS ratecard_dim_id
            , data_source_code
            , 1 AS version_id
            , buyerorg_id
            , ratecard_id
            , ratecard_identifier_id
            , job_template_id
            , supplierorg_id
            , ratecard_identifier
            , ratecard_type
            , currency_dim_id
            , min_reg_bill_rate
            , max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_cs_bill_rate
            , max_cs_bill_rate
            , min_reg_pay_rate
            , max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cs_pay_rate
            , max_cs_pay_rate
            , is_active
            , is_ratecard_range
            , is_ratecard_factor
            , min_reg_markup
            , max_reg_markup
            , min_ot_markup
            , max_ot_markup
            , min_dt_markup
            , max_dt_markup
            , min_cs_markup
            , max_cs_markup
            , buyer_firm_fk
            , supplier_firm_fk
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
            , 'Y' AS is_effective
            , p_msg_id AS batch_id
            , SYSDATE AS last_update_date
            , g_last_process_date AS valid_from_date
            , NULL AS valid_to_date
      FROM dm_ratecard_tmp t
     WHERE t.data_source_code = p_source_code;

     v_rec_count := SQL%ROWCOUNT;

     g_sub_id := NVL(g_sub_id,0) + 1;
     dm_util_log.p_log_msg(p_msg_id, g_sub_id, v_rec_count || ' initial records inserted into dm_ratecard_dim', v_proc_name, 'I');
     dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');
   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := v_proc_name||', unable to insert initial records in dm_ratecard_dim !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END insert_dim_records;

   ---------------------------------------------------------------------------
   -- Procedure Name : insert_new_dim_records
   -- Description    : Insert new dim records
   ---------------------------------------------------------------------------
   PROCEDURE insert_new_dim_records
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   )
   IS
          v_proc_name  VARCHAR2(100) := g_pkg_name||'.insert_new_dim_records' ;
          v_rec_count  NUMBER;
   BEGIN
          INSERT INTO dm_ratecard_dim x
          (
              ratecard_dim_id
            , data_source_code
            , version_id
            , buyerorg_id
            , ratecard_id
            , ratecard_identifier_id
            , job_template_id
            , supplierorg_id
            , ratecard_identifier
            , ratecard_type
            , currency_dim_id
            , min_reg_bill_rate
            , max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_cs_bill_rate
            , max_cs_bill_rate
            , min_reg_pay_rate
            , max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cs_pay_rate
            , max_cs_pay_rate
            , is_active
            , is_ratecard_range
            , is_ratecard_factor
            , min_reg_markup
            , max_reg_markup
            , min_ot_markup
            , max_ot_markup
            , min_dt_markup
            , max_dt_markup
            , min_cs_markup
            , max_cs_markup
            , buyer_firm_fk
            , supplier_firm_fk
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
            , is_effective
            , batch_id
            , last_update_date
            , valid_from_date
            , valid_to_date
          )
          SELECT
              dm_ratecard_dim_seq.NEXTVAL AS ratecard_dim_id
            , data_source_code
            , 1 AS version_id
            , buyerorg_id
            , ratecard_id
            , ratecard_identifier_id
            , job_template_id
            , supplierorg_id
            , ratecard_identifier
            , ratecard_type
            , currency_dim_id
            , min_reg_bill_rate
            , max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_cs_bill_rate
            , max_cs_bill_rate
            , min_reg_pay_rate
            , max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cs_pay_rate
            , max_cs_pay_rate
            , is_active
            , is_ratecard_range
            , is_ratecard_factor
            , min_reg_markup
            , max_reg_markup
            , min_ot_markup
            , max_ot_markup
            , min_dt_markup
            , max_dt_markup
            , min_cs_markup
            , max_cs_markup
            , buyer_firm_fk
            , supplier_firm_fk
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
            , 'Y' AS is_effective
            , p_msg_id AS batch_id
            , SYSDATE AS last_update_date
            , g_last_process_date AS valid_from_date
            , NULL AS valid_to_date
      FROM dm_ratecard_tmp t
     WHERE NOT EXISTS (
                        SELECT NULL 
                          FROM dm_ratecard_dim d
                         WHERE d.data_source_code       = t.data_source_code
                           AND d.buyerorg_id            = t.buyerorg_id
                           AND d.ratecard_identifier_id = t.ratecard_identifier_id
                           AND d.job_template_id        = t.job_template_id
                           AND d.supplierorg_id         = t.supplierorg_id
                      );

     v_rec_count := SQL%ROWCOUNT;
     COMMIT;

     g_sub_id := NVL(g_sub_id,0) + 1;
     dm_util_log.p_log_msg(p_msg_id, g_sub_id, v_rec_count || ' new records inserted into dm_ratecard_dim', v_proc_name, 'I');
     dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');
   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := v_proc_name||', unable to insert new records in dm_ratecard_dim !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END insert_new_dim_records;

   ---------------------------------------------------------------------------
   -- Procedure Name : pull_fo_ratecard_data
   -- Description    : Procedure to pull ratecard data from FO and load load dm_ratecard_tmp
   ---------------------------------------------------------------------------
   PROCEDURE pull_fo_ratecard_data
   ( 
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   )
   IS
          v_proc_name  VARCHAR2(100) := g_pkg_name || '.pull_fo_ratecard_data';
          v_rec_count  NUMBER;
   BEGIN
          INSERT INTO dm_ratecard_tmp t
          (
              data_source_code
            , ratecard_id
            , ratecard_identifier_id
            , ratecard_identifier
            , buyerorg_id
            , buyer_firm_fk
            , supplierorg_id
            , supplier_firm_fk
            , ratecard_type
            , is_active
            , is_ratecard_factor
            , is_ratecard_range
            , currency_unit
            , currency_dim_id
            , job_template_id
            , min_reg_bill_rate
            , max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_reg_pay_rate
            , max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cs_bill_rate
            , max_cs_bill_rate
            , min_cs_pay_rate
            , max_cs_pay_rate
            , min_reg_markup
            , max_reg_markup
            , min_ot_markup
            , max_ot_markup
            , min_dt_markup
            , max_dt_markup
            , min_cs_markup
            , max_cs_markup
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
          )
          SELECT
              data_source_code
            , ratecard_id
            , ratecard_identifier_id
            , ratecard_identifier
            , buyerorg AS buyerorg_id
            , buyer_firm_fk
            , supplierorg_id
            , supplierfirm_id AS supplier_firm_fk
            , ratecard_type
            , active AS is_active
            , uses_factors AS is_ratecard_factor
            , uses_ranges AS is_ratecard_range
            , currency_unit
            , get_currency_dim_id(currency_unit) AS currency_dim_id
            , job_template_fk AS job_template_id
            , min_bill_rate AS min_reg_bill_rate
            , max_bill_rate AS max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_pay_rate AS min_reg_pay_rate
            , max_pay_rate AS max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cust_bill_rate    AS min_cs_bill_rate
            , max_cust_bill_rate    AS max_cs_bill_rate
            , min_cust_pay_rate     AS min_cs_pay_rate
            , max_cust_pay_rate     AS max_cs_pay_rate
            , ROUND(min_markup/100, 2)      AS min_reg_markup
            , ROUND(max_markup/100, 2)      AS max_reg_markup
            , ROUND(min_ot_markup/100, 2)   AS min_ot_markup
            , ROUND(max_ot_markup/100, 2)   AS max_ot_markup
            , ROUND(min_dt_markup/100, 2)   AS min_dt_markup
            , ROUND(max_dt_markup/100, 2)   AS max_dt_markup
            , ROUND(min_cust_markup/100, 2) AS min_cs_markup
            , ROUND(max_cust_markup/100, 2) AS max_cs_markup
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
            FROM fo_dm_ratecard_tmp@FO_R
           WHERE data_source_code = p_source_code 
             AND active = 'Y';

          v_rec_count := SQL%ROWCOUNT;
          COMMIT;

          g_sub_id := NVL(g_sub_id,0) + 1;
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, v_rec_count || ' records inserted into dm_ratecard_tmp', v_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');

   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := v_proc_name || ', unable to insert records into dm_ratecard_tmp !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END pull_fo_ratecard_data;
 
   PROCEDURE insert_new_ratecard_versions
   (
       p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
     , p_start_date  IN DATE     DEFAULT SYSDATE
     , p_msg_id      IN NUMBER
   )
   IS
          v_proc_name  VARCHAR2(100) := g_pkg_name||'.insert_new_ratecard_versions' ;
          v_rec_count  NUMBER;
   BEGIN
          INSERT INTO dm_ratecard_dim t
          (
              ratecard_dim_id
            , data_source_code
            , version_id
            , buyerorg_id
            , ratecard_id
            , ratecard_identifier_id
            , job_template_id
            , supplierorg_id
            , ratecard_identifier
            , ratecard_type
            , currency_dim_id
            , min_reg_bill_rate
            , max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_cs_bill_rate
            , max_cs_bill_rate
            , min_reg_pay_rate
            , max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cs_pay_rate
            , max_cs_pay_rate
            , is_active
            , is_ratecard_range
            , is_ratecard_factor
            , min_reg_markup
            , max_reg_markup
            , min_ot_markup
            , max_ot_markup
            , min_dt_markup
            , max_dt_markup
            , min_cs_markup
            , max_cs_markup
            , buyer_firm_fk
            , supplier_firm_fk
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
            , is_effective
            , batch_id
            , last_update_date
            , valid_from_date
            , valid_to_date
          )
          SELECT
              dm_ratecard_dim_seq.NEXTVAL AS ratecard_dim_id
            , data_source_code
            , new_version_id AS version_id
            , buyerorg_id
            , ratecard_id
            , ratecard_identifier_id
            , job_template_id
            , supplierorg_id
            , ratecard_identifier
            , ratecard_type
            , currency_dim_id
            , min_reg_bill_rate
            , max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_cs_bill_rate
            , max_cs_bill_rate
            , min_reg_pay_rate
            , max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cs_pay_rate
            , max_cs_pay_rate
            , is_active
            , is_ratecard_range
            , is_ratecard_factor
            , min_reg_markup
            , max_reg_markup
            , min_ot_markup
            , max_ot_markup
            , min_dt_markup
            , max_dt_markup
            , min_cs_markup
            , max_cs_markup
            , buyer_firm_fk
            , supplier_firm_fk
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
            , 'Y' AS is_effective
            , p_msg_id AS batch_id
            , SYSDATE AS last_update_date
            , p_start_date AS valid_from_date
            , NULL AS valid_to_date
      FROM dm_ratecard_stage s
     WHERE s.data_source_code = p_source_code;

     v_rec_count := SQL%ROWCOUNT;

     g_sub_id := NVL(g_sub_id,0) + 1;
     dm_util_log.p_log_msg(p_msg_id, g_sub_id, v_rec_count || ' new version records inserted into dm_ratecard_dim', v_proc_name, 'I');
     dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');
   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := v_proc_name||', unable to insert new version records in dm_ratecard_dim !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END insert_new_ratecard_versions;

   PROCEDURE invalidate_old_ratecards
   (
       p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
     , p_close_date  IN DATE     DEFAULT SYSDATE
     , p_msg_id      IN NUMBER
   )
   IS
          v_proc_name  VARCHAR2(100) := g_pkg_name||'.invalidate_old_ratecards' ;
          v_rec_count  NUMBER;
   BEGIN
          --MERGE INTO dm_ratecard_dim t
          --USING      dm_ratecard_stage s
          --   ON (
          --        t.ratecard_dim_id = s.ratecard_dim_id
          --      )
          -- WHEN MATCHED THEN UPDATE SET
          --        is_effective     = 'N'
          --      , valid_to_date    = p_close_date
          --      , batch_id         = p_msg_id
          --      , last_update_date = SYSDATE;
          UPDATE dm_ratecard_dim t 
             SET   t.is_effective     = 'N'
                 , t.valid_to_date    = p_close_date
                 , t.batch_id         = p_msg_id
                 , t.last_update_date = SYSDATE
           WHERE EXISTS (
                          SELECT NULL
                            FROM dm_ratecard_stage s
                           WHERE s.ratecard_dim_id = t.ratecard_dim_id
                        );
           
          v_rec_count := SQL%ROWCOUNT;
          g_sub_id := NVL(g_sub_id,0) + 1;
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, v_rec_count || ' old version records invalidated in dm_ratecard_dim', v_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');
   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := v_proc_name||', unable to invalidate old version records in dm_ratecard_dim !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END invalidate_old_ratecards;

   PROCEDURE get_changed_ratecards
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   )
   IS
          v_proc_name  VARCHAR2(100) := g_pkg_name||'.get_changed_ratecards' ;
          v_rec_count  NUMBER;
   BEGIN
          INSERT INTO dm_ratecard_stage x
          (
              ratecard_dim_id
            , new_version_id
            , data_source_code
            , ratecard_id
            , ratecard_identifier_id
            , ratecard_identifier
            , buyerorg_id
            , buyer_firm_fk
            , supplierorg_id
            , supplier_firm_fk
            , job_template_id
            , ratecard_type
            , is_active
            , is_ratecard_range
            , is_ratecard_factor
            , currency_dim_id
            , min_reg_bill_rate
            , max_reg_bill_rate
            , min_ot_bill_rate
            , max_ot_bill_rate
            , min_dt_bill_rate
            , max_dt_bill_rate
            , min_cs_bill_rate
            , max_cs_bill_rate
            , min_reg_pay_rate
            , max_reg_pay_rate
            , min_ot_pay_rate
            , max_ot_pay_rate
            , min_dt_pay_rate
            , max_dt_pay_rate
            , min_cs_pay_rate
            , max_cs_pay_rate
            , min_reg_markup
            , max_reg_markup
            , min_ot_markup
            , max_ot_markup
            , min_dt_markup
            , max_dt_markup
            , min_cs_markup
            , max_cs_markup
            , min_ot_bill_factor
            , max_ot_bill_factor
            , min_dt_bill_factor
            , max_dt_bill_factor
            , min_ot_pay_factor
            , max_ot_pay_factor
            , min_dt_pay_factor
            , max_dt_pay_factor
          )
          SELECT 
              d.ratecard_dim_id
            , d.version_id + 1 AS new_version_id
            , t.data_source_code
            , t.ratecard_id
            , t.ratecard_identifier_id
            , t.ratecard_identifier
            , t.buyerorg_id
            , t.buyer_firm_fk
            , t.supplierorg_id
            , t.supplier_firm_fk
            , t.job_template_id
            , t.ratecard_type
            , t.is_active
            , t.is_ratecard_range
            , t.is_ratecard_factor
            , t.currency_dim_id
            , t.min_reg_bill_rate
            , t.max_reg_bill_rate
            , t.min_ot_bill_rate
            , t.max_ot_bill_rate
            , t.min_dt_bill_rate
            , t.max_dt_bill_rate
            , t.min_cs_bill_rate
            , t.max_cs_bill_rate
            , t.min_reg_pay_rate
            , t.max_reg_pay_rate
            , t.min_ot_pay_rate
            , t.max_ot_pay_rate
            , t.min_dt_pay_rate
            , t.max_dt_pay_rate
            , t.min_cs_pay_rate
            , t.max_cs_pay_rate
            , t.min_reg_markup
            , t.max_reg_markup
            , t.min_ot_markup
            , t.max_ot_markup
            , t.min_dt_markup
            , t.max_dt_markup
            , t.min_cs_markup
            , t.max_cs_markup
            , t.min_ot_bill_factor
            , t.max_ot_bill_factor
            , t.min_dt_bill_factor
            , t.max_dt_bill_factor
            , t.min_ot_pay_factor
            , t.max_ot_pay_factor
            , t.min_dt_pay_factor
            , t.max_dt_pay_factor
            FROM dm_ratecard_tmp t, dm_ratecard_dim d
           WHERE d.data_source_code       = t.data_source_code
             AND d.buyerorg_id            = t.buyerorg_id
             AND d.ratecard_identifier_id = t.ratecard_identifier_id
             AND d.job_template_id        = t.job_template_id
             AND d.supplierorg_id         = t.supplierorg_id
             AND d.is_effective           = 'Y'
             AND ( 
                      NVL(d.is_ratecard_factor,'x') <> NVL(t.is_ratecard_factor,'x')
                   OR NVL(d.ratecard_id,-1)         <> NVL(t.ratecard_id,-1)
                   OR NVL(d.ratecard_identifier,'x')<> NVL(t.ratecard_identifier,'x')
                   OR NVL(d.ratecard_type,'x')      <> NVL(t.ratecard_type,'x')
                   OR NVL(d.is_ratecard_range,'x')  <> NVL(t.is_ratecard_range,'x')
                   OR NVL(d.currency_dim_id,-1)     <> NVL(t.currency_dim_id,-1)
                   OR NVL(d.min_reg_bill_rate,-1)   <> NVL(t.min_reg_bill_rate,-1)
                   OR NVL(d.max_reg_bill_rate,-1)   <> NVL(t.max_reg_bill_rate,-1)
                   OR NVL(d.min_ot_bill_rate,-1)    <> NVL(t.min_ot_bill_rate,-1)
                   OR NVL(d.max_ot_bill_rate,-1)    <> NVL(t.max_ot_bill_rate,-1)
                   OR NVL(d.min_dt_bill_rate,-1)    <> NVL(t.min_dt_bill_rate,-1)
                   OR NVL(d.max_dt_bill_rate,-1)    <> NVL(t.max_dt_bill_rate,-1)
                   OR NVL(d.min_reg_pay_rate,-1)    <> NVL(t.min_reg_pay_rate,-1)
                   OR NVL(d.max_reg_pay_rate,-1)    <> NVL(t.max_reg_pay_rate,-1)
                   OR NVL(d.min_ot_pay_rate,-1)     <> NVL(t.min_ot_pay_rate,-1)
                   OR NVL(d.max_ot_pay_rate,-1)     <> NVL(t.max_ot_pay_rate,-1)
                   OR NVL(d.min_dt_pay_rate,-1)     <> NVL(t.min_dt_pay_rate,-1)
                   OR NVL(d.max_dt_pay_rate,-1)     <> NVL(t.max_dt_pay_rate,-1)
                   OR NVL(d.min_cs_bill_rate,-1)    <> NVL(t.min_cs_bill_rate,-1)
                   OR NVL(d.max_cs_bill_rate,-1)    <> NVL(t.max_cs_bill_rate,-1)
                   OR NVL(d.min_cs_pay_rate,-1)     <> NVL(t.min_cs_pay_rate,-1)
                   OR NVL(d.max_cs_pay_rate,-1)     <> NVL(t.max_cs_pay_rate,-1)
                   OR NVL(d.min_reg_markup,-1)      <> NVL(ROUND(t.min_reg_markup, 2),-1)
                   OR NVL(d.max_reg_markup,-1)      <> NVL(ROUND(t.max_reg_markup, 2),-1)
                   OR NVL(d.min_ot_markup,-1)       <> NVL(ROUND(t.min_ot_markup, 2),-1)
                   OR NVL(d.max_ot_markup,-1)       <> NVL(ROUND(t.max_ot_markup, 2),-1)
                   OR NVL(d.min_dt_markup,-1)       <> NVL(ROUND(t.min_dt_markup, 2), -1)
                   OR NVL(d.max_dt_markup,-1)       <> NVL(ROUND(t.max_dt_markup,2),-1)
                   OR NVL(d.min_cs_markup,-1)       <> NVL(ROUND(t.min_cs_markup, 2),-1)
                   OR NVL(d.max_cs_markup,-1)       <> NVL(ROUND(t.max_cs_markup, 2),-1)
                   OR NVL(d.min_ot_bill_factor,-1)  <> NVL(t.min_ot_bill_factor,-1)
                   OR NVL(d.max_ot_bill_factor,-1)  <> NVL(t.max_ot_bill_factor,-1)
                   OR NVL(d.min_dt_bill_factor,-1)  <> NVL(t.min_dt_bill_factor,-1)
                   OR NVL(d.max_dt_bill_factor,-1)  <> NVL(t.max_dt_bill_factor,-1)
                   OR NVL(d.min_ot_pay_factor,-1)   <> NVL(t.min_ot_pay_factor,-1)
                   OR NVL(d.max_ot_pay_factor,-1)   <> NVL(t.max_ot_pay_factor,-1)
                   OR NVL(d.min_dt_pay_factor,-1)   <> NVL(t.min_dt_pay_factor,-1)
                   OR NVL(d.max_dt_pay_factor,-1)   <> NVL(t.max_dt_pay_factor,-1)
                 );

          v_rec_count := SQL%ROWCOUNT;
          COMMIT;

          g_sub_id := NVL(g_sub_id,0) + 1;
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, v_rec_count || ' changed ratecard records inserted into dm_ratecard_stage', v_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
          g_sub_id := NVL(g_sub_id,0) + 1;
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, 'No changed ratecard records found', v_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, g_sub_id, NULL, NULL, 'U');
     WHEN OTHERS THEN
          g_app_err_msg := v_proc_name||', unable insert changed ratecard records inserted into dm_ratecard_stage!';
          g_db_err_msg  := SQLERRM;
          RAISE g_exception;
   END get_changed_ratecards;

   ---------------------------------------------------------------------------
   -- Procedure Name : extract_fo_ratecards
   -- Description    : Procedure to load FO rate card table fo_dm_ratecard_tmp
   ---------------------------------------------------------------------------
   PROCEDURE extract_fo_ratecards
   (
       p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
     , p_msg_id      IN NUMBER
   )
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.extract_fo_ratecards' ;
     ln_offset            NUMBER := 50000;
     ln_fo_count          NUMBER;
     lv_err_msg           VARCHAR2(2000) := NULL;
  BEGIN
     BEGIN
       CASE (p_source_code)
       WHEN 'REGULAR' THEN
            fo_dm_ratecard_dim_process.main@FO_R(p_source_code,p_msg_id,ln_offset);
       END CASE;

     EXCEPTION
       WHEN OTHERS THEN
         g_app_err_msg := 'Unable to execute the remote procedure to get the FO ratecard data !';
         g_db_err_msg  := SQLERRM;
     END;

     --
     -- check for any errors in remote procedure
     --
     BEGIN
       CASE (p_source_code)
       WHEN 'REGULAR' THEN
             SELECT err_msg INTO lv_err_msg
               FROM fo_dm_ratecard_errmsg@FO_R
              WHERE ROWNUM < 2;
       END CASE;

       IF lv_err_msg IS NOT NULL THEN
          g_app_err_msg := 'Errors occured in the remote procedure to get ratecard data! ';
          g_db_err_msg  := lv_err_msg || ' ' || SQLERRM;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
           lv_err_msg := NULL;
     END;

     IF (g_db_err_msg IS NOT NULL) THEN
        RAISE g_exception;
     END IF;

   END extract_fo_ratecards;

  /*---------------------------------------------------------------------------
   * Procedure : main
   * Desc      : This proccedure contains all the steps involved in gathering
   *             and migrating rate card information from data mart as well as
   *             Front office.
   *---------------------------------------------------------------------------*/
   PROCEDURE main
   (
       p_source_code  IN VARCHAR2 DEFAULT 'REGULAR'
     , p_dbg_mode          IN VARCHAR2 DEFAULT 'N'
   )
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.main';
     is_initial_load      VARCHAR2(1)     := 'N';
     v_msg_id             NUMBER;
     ln_count             NUMBER;
     ln_process_cnt       NUMBER;
     lv_err_msg           VARCHAR2(4000)  := NULL;
     ln_err               NUMBER;
     ld_last_process_date DATE;
     ld_last_update_date  DATE;
     v_close_date         DATE;
     v_start_date         DATE;
   BEGIN
          --
          -- Get the sequence reuired for logging messages
          --
          SELECT dm_msg_log_seq.NEXTVAL
            INTO v_msg_id FROM dual;

          BEGIN
                SELECT NULL
                  INTO is_initial_load
                  FROM dm_cube_objects
                 WHERE object_name = 'DM_RATECARD_DIM';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                      INSERT INTO dm_cube_objects 
                             (object_name,last_update_date,last_identifier,object_source_code)
                      VALUES ('DM_RATECARD_DIM', g_last_process_date, NULL, p_source_code);
                      COMMIT;
          END;

          BEGIN
                SELECT 'N'
                  INTO is_initial_load
                  FROM dm_ratecard_dim d
                 WHERE d.ratecard_dim_id > 0
                   AND ROWNUM < 2;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN is_initial_load := 'Y';
          END;

          --
          -- Extract Ratecard data from FO
          extract_fo_ratecards (p_source_code, v_msg_id);

          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_ratecard_tmp';
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_ratecard_stage';

          -- Setup currency dim lookup table
          set_currency_dim_tab(v_msg_id);

          pull_fo_ratecard_data (p_source_code, v_msg_id);
          delete_dups(p_source_code, v_msg_id);

          IF (is_initial_load = 'Y')
             THEN
                   insert_dim_records(p_source_code, v_msg_id);
                   COMMIT;
             ELSE
                   invalidate_fo_deleted(p_source_code, v_msg_id);
                   get_changed_ratecards(p_source_code, v_msg_id);
                   insert_new_dim_records(p_source_code, v_msg_id);

                   v_close_date := SYSDATE;
                   v_start_date := v_close_date + (1/86400);
                   invalidate_old_ratecards(p_source_code, v_close_date, v_msg_id);
                   insert_new_ratecard_versions(p_source_code, v_start_date, v_msg_id);
                   COMMIT;
          END IF;

          UPDATE dm_cube_objects
             SET last_update_date = SYSDATE
           WHERE object_name        = 'DM_RATECARD_DIM'
             AND object_source_code = p_source_code;

          COMMIT;
   EXCEPTION
     WHEN OTHERS THEN ROLLBACK; RAISE;
   END main;

END dm_ratecard_dim_process;
/