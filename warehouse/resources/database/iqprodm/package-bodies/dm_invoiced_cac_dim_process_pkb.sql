CREATE OR REPLACE PACKAGE BODY dm_invoiced_cac_dim_process
/********************************************************************
 * Name:   dm_invoiced_cac_dim_process
 * Desc:   This package contains all the procedures required to
 *         migrate/process the invoiced CAC dimension
 * Source: Front office and Data mart ( Invoiced Spend table)
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj   06/28/2010    Initial
 * JoeP    02/01/2016    Hard-coded dblink
 ********************************************************************/
AS
 /**************************************************************
  * Name: get_hlvl_desc
  * Desc: Function to get hierachy level description
  *       based on cac segment
  **************************************************************/
  FUNCTION get_hlvl_desc (in_buyer_org_id IN number,
                          iv_cac_value    IN varchar2,
                          in_level        IN number)
  RETURN varchar2
  IS
    hlvl_desc varchar2(500);
    lv_desc   varchar2(4000);
    CURSOR c1
    IS
    SELECT b.hierarchy_desc
      FROM dm_bus_org_lineage ol,
           dm_cac_hierarchy   b
     WHERE ol.descendant_bus_org_fk = in_buyer_org_id
       AND ol.ancestor_bus_org_fk   = b.BUYER_ORG_ID
       AND nvl(b.cac_value,'X')     = nvl(iv_cac_value,'X')
       AND b.hierarchy_level        = in_level
       AND b.is_effective           = 'Y'
       AND ol.is_effective          = 'Y';
  BEGIN
   FOR c2 in c1
   LOOP
     IF lv_desc IS NULL THEN
        lv_desc := c2.hierarchy_desc;
     ELSE
      lv_desc := lv_desc||'; '||c2.hierarchy_desc;
     END IF;
   END LOOP;

   hlvl_desc := ltrim(rtrim(substr(lv_desc,1,500)));

   RETURN hlvl_desc;

  END get_hlvl_desc;

 /**************************************************************
  * Name: get_hlvl_title
  * Desc: Function to get hierachy level title
  *       based on cac segment
  **************************************************************/
  FUNCTION get_hlvl_title (in_buyer_org_id IN number,
                           iv_cac_value    IN varchar2,
                           in_level        IN number)
  RETURN varchar2
  IS
    hlvl_title varchar2(250);
    lv_title   varchar2(4000);
    CURSOR c1
    IS
    SELECT b.hierarchy_title
      FROM dm_bus_org_lineage ol,
           dm_cac_hierarchy   b
     WHERE ol.descendant_bus_org_fk = in_buyer_org_id
       AND ol.ancestor_bus_org_fk   = b.BUYER_ORG_ID
       AND nvl(b.cac_value,'X')     = nvl(iv_cac_value,'X')
       AND b.hierarchy_level        = in_level
       AND b.is_effective           = 'Y'
       AND ol.is_effective          = 'Y';
  BEGIN
   FOR c2 in c1
   LOOP
     IF lv_title IS NULL THEN
        lv_title := c2.hierarchy_title;
     ELSE
      lv_title := lv_title||'; '||c2.hierarchy_title;
     END IF;
   END LOOP;

   hlvl_title := ltrim(rtrim(substr(lv_title,1,250)));

   RETURN hlvl_title;

  END get_hlvl_title;
/*****************************************************************
  * Name: bus_org_lineage_upd
  * Desc: This procedure pulls the data from FO for the current state
  *       of business org lineage and update dm business org_lineage
  *****************************************************************/
PROCEDURE bus_org_lineage_upd(in_msg_id   IN number,
                              on_err_num OUT number,
                              ov_err_msg OUT varchar2)
IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_invoiced_cac_dim_process.bus_org_lineage_upd' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
  CURSOR c1
  IS
  SELECT *
    FROM dm_bus_org_lineage_upd_tmp;
BEGIN
  on_err_num := 0;
  ov_err_msg := NULL;
  --
  -- Truncate temp tables
  --
  BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_bus_org_lineage_tmp';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_bus_org_lineage_upd_tmp';
  EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to truncate temp tables for dm_bus_org_lineage updates ! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
  END;

  --
  -- Insert the current stae of business org lineage from Front office
  --
  BEGIN
    INSERT
      INTO dm_bus_org_lineage_tmp
    SELECT *
      FROM bus_org_lineage@FO_R;
  EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into dm_bus_org_lineage_tmp data from front office ! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
  END;

  --
  -- insert into a temp table any data that is existing in data warehouse but not in front office
  --
  BEGIN
    INSERT
      INTO dm_bus_org_lineage_upd_tmp
    SELECT  a.ancestor_bus_org_fk,a.descendant_bus_org_fk
      FROM dm_bus_org_lineage a
     WHERE NOT EXISTS (SELECT 'x'
                         FROM dm_bus_org_lineage_tmp b
                        WHERE b.ancestor_bus_org_fk   = a.ancestor_bus_org_fk
                          AND b.descendant_bus_org_fk = a.descendant_bus_org_fk);
  EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into dm_bus_org_lineage_tmp data from front office ! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
  END;

  --
  -- If there is any data in data warehouse business org lineage that is not in
  -- front office. Then those rows need to be invalidated to reflect the FO state
  --
  BEGIN

    FOR c2 in c1
    LOOP
      UPDATE dm_bus_org_lineage
         SET is_effective     = 'N',
             last_update_date = SYSDATE
       WHERE ancestor_bus_org_fk   = c2.ancestor_bus_org_fk
         AND descendant_bus_org_fk = c2.descendant_bus_org_fk;
    END LOOP;

  EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to update dm_bus_org_lineage to invalidate rows ! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
  END;

  --
  -- Insert into dm_bus_org_lineage any new data from coming from front office
  --
  BEGIN
    INSERT
      INTO dm_bus_org_lineage
    SELECT a.*,'Y',SYSDATE
      FROM dm_bus_org_lineage_tmp a
     WHERE NOT EXISTS (SELECT 'x'
                         FROM dm_bus_org_lineage b
                        WHERE b.ancestor_bus_org_fk   = a.ancestor_bus_org_fk
                          AND b.descendant_bus_org_fk = a.descendant_bus_org_fk);
  EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to update dm_bus_org_lineage to invalidate rows ! ';
        lv_db_err_msg := SQLERRM;
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
END bus_org_lineage_upd;

 /*****************************************************************
  * Name: process_fo_hierarchy
  * Desc: This procedure pulls the data from FO CAC hierarchy MV
  *       and stores the data in Data Mart and also creates history
  *       (by updating the old records to inactive)
  *****************************************************************/
  PROCEDURE process_fo_hierarchy(in_msg_id   IN number,
                                 on_err_num OUT number,
                                 ov_err_msg OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_invoiced_cac_dim_process.process_fo_hierarchy' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER;
    CURSOR c1
    IS
    SELECT  *
      FROM dm_cac_hierarchy where is_effective           = 'Y';
  BEGIN
    on_err_num := 0;
    ov_err_msg := NULL;
    --
    -- Pull the data from Front office to a temp table
    --
    BEGIN
      INSERT
        INTO dm_fo_cac_hierarchy_tmp
             (buyer_org_id,
              cac_value ,
              cac_id ,
              hierarchy_level,
              hierarchy_desc,
              hierarchy_title
             )
      SELECT DISTINCT
             a.buyer_org_id ,
             a.cac_value,
             a.cac_id,
             a.hierarchy_level,
             a.hierarchy_desc,
             a.hierarchy_title
        FROM cac_category_hierarchy_mv@FO_R a
       WHERE a.buyer_org_id <> 24696; -- remove bearing point
    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into temp table dm_fo_cac_hierarchy_tmp ! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
    END;

    --
    -- Invalidate the records not in the current hierarchy
    --
    BEGIN
      FOR c2 IN c1
      LOOP
        SELECT count(1)
          INTO ln_count
          FROM dm_fo_cac_hierarchy_tmp
         WHERE buyer_org_id            = c2.buyer_org_id
           AND cac_value               = c2.cac_value
           AND hierarchy_title         = c2.hierarchy_title
           AND nvl(hierarchy_desc,'X') = nvl(c2.hierarchy_desc,'X')
           AND hierarchy_level         = c2.hierarchy_level;

        IF ln_count = 0 THEN
           UPDATE dm_cac_hierarchy
              SET is_effective            = 'N', -- invalidate with a flag of N
                  last_update_date        = sysdate
            WHERE buyer_org_id            = c2.buyer_org_id
              AND cac_value               = c2.cac_value
              AND hierarchy_title         = c2.hierarchy_title
              AND nvl(hierarchy_desc,'X') = nvl(c2.hierarchy_desc,'X')
              AND hierarchy_level         = c2.hierarchy_level;
        ELSE
          null;
        END IF;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to process the invalidation routine ! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
    END;

    --
    -- Insert into CAC hierarchy table stored in data mart with any new records
    --
    BEGIN
       INSERT
         INTO dm_cac_hierarchy
              (buyer_org_id,
               cac_value,
               cac_id,
               hierarchy_level,
               hierarchy_desc,
               hierarchy_title,
               is_effective ,
               last_update_date
              )
       SELECT a.buyer_org_id ,
              a.cac_value,
              a.cac_id,
              a.hierarchy_level,
              a.hierarchy_desc,
              a.hierarchy_title,
              'Y',
              SYSDATE
         FROM dm_fo_cac_hierarchy_tmp a
        WHERE NOT EXISTS
              (SELECT 'X'
                 FROM dm_cac_hierarchy b
                WHERE b.buyer_org_id            = a.buyer_org_id
                  AND b.cac_value               = a.cac_value
                  AND b.hierarchy_title         = a.hierarchy_title
                  AND nvl(b.hierarchy_desc,'X') = nvl(a.hierarchy_desc,'X')
                  AND b.hierarchy_level         = a.hierarchy_level);
    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable insert new records in dm_cac_hierarchy ! ';
        lv_db_err_msg := SQLERRM;
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
  END process_fo_hierarchy;

 /*****************************************************************
  * Name: process_dm_invoiced_cacs
  * Desc: This procedure pulls the distinct invoiced cacs from
  *       invoiced spend (dm_invoiced_spend_all)
  *       It also gets the hierarchy values for the cac info
  *       pulled and stores it in a temp table.
  *****************************************************************/
  PROCEDURE process_dm_invoiced_cacs(in_msg_id            IN number,
                                     id_last_process_date IN DATE,
                                     on_err_num          OUT number,
                                     ov_err_msg          OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_invoiced_cac_dim_process.process_dm_invoiced_cacs' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;

  BEGIN
    on_err_num := 0;
    ov_err_msg := null;
    --
    -- Insert into a temp table the distinct cac values from invoiced spend since the last process_date
    --
    BEGIN
      INSERT
        INTO dm_invoiced_cac_tmp
             (buyer_bus_org_fk,
              cac1_seg1_value,
              cac1_seg2_value,
              cac1_seg3_value,
              cac1_seg4_value,
              cac1_seg5_value,
              cac2_seg1_value,
              cac2_seg2_value,
              cac2_seg3_value,
              cac2_seg4_value,
              cac2_seg5_value
             )
      SELECT DISTINCT
             buyer_bus_org_fk,
	     cac1_seg1_value,
	     cac1_seg2_value,
	     cac1_seg3_value,
	     cac1_seg4_value,
	     cac1_seg5_value,
	     cac2_seg1_value,
	     cac2_seg2_value,
	     cac2_seg3_value,
	     cac2_seg4_value,
             cac2_seg5_value
        FROM dm_invoiced_spend_all
       WHERE last_update_date > id_last_process_date;

     --
     -- gather stats
     --
     DBMS_STATS.gather_table_stats(USER, 'DM_INVOICED_CAC_TMP');
     DBMS_STATS.gather_index_stats(USER, 'DM_INVOICED_CAC_TMP_N1');
     DBMS_STATS.gather_index_stats(USER, 'DM_INVOICED_CAC_TMP_N2');
     DBMS_STATS.gather_index_stats(USER, 'DM_INVOICED_CAC_TMP_N3');

    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable insert records into dm_invoiced_cac_tmp ! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
    END;

    --
    -- Insert into a temp table including hierarchy values
    --
    BEGIN
      INSERT
        INTO dm_invoiced_cac_dim_tmp
             (cac1_seg1_value,
              cac1_seg2_value,
              cac1_seg3_value,
              cac1_seg4_value,
              cac1_seg5_value,
              cac2_seg1_value,
              cac2_seg2_value,
              cac2_seg3_value,
              cac2_seg4_value,
              cac2_seg5_value,
              cac1_seg1_hlvl1_desc,
              cac1_seg1_hlvl2_desc,
              cac1_seg1_hlvl3_desc,
              cac1_seg1_hlvl4_desc,
              cac1_seg1_hlvl5_desc,
              cac1_seg1_hlvl6_desc,
              cac1_seg1_hlvl1_title,
              cac1_seg1_hlvl2_title,
              cac1_seg1_hlvl3_title,
              cac1_seg1_hlvl4_title,
              cac1_seg1_hlvl5_title,
              cac1_seg1_hlvl6_title,
              cac1_seg3_hlvl1_desc,
              cac1_seg3_hlvl2_desc,
              cac1_seg3_hlvl3_desc,
              cac1_seg3_hlvl4_desc,
              cac1_seg3_hlvl5_desc,
              cac1_seg3_hlvl6_desc,
              cac1_seg3_hlvl1_title,
              cac1_seg3_hlvl2_title,
              cac1_seg3_hlvl3_title,
              cac1_seg3_hlvl4_title,
              cac1_seg3_hlvl5_title,
              cac1_seg3_hlvl6_title,
              cac2_seg1_hlvl1_desc,
              cac2_seg1_hlvl2_desc,
              cac2_seg1_hlvl3_desc,
              cac2_seg1_hlvl4_desc,
              cac2_seg1_hlvl5_desc,
              cac2_seg1_hlvl6_desc,
              cac2_seg1_hlvl1_title,
              cac2_seg1_hlvl2_title,
              cac2_seg1_hlvl3_title,
              cac2_seg1_hlvl4_title,
              cac2_seg1_hlvl5_title,
              cac2_seg1_hlvl6_title,
              buyerorg_id
             )
      SELECT a.cac1_seg1_value,
             a.cac1_seg2_value ,
             a.cac1_seg3_value ,
             a.cac1_seg4_value ,
             a.cac1_seg5_value,
             a.cac2_seg1_value ,
             a.cac2_seg2_value ,
             a.cac2_seg3_value ,
             a.cac2_seg4_value ,
             a.cac2_seg5_value,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg1_value,0)  ELSE NULL END) cac1_seg1_lvl1_desc,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg1_value,1)  ELSE NULL END) cac1_seg1_lvl2_desc,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg1_value,2)  ELSE NULL END) cac1_seg1_lvl3_desc,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg1_value,3)  ELSE NULL END) cac1_seg1_lvl4_desc,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg1_value,4)  ELSE NULL END) cac1_seg1_lvl5_desc,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg1_value,5)  ELSE NULL END) cac1_seg1_lvl6_desc,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg1_value,0) ELSE NULL END) cac1_seg1_lvl1_title,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg1_value,1) ELSE NULL END) cac1_seg1_lvl2_title,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg1_value,2) ELSE NULL END) cac1_seg1_lvl3_title,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg1_value,3) ELSE NULL END) cac1_seg1_lvl4_title,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg1_value,4) ELSE NULL END) cac1_seg1_lvl5_title,
             (CASE WHEN a.cac1_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg1_value,5) ELSE NULL END) cac1_seg1_lvl6_title,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg3_value,0)  ELSE NULL END) cac1_seg3_lvl1_desc,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg3_value,1)  ELSE NULL END) cac1_seg3_lvl2_desc,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg3_value,2)  ELSE NULL END) cac1_seg3_lvl3_desc,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg3_value,3)  ELSE NULL END) cac1_seg3_lvl4_desc,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg3_value,4)  ELSE NULL END) cac1_seg3_lvl5_desc,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac1_seg3_value,5)  ELSE NULL END) cac1_seg3_lvl6_desc,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg3_value,0) ELSE NULL END) cac1_seg3_lvl1_title,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN Get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg3_value,1) ELSE NULL END) cac1_seg3_lvl2_title,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg3_value,2) ELSE NULL END) cac1_seg3_lvl3_title,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg3_value,3) ELSE NULL END) cac1_seg3_lvl4_title,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg3_value,4) ELSE NULL END) cac1_seg3_lvl5_title,
             (CASE WHEN a.cac1_seg3_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac1_seg3_value,5) ELSE NULL END) cac1_seg3_lvl6_title,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac2_seg1_value,0)  ELSE NULL END) cac2_seg1_lvl1_desc,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac2_seg1_value,1)  ELSE NULL END) cac2_seg1_lvl2_desc,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac2_seg1_value,2)  ELSE NULL END) cac2_seg1_lvl3_desc,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac2_seg1_value,3)  ELSE NULL END) cac2_seg1_lvl4_desc,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac2_seg1_value,4)  ELSE NULL END) cac2_seg1_lvl5_desc,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_desc(a.buyer_bus_org_fk,a.cac2_seg1_value,5)  ELSE NULL END) cac2_seg1_lvl6_desc,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac2_seg1_value,0) ELSE NULL END) cac2_seg1_lvl1_title,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac2_seg1_value,1) ELSE NULL END) cac2_seg1_lvl2_title,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac2_seg1_value,2) ELSE NULL END) cac2_seg1_lvl3_title,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac2_seg1_value,3) ELSE NULL END) cac2_seg1_lvl4_title,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac2_seg1_value,4) ELSE NULL END) cac2_seg1_lvl5_title,
             (CASE WHEN a.cac2_seg1_value IS NOT NULL THEN get_hlvl_title(a.buyer_bus_org_fk,a.cac2_seg1_value,5) ELSE NULL END) cac2_seg1_lvl6_title,
             a.buyer_bus_org_fk
        FROM dm_invoiced_cac_tmp a;

            --
            -- gather stats
            --
            DBMS_STATS.gather_table_stats(USER, 'DM_INVOICED_CAC_DIM_TMP');
            DBMS_STATS.gather_index_stats(USER, 'AK_DM_INVOICED_CAC_DIM_TMP');

    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable insert records into dm_invoiced_cac_dim_tmp ! ';
        lv_db_err_msg := SQLERRM;
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
  END process_dm_invoiced_cacs;

 /*****************************************************************
  * Name: populate_invoiced_cac_dim
  * Desc: This procedure is used to populate the invoice cac dim
  *       table and also invalidate any old records
  *
  *****************************************************************/
  PROCEDURE populate_invoiced_cac_dim(in_msg_id           IN number,
                                      iv_data_source_code IN varchar2,
                                      on_err_num         OUT number,
                                      ov_err_msg         OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_invoiced_cac_dim_process.populate_invoiced_cac_dim' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER;
    ln_cac_dim_id        NUMBER;
    ln_version_id        NUMBER;

    --
    -- cursor for the existing records
    --
    CURSOR cac_dim
    IS
    SELECT cac1_seg1_value,
           cac1_seg2_value,
           cac1_seg3_value,
           cac1_seg4_value,
           cac1_seg5_value,
           cac2_seg1_value,
           cac2_seg2_value,
           cac2_seg3_value,
           cac2_seg4_value,
           cac2_seg5_value,
           cac1_seg1_hlvl1_desc,
           cac1_seg1_hlvl2_desc,
           cac1_seg1_hlvl3_desc,
           cac1_seg1_hlvl4_desc,
           cac1_seg1_hlvl5_desc,
           cac1_seg1_hlvl6_desc,
           cac1_seg1_hlvl1_title,
           cac1_seg1_hlvl2_title,
           cac1_seg1_hlvl3_title,
           cac1_seg1_hlvl4_title,
           cac1_seg1_hlvl5_title,
           cac1_seg1_hlvl6_title,
           cac1_seg3_hlvl1_desc,
           cac1_seg3_hlvl2_desc,
           cac1_seg3_hlvl3_desc,
           cac1_seg3_hlvl4_desc,
           cac1_seg3_hlvl5_desc,
           cac1_seg3_hlvl6_desc,
           cac1_seg3_hlvl1_title,
           cac1_seg3_hlvl2_title,
           cac1_seg3_hlvl3_title,
           cac1_seg3_hlvl4_title,
           cac1_seg3_hlvl5_title,
           cac1_seg3_hlvl6_title,
           cac2_seg1_hlvl1_desc,
           cac2_seg1_hlvl2_desc,
           cac2_seg1_hlvl3_desc,
           cac2_seg1_hlvl4_desc,
           cac2_seg1_hlvl5_desc,
           cac2_seg1_hlvl6_desc,
           cac2_seg1_hlvl1_title,
           cac2_seg1_hlvl2_title,
           cac2_seg1_hlvl3_title,
           cac2_seg1_hlvl4_title,
           cac2_seg1_hlvl5_title,
           cac2_seg1_hlvl6_title,
           buyerorg_id
      FROM dm_invoiced_cac_dim_tmp
     WHERE EXISTS
           (SELECT 'X'
              FROM dm_invoiced_cac_dim di
             WHERE di.buyerorg_id               = dm_invoiced_cac_dim_tmp.buyerorg_id
               AND nvl(di.cac1_seg1_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg1_value,'x')
               AND nvl(di.cac1_seg2_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg2_value,'x')
               AND nvl(di.cac1_seg3_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg3_value,'x')
               AND nvl(di.cac1_seg4_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg4_value,'x')
               AND nvl(di.cac1_seg5_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg5_value,'x')
               AND nvl(di.cac2_seg1_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg1_value,'x')
               AND nvl(di.cac2_seg2_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg2_value,'x')
               AND nvl(di.cac2_seg3_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg3_value,'x')
               AND nvl(di.cac2_seg4_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg4_value,'x')
               AND nvl(di.cac2_seg5_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg5_value,'x'));

  BEGIN
    on_err_num := 0;
    ov_err_msg := null;
    --
    -- loop through the cursor and see any existing records are changed
    --
    FOR cac_dim_rec in cac_dim
    LOOP
      SELECT count(1)
        INTO ln_count
        FROM dm_invoiced_cac_dim
       WHERE buyerorg_id                     = cac_dim_rec.buyerorg_id
         AND nvl(cac1_seg1_value,'x')        = nvl(cac_dim_rec.cac1_seg1_value,'x')
         AND nvl(cac1_seg2_value,'x')        = nvl(cac_dim_rec.cac1_seg2_value,'x')
         AND nvl(cac1_seg3_value,'x')        = nvl(cac_dim_rec.cac1_seg3_value,'x')
         AND nvl(cac1_seg4_value,'x')        = nvl(cac_dim_rec.cac1_seg4_value,'x')
         AND nvl(cac1_seg5_value,'x')        = nvl(cac_dim_rec.cac1_seg5_value,'x')
         AND nvl(cac2_seg1_value,'x')        = nvl(cac_dim_rec.cac2_seg1_value,'x')
         AND nvl(cac2_seg2_value,'x')        = nvl(cac_dim_rec.cac2_seg2_value,'x')
         AND nvl(cac2_seg3_value,'x')        = nvl(cac_dim_rec.cac2_seg3_value,'x')
         AND nvl(cac2_seg4_value,'x')        = nvl(cac_dim_rec.cac2_seg4_value,'x')
         AND nvl(cac2_seg5_value,'x')        = nvl(cac_dim_rec.cac2_seg5_value,'x')
         AND nvl(cac1_seg1_hlvl1_desc, 'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl1_desc, 'x')
	 AND nvl(cac1_seg1_hlvl2_desc, 'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl2_desc, 'x')
	 AND nvl(cac1_seg1_hlvl3_desc, 'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl3_desc, 'x')
	 AND nvl(cac1_seg1_hlvl4_desc, 'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl4_desc, 'x')
	 AND nvl(cac1_seg1_hlvl5_desc, 'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl5_desc, 'x')
	 AND nvl(cac1_seg1_hlvl6_desc, 'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl6_desc, 'x')
	 AND nvl(cac1_seg1_hlvl1_title,'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl1_title,'x')
	 AND nvl(cac1_seg1_hlvl2_title,'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl2_title,'x')
	 AND nvl(cac1_seg1_hlvl3_title,'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl3_title,'x')
	 AND nvl(cac1_seg1_hlvl4_title,'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl4_title,'x')
	 AND nvl(cac1_seg1_hlvl5_title,'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl5_title,'x')
	 AND nvl(cac1_seg1_hlvl6_title,'x')  = nvl(cac_dim_rec.cac1_seg1_hlvl6_title,'x')
	 AND nvl(cac1_seg3_hlvl1_desc, 'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl1_desc, 'x')
	 AND nvl(cac1_seg3_hlvl2_desc, 'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl2_desc, 'x')
	 AND nvl(cac1_seg3_hlvl3_desc, 'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl3_desc, 'x')
	 AND nvl(cac1_seg3_hlvl4_desc, 'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl4_desc, 'x')
	 AND nvl(cac1_seg3_hlvl5_desc, 'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl5_desc, 'x')
	 AND nvl(cac1_seg3_hlvl6_desc, 'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl6_desc, 'x')
	 AND nvl(cac1_seg3_hlvl1_title,'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl1_title,'x')
	 AND nvl(cac1_seg3_hlvl2_title,'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl2_title,'x')
	 AND nvl(cac1_seg3_hlvl3_title,'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl3_title,'x')
	 AND nvl(cac1_seg3_hlvl4_title,'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl4_title,'x')
	 AND nvl(cac1_seg3_hlvl5_title,'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl5_title,'x')
	 AND nvl(cac1_seg3_hlvl6_title,'x')  = nvl(cac_dim_rec.cac1_seg3_hlvl6_title,'x')
	 AND nvl(cac2_seg1_hlvl1_desc, 'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl1_desc, 'x')
	 AND nvl(cac2_seg1_hlvl2_desc, 'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl2_desc, 'x')
	 AND nvl(cac2_seg1_hlvl3_desc, 'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl3_desc, 'x')
	 AND nvl(cac2_seg1_hlvl4_desc, 'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl4_desc, 'x')
	 AND nvl(cac2_seg1_hlvl5_desc, 'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl5_desc, 'x')
	 AND nvl(cac2_seg1_hlvl6_desc, 'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl6_desc, 'x')
	 AND nvl(cac2_seg1_hlvl1_title,'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl1_title,'x')
	 AND nvl(cac2_seg1_hlvl2_title,'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl2_title,'x')
	 AND nvl(cac2_seg1_hlvl3_title,'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl3_title,'x')
	 AND nvl(cac2_seg1_hlvl4_title,'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl4_title,'x')
	 AND nvl(cac2_seg1_hlvl5_title,'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl5_title,'x')
         AND nvl(cac2_seg1_hlvl6_title,'x')  = nvl(cac_dim_rec.cac2_seg1_hlvl6_title,'x');

      IF ln_count = 0 THEN -- this means description/title is changed. so, update the old record as invalid and  insert new record

         ln_version_id := 0;

         UPDATE dm_invoiced_cac_dim
            SET
                is_effective     = 'N',
                valid_to_date    = sysdate,
                last_update_date = sysdate
          WHERE buyerorg_id               = cac_dim_rec.buyerorg_id
	    AND nvl(cac1_seg1_value,'x')  = nvl(cac_dim_rec.cac1_seg1_value,'x')
	    AND nvl(cac1_seg2_value,'x')  = nvl(cac_dim_rec.cac1_seg2_value,'x')
	    AND nvl(cac1_seg3_value,'x')  = nvl(cac_dim_rec.cac1_seg3_value,'x')
	    AND nvl(cac1_seg4_value,'x')  = nvl(cac_dim_rec.cac1_seg4_value,'x')
	    AND nvl(cac1_seg5_value,'x')  = nvl(cac_dim_rec.cac1_seg5_value,'x')
	    AND nvl(cac2_seg1_value,'x')  = nvl(cac_dim_rec.cac2_seg1_value,'x')
	    AND nvl(cac2_seg2_value,'x')  = nvl(cac_dim_rec.cac2_seg2_value,'x')
	    AND nvl(cac2_seg3_value,'x')  = nvl(cac_dim_rec.cac2_seg3_value,'x')
	    AND nvl(cac2_seg4_value,'x')  = nvl(cac_dim_rec.cac2_seg4_value,'x')
            AND nvl(cac2_seg5_value,'x')  = nvl(cac_dim_rec.cac2_seg5_value,'x')
            AND is_effective     = 'Y'
          RETURNING version_id INTO ln_version_id;

        BEGIN

         SELECT dm_invoiced_cac_dim_seq.NEXTVAL
           INTO ln_cac_dim_id
           FROM dual;

         INSERT
           INTO dm_invoiced_cac_dim
                (inv_cac_dim_id,
                 version_id,
                 data_source_code,
                 cac1_seg1_value,
                 cac1_seg2_value,
                 cac1_seg3_value,
                 cac1_seg4_value,
                 cac1_seg5_value,
                 cac2_seg1_value,
                 cac2_seg2_value,
                 cac2_seg3_value,
                 cac2_seg4_value,
                 cac2_seg5_value,
                 cac1_seg1_hlvl1_desc,
                 cac1_seg1_hlvl2_desc,
                 cac1_seg1_hlvl3_desc,
                 cac1_seg1_hlvl4_desc,
                 cac1_seg1_hlvl5_desc,
                 cac1_seg1_hlvl6_desc,
                 cac1_seg1_hlvl1_title,
                 cac1_seg1_hlvl2_title,
                 cac1_seg1_hlvl3_title,
                 cac1_seg1_hlvl4_title,
                 cac1_seg1_hlvl5_title,
                 cac1_seg1_hlvl6_title,
                 cac1_seg3_hlvl1_desc,
                 cac1_seg3_hlvl2_desc,
                 cac1_seg3_hlvl3_desc,
                 cac1_seg3_hlvl4_desc,
                 cac1_seg3_hlvl5_desc,
                 cac1_seg3_hlvl6_desc,
                 cac1_seg3_hlvl1_title,
                 cac1_seg3_hlvl2_title,
                 cac1_seg3_hlvl3_title,
                 cac1_seg3_hlvl4_title,
                 cac1_seg3_hlvl5_title,
                 cac1_seg3_hlvl6_title,
                 cac2_seg1_hlvl1_desc,
                 cac2_seg1_hlvl2_desc,
                 cac2_seg1_hlvl3_desc,
                 cac2_seg1_hlvl4_desc,
                 cac2_seg1_hlvl5_desc,
                 cac2_seg1_hlvl6_desc,
                 cac2_seg1_hlvl1_title,
                 cac2_seg1_hlvl2_title,
                 cac2_seg1_hlvl3_title,
                 cac2_seg1_hlvl4_title,
                 cac2_seg1_hlvl5_title,
                 cac2_seg1_hlvl6_title,
                 buyerorg_id,
                 is_effective,
                 valid_from_date,
                 valid_to_date,
                 batch_id,
                 last_update_date
                )
         VALUES (ln_cac_dim_id,
                 ln_version_id +1,
                 iv_data_source_code,
                 cac_dim_rec.cac1_seg1_value,
                 cac_dim_rec.cac1_seg2_value,
                 cac_dim_rec.cac1_seg3_value,
                 cac_dim_rec.cac1_seg4_value,
                 cac_dim_rec.cac1_seg5_value,
                 cac_dim_rec.cac2_seg1_value,
                 cac_dim_rec.cac2_seg2_value,
                 cac_dim_rec.cac2_seg3_value,
                 cac_dim_rec.cac2_seg4_value,
                 cac_dim_rec.cac2_seg5_value,
                 cac_dim_rec.cac1_seg1_hlvl1_desc,
                 cac_dim_rec.cac1_seg1_hlvl2_desc,
                 cac_dim_rec.cac1_seg1_hlvl3_desc,
                 cac_dim_rec.cac1_seg1_hlvl4_desc,
                 cac_dim_rec.cac1_seg1_hlvl5_desc,
                 cac_dim_rec.cac1_seg1_hlvl6_desc,
                 cac_dim_rec.cac1_seg1_hlvl1_title,
                 cac_dim_rec.cac1_seg1_hlvl2_title,
                 cac_dim_rec.cac1_seg1_hlvl3_title,
                 cac_dim_rec.cac1_seg1_hlvl4_title,
                 cac_dim_rec.cac1_seg1_hlvl5_title,
                 cac_dim_rec.cac1_seg1_hlvl6_title,
                 cac_dim_rec.cac1_seg3_hlvl1_desc,
                 cac_dim_rec.cac1_seg3_hlvl2_desc,
                 cac_dim_rec.cac1_seg3_hlvl3_desc,
                 cac_dim_rec.cac1_seg3_hlvl4_desc,
                 cac_dim_rec.cac1_seg3_hlvl5_desc,
                 cac_dim_rec.cac1_seg3_hlvl6_desc,
                 cac_dim_rec.cac1_seg3_hlvl1_title,
                 cac_dim_rec.cac1_seg3_hlvl2_title,
                 cac_dim_rec.cac1_seg3_hlvl3_title,
                 cac_dim_rec.cac1_seg3_hlvl4_title,
                 cac_dim_rec.cac1_seg3_hlvl5_title,
                 cac_dim_rec.cac1_seg3_hlvl6_title,
                 cac_dim_rec.cac2_seg1_hlvl1_desc,
                 cac_dim_rec.cac2_seg1_hlvl2_desc,
                 cac_dim_rec.cac2_seg1_hlvl3_desc,
                 cac_dim_rec.cac2_seg1_hlvl4_desc,
                 cac_dim_rec.cac2_seg1_hlvl5_desc,
                 cac_dim_rec.cac2_seg1_hlvl6_desc,
                 cac_dim_rec.cac2_seg1_hlvl1_title,
                 cac_dim_rec.cac2_seg1_hlvl2_title,
                 cac_dim_rec.cac2_seg1_hlvl3_title,
                 cac_dim_rec.cac2_seg1_hlvl4_title,
                 cac_dim_rec.cac2_seg1_hlvl5_title,
                 cac_dim_rec.cac2_seg1_hlvl6_title,
                 cac_dim_rec.buyerorg_id,
                 'Y',
                 sysdate,
                 null,
                 in_msg_id,
                 sysdate
                );
        EXCEPTION
          WHEN OTHERS THEN
            lv_app_err_msg := 'Unable insert records into dm_invoiced_cac_dim ! ';
            lv_db_err_msg := SQLERRM;
            RAISE le_exception;
        END;

      END IF;
    END LOOP;

    --
    -- insert new records
    --
    BEGIN
         INSERT
           INTO dm_invoiced_cac_dim
                (inv_cac_dim_id,
                 version_id,
                 data_source_code,
                 cac1_seg1_value,
                 cac1_seg2_value,
                 cac1_seg3_value,
                 cac1_seg4_value,
                 cac1_seg5_value,
                 cac2_seg1_value,
                 cac2_seg2_value,
                 cac2_seg3_value,
                 cac2_seg4_value,
                 cac2_seg5_value,
                 cac1_seg1_hlvl1_desc,
                 cac1_seg1_hlvl2_desc,
                 cac1_seg1_hlvl3_desc,
                 cac1_seg1_hlvl4_desc,
                 cac1_seg1_hlvl5_desc,
                 cac1_seg1_hlvl6_desc,
                 cac1_seg1_hlvl1_title,
                 cac1_seg1_hlvl2_title,
                 cac1_seg1_hlvl3_title,
                 cac1_seg1_hlvl4_title,
                 cac1_seg1_hlvl5_title,
                 cac1_seg1_hlvl6_title,
                 cac1_seg3_hlvl1_desc,
                 cac1_seg3_hlvl2_desc,
                 cac1_seg3_hlvl3_desc,
                 cac1_seg3_hlvl4_desc,
                 cac1_seg3_hlvl5_desc,
                 cac1_seg3_hlvl6_desc,
                 cac1_seg3_hlvl1_title,
                 cac1_seg3_hlvl2_title,
                 cac1_seg3_hlvl3_title,
                 cac1_seg3_hlvl4_title,
                 cac1_seg3_hlvl5_title,
                 cac1_seg3_hlvl6_title,
                 cac2_seg1_hlvl1_desc,
                 cac2_seg1_hlvl2_desc,
                 cac2_seg1_hlvl3_desc,
                 cac2_seg1_hlvl4_desc,
                 cac2_seg1_hlvl5_desc,
                 cac2_seg1_hlvl6_desc,
                 cac2_seg1_hlvl1_title,
                 cac2_seg1_hlvl2_title,
                 cac2_seg1_hlvl3_title,
                 cac2_seg1_hlvl4_title,
                 cac2_seg1_hlvl5_title,
                 cac2_seg1_hlvl6_title,
                 buyerorg_id,
                 is_effective,
                 valid_from_date,
                 valid_to_date,
                 batch_id,
                 last_update_date
                )
         SELECT  dm_invoiced_cac_dim_seq.NEXTVAL,
                 1,
                 iv_data_source_code,
                 cac1_seg1_value,
                 cac1_seg2_value,
                 cac1_seg3_value,
                 cac1_seg4_value,
                 cac1_seg5_value,
                 cac2_seg1_value,
                 cac2_seg2_value,
                 cac2_seg3_value,
                 cac2_seg4_value,
                 cac2_seg5_value,
                 cac1_seg1_hlvl1_desc,
                 cac1_seg1_hlvl2_desc,
                 cac1_seg1_hlvl3_desc,
                 cac1_seg1_hlvl4_desc,
                 cac1_seg1_hlvl5_desc,
                 cac1_seg1_hlvl6_desc,
                 cac1_seg1_hlvl1_title,
                 cac1_seg1_hlvl2_title,
                 cac1_seg1_hlvl3_title,
                 cac1_seg1_hlvl4_title,
                 cac1_seg1_hlvl5_title,
                 cac1_seg1_hlvl6_title,
                 cac1_seg3_hlvl1_desc,
                 cac1_seg3_hlvl2_desc,
                 cac1_seg3_hlvl3_desc,
                 cac1_seg3_hlvl4_desc,
                 cac1_seg3_hlvl5_desc,
                 cac1_seg3_hlvl6_desc,
                 cac1_seg3_hlvl1_title,
                 cac1_seg3_hlvl2_title,
                 cac1_seg3_hlvl3_title,
                 cac1_seg3_hlvl4_title,
                 cac1_seg3_hlvl5_title,
                 cac1_seg3_hlvl6_title,
                 cac2_seg1_hlvl1_desc,
                 cac2_seg1_hlvl2_desc,
                 cac2_seg1_hlvl3_desc,
                 cac2_seg1_hlvl4_desc,
                 cac2_seg1_hlvl5_desc,
                 cac2_seg1_hlvl6_desc,
                 cac2_seg1_hlvl1_title,
                 cac2_seg1_hlvl2_title,
                 cac2_seg1_hlvl3_title,
                 cac2_seg1_hlvl4_title,
                 cac2_seg1_hlvl5_title,
                 cac2_seg1_hlvl6_title,
                 buyerorg_id,
                 'Y',
                 sysdate,
                 null,
                 in_msg_id,
                 sysdate
            FROM dm_invoiced_cac_dim_tmp
           WHERE NOT EXISTS
                 (SELECT 'X'
                    FROM dm_invoiced_cac_dim di
                   WHERE di.buyerorg_id               = dm_invoiced_cac_dim_tmp.buyerorg_id
                     AND nvl(di.cac1_seg1_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg1_value,'x')
                     AND nvl(di.cac1_seg2_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg2_value,'x')
                     AND nvl(di.cac1_seg3_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg3_value,'x')
                     AND nvl(di.cac1_seg4_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg4_value,'x')
                     AND nvl(di.cac1_seg5_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac1_seg5_value,'x')
                     AND nvl(di.cac2_seg1_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg1_value,'x')
                     AND nvl(di.cac2_seg2_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg2_value,'x')
                     AND nvl(di.cac2_seg3_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg3_value,'x')
                     AND nvl(di.cac2_seg4_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg4_value,'x')
                     AND nvl(di.cac2_seg5_value,'x')  = nvl(dm_invoiced_cac_dim_tmp.cac2_seg5_value,'x'));


    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable insert records into dm_invoiced_cac_dim ! ';
        lv_db_err_msg := SQLERRM;
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
  END populate_invoiced_cac_dim;
 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the CAC information from
  *       data mart as well as Front office
  ****************************************************************/
  PROCEDURE p_main(iv_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
  IS
    ln_msg_id            NUMBER;
    ln_count             NUMBER;
    ln_process_cnt       NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(4000)  := NULL;
    gv_proc_name         VARCHAR2(100)   := 'DM_INVOICED_CAC_DIM_PROCESS.p_main' ;
    gv_app_err_msg       VARCHAR2(2000)  := NULL;
    gv_db_err_msg        VARCHAR2(2000)  := NULL;
    ge_exception         EXCEPTION;
    ln_err               NUMBER;
    fo_ln_count          NUMBER;
    bo_ln_count          NUMBER;
    ld_last_process_date DATE;

  BEGIN

 dm_cube_utils.make_indexes_visible;
     --
     -- Get the sequence reuired for logging messages
     --
     BEGIN
       SELECT DM_MSG_LOG_SEQ.nextval
         INTO ln_msg_id
         FROM dual;
     END;

     SELECT last_update_date
       INTO ld_last_process_date
       FROM dm_cube_objects
      WHERE object_name = 'DM_INVOICED_CAC_DIM';

     --
     -- truncate tables
     --
     BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_fo_cac_hierarchy_tmp';
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_invoiced_cac_tmp';
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_invoiced_cac_dim_tmp';
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to trunacte work tables for invoiced cac dims!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     BEGIN
            bus_org_lineage_upd(ln_msg_id,ln_err_num,lv_err_msg);
     EXCEPTION
            WHEN OTHERS THEN
                 gv_app_err_msg := 'Unable to execute the procedure to process Business org lineage!';
                 gv_db_err_msg := SQLERRM;
                 RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'DM_INVOICED_CAC_DIM_PROCESS',gv_proc_name,'I'); -- log the start of main process

     --
     -- Step 1 : Process the FO hierarchy
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Process the FO hierarchy',gv_proc_name,'I');
     BEGIN
       process_fo_hierarchy(ln_msg_id,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process FO hierarchy!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --
     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to process FO hierarchy!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

     --
     -- Step 2 : Process the Invoiced cac from data mart
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Process the Invoiced cac from data mart',gv_proc_name,'I');
     BEGIN
       process_dm_invoiced_cacs(ln_msg_id,ld_last_process_date,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process invoiced cacs fom data mart!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --
     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to process invoiced cacs fom data mart!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

     --
     -- Step 3 : Populate the invoiced cac dim tables
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,4,'Populate the invoiced cac dim tables',gv_proc_name,'I');
     BEGIN
       populate_invoiced_cac_dim(ln_msg_id,iv_data_source_code,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to populate the invoiced cac dim!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --
     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to populate the invoiced cac dim!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,4,null,null,'U');

     --
     -- Step 4: Update the cube objects for last process date
     --
     UPDATE dm_cube_objects
        SET last_update_date = sysdate
      WHERE object_name = 'DM_INVOICED_CAC_DIM';

     Commit;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');
     
     DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICED_CAC_DIM',
                                        iv_data_source_code,
                                        'SPEND_CUBE-DIM',
                                        'COMPLETED',
                                        p_date_id);

  EXCEPTION
      WHEN ge_exception THEN
           --
           -- user defined exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'DM_INVOICED_CAC_DIM_PROCESS-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
            ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);
     DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICED_CAC_DIM',
                                        iv_data_source_code,
                                        'SPEND_CUBE-DIM',
                                        'FAILED',
                                        p_date_id);


      WHEN OTHERS THEN
           --
           -- Unknown exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'DM_INVOICED_CAC_DIM_PROCESS-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           gv_app_err_msg := 'Unknown Error !';
           gv_db_err_msg  := SQLERRM;
           ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                        gv_app_err_msg,
                                                        gv_db_err_msg,
                                                        gv_proc_name);
     DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICED_CAC_DIM',
                                        iv_data_source_code,
                                        'SPEND_CUBE-DIM',
                                        'FAILED',
                                        p_date_id);
                                                        
  END p_main;


END dm_invoiced_cac_dim_process;
/