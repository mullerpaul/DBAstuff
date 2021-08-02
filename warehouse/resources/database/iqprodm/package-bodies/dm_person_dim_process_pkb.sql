CREATE OR REPLACE PACKAGE BODY dm_person_dim_process AS
/******************************************************************************
 * Name   : FO_DM_PERSON_DIM_PROCESS
 * Desc   : This package contains all the procedures required to
 *          migrate/process persons data.
 *
 * Source : Front office and Data mart ( person_snapshot )
 *
 * Name          Date         Version     Details
 * ----------------------------------------------------------------------------
 * jpullifrone   01/7/2016    1.1         Procedure, process_upd_records.  Moved
 *                                        EXIT WHEN person_dim_cur%NOTFOUND from
 *                                        end of loop to beginning of loop.
 *                                        IQN-29795 
 * smeriweather  07/15/2010   Initial
 *****************************************************************************/

   g_pkg_name              VARCHAR2(35)         := 'DM_PERSON_DIM_PROCESS';
   g_curr_schema           VARCHAR2(30)         := sys_context('USERENV','CURRENT_SCHEMA');
   g_err_msg               VARCHAR2(2000)       := NULL;
   g_log_msg               VARCHAR2(2000)       := NULL;
   g_app_err_msg           VARCHAR2(2000)       := NULL;
   g_db_err_msg            VARCHAR2(2000)       := NULL;
   g_dbg_mode              VARCHAR2(1);

   c_tab                   VARCHAR2(2)          := CHR(9);
   c_crlf                  VARCHAR2(2)          := CHR(10);
   c_space                 VARCHAR2(2)          := CHR(32);
   c_delim                 VARCHAR2(1)          := ',';

   DBG_0_LVL               CONSTANT PLS_INTEGER := 0;
   DBG_1_LVL               CONSTANT PLS_INTEGER := 1;
   DBG_2_LVL               CONSTANT PLS_INTEGER := 2;

   g_msg_id                NUMBER;
   g_offset_limit          NUMBER               := 100000;
   g_last_process_date     DATE                 := TO_DATE('01-JAN-1999','DD-MON-YYYY');


   -- Setup pragma exception_init
   g_exception             EXCEPTION;
   pragma                  exception_init(g_exception, -20001);

   TYPE version_rectyp IS RECORD
     (person_id           dm_person_dim.person_id%TYPE
     ,version_id          dm_person_dim.version_id%TYPE);

   TYPE version_dim_tabtyp IS TABLE OF version_rectyp
     INDEX BY PLS_INTEGER;
   TYPE person_tmp_tabtyp IS TABLE OF dm_person_tmp%ROWTYPE
     INDEX BY PLS_INTEGER;
   TYPE person_dim_tabtyp IS TABLE OF dm_person_dim%ROWTYPE
     INDEX BY PLS_INTEGER;

   TYPE number_tabtyp IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

   -- Forward Declarations --

   PROCEDURE load_dm_person_tmp
     (in_data_source_code IN VARCHAR2
     ,in_last_identifier  IN NUMBER
     ,in_new_identifier   IN NUMBER);

   PROCEDURE process_person_dim
     (in_data_source_code IN VARCHAR2
     ,in_last_identifier  IN NUMBER
     ,in_remove_dups      IN VARCHAR2 DEFAULT 'Y'
     ,in_verify_eff_date  IN VARCHAR2 DEFAULT 'Y');

   PROCEDURE remove_duplicates (in_data_source_code IN VARCHAR2);
   PROCEDURE verify_eff_date (in_data_source_code IN VARCHAR2);
   PROCEDURE process_new_records (in_data_source_code IN VARCHAR2);
   PROCEDURE process_upd_records (in_data_source_code IN VARCHAR2);

   ---------------------------------------------------------------------------
   -- Function Name  : get_person_dim_id
   -- Description    : returns person dimension id
   ---------------------------------------------------------------------------
   FUNCTION get_person_dim_id
     (in_person_id        IN NUMBER
     ,in_invoice_date     IN DATE
     ,in_data_source_code IN VARCHAR2)
   RETURN NUMBER
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.get_person_dim_id';
     ln_person_dim_id     NUMBER;
   BEGIN
     BEGIN
       SELECT person_dim_id INTO ln_person_dim_id
         FROM dm_person_dim
        WHERE person_id = in_person_id
          AND data_source_code = in_data_source_code
          AND in_invoice_date BETWEEN valid_from_date AND NVL(valid_to_date,in_invoice_date);
     EXCEPTION
       WHEN OTHERS THEN
         ln_person_dim_id := 0;
     END;

     RETURN ln_person_dim_id;

   END get_person_dim_id;

   ---------------------------------------------------------------------------
   -- Procedure Name : load_dm_person_tmp
   -- Description    : Procedure to load person table dm_person_tmp
   ---------------------------------------------------------------------------
   PROCEDURE load_dm_person_tmp
     (in_data_source_code IN VARCHAR2
     ,in_last_identifier  IN NUMBER
     ,in_new_identifier   IN NUMBER)
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.load_dm_person_tmp' ;
     ln_fo_count          NUMBER;
     le_exception         EXCEPTION;
     ln_min_id            NUMBER;
     ln_max_id            NUMBER;
     lb_initial_load      BOOLEAN;
   BEGIN

     IF in_last_identifier = 0 THEN
        lb_initial_load := TRUE;
     ELSE
        lb_initial_load := FALSE;
     END IF;

     IF lb_initial_load THEN
        ln_min_id := 0;
     ELSE
        ln_min_id := in_last_identifier;

     END IF;

     ln_max_id := in_new_identifier;

     INSERT INTO dm_person_tmp
           (DATA_SOURCE_CODE
           ,PERSON_ID
           ,PERSON_SNAPSHOT_ID
           ,PERSON_TYPE
           ,FIRST_NAME
           ,LAST_NAME
           ,MIDDLE_NAME
           ,ORG_ID
           ,DIM_RECORD_TYPE
           ,CREATION_DATE
           ,VALID_TO_DATE)
     SELECT in_data_source_code as data_source_code
           ,ps.person_fk
           ,ps.person_snapshot_id
           ,fr.firm_type
           ,ps.first_name
           ,ps.last_name
           ,ps.middle_name
           ,p.business_organization_fk as org_id
           ,'L' as dim_record_type
           ,ps.creation_date
           ,ps.valid_to_date
       FROM person_snapshot@FO_R ps
           ,person@FO_R p
           ,firm_role@FO_R fr
      WHERE ps.person_fk IS NOT NULL
        AND p.person_id = ps.person_fk +0
        AND fr.business_org_fk = p.business_organization_fk
        AND fr.firm_type IN ('D','S')
        AND ps.person_snapshot_id > ln_min_id
        AND ps.person_snapshot_id <= ln_max_id;

     ln_fo_count := SQL%ROWCOUNT;
     COMMIT;

     --
     -- gather stats
     --
     DBMS_STATS.gather_table_stats(g_curr_schema, 'DM_PERSON_TMP');
     DBMS_STATS.gather_index_stats(g_curr_schema, 'DM_PERSON_TMP_NDX1');
     DBMS_STATS.gather_index_stats(g_curr_schema, 'DM_PERSON_TMP_NDX2');
     DBMS_STATS.gather_index_stats(g_curr_schema, 'DM_PERSON_TMP_NDX3');

     g_log_msg := 'Added '||ln_fo_count||' to dm_person_tmp';
   

   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := 'Unable to load dm_person_tmp table !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END load_dm_person_tmp;

   ---------------------------------------------------------------------------
   -- Procedure Name : process_person_dim
   -- Description    : process person dim records
   ---------------------------------------------------------------------------
   PROCEDURE process_person_dim
     (in_data_source_code IN VARCHAR2
     ,in_last_identifier  IN NUMBER
     ,in_remove_dups      IN VARCHAR2 DEFAULT 'Y'
     ,in_verify_eff_date  IN VARCHAR2 DEFAULT 'Y')
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.process_person_dim';
     ln_insert_count      NUMBER;
     ln_update_count      NUMBER;
     lb_initial_load      BOOLEAN;
   BEGIN

     IF in_last_identifier = 0 THEN
        lb_initial_load := TRUE;
     ELSE
        lb_initial_load := FALSE;
     END IF;

     -- Perform data scrub activities
     IF in_remove_dups = 'Y' THEN
        remove_duplicates(in_data_source_code);
     END IF;

     IF in_verify_eff_date = 'Y' THEN
        verify_eff_date(in_data_source_code);
     END IF;


     IF NOT lb_initial_load THEN
        -- Check for new records
        UPDATE /*+ index(t dm_person_tmp_ndx1) */ dm_person_tmp t
           SET dim_record_type = 'I'
         WHERE data_source_code = in_data_source_code
           AND NOT EXISTS (SELECT null
                             FROM dm_person_dim d
                            WHERE d.data_source_code = t.data_source_code
                              AND d.person_id        = t.person_id);

        ln_insert_count := SQL%ROWCOUNT;

        -- Set remaining records to 'U' for updating
        UPDATE dm_person_tmp t
           SET dim_record_type = 'U'
         WHERE dim_record_type <> 'I';

        ln_update_count := SQL%ROWCOUNT;

         COMMIT;

     END IF;

     -- Load new records
     IF lb_initial_load OR ln_insert_count > 0 THEN
        process_new_records(in_data_source_code);
     END IF;

     -- Update existing records
     IF ln_update_count > 0 THEN
        process_upd_records(in_data_source_code);
     END IF;

   END process_person_dim;

   ---------------------------------------------------------------------------
   -- Procedure Name : remove_duplicates
   -- Description    : Remove duplicate records that primarily exists because
   --                  the dimension load omits email address.
   ---------------------------------------------------------------------------
   PROCEDURE remove_duplicates (in_data_source_code IN VARCHAR2)
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.remove_duplicates' ;
     ln_delete_cnt        NUMBER;
     ln_dtotal_cnt        NUMBER;
     ln_min_id            NUMBER;
     ln_max_id            NUMBER;
     ln_last_id           NUMBER;
     ln_offset            NUMBER := 100000;

     TYPE numeric_tabtyp IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
     person_tab        numeric_tabtyp;
     snapshot_tab      numeric_tabtyp;
     person_tmp_tab    person_tmp_tabtyp;

     CURSOR tmp_cur (c_min_id IN NUMBER
                    ,c_offset IN NUMBER
                    ,c_data_source_code IN VARCHAR2)
     IS
     SELECT /*+ index(t dm_person_tmp_ndx1) */ t.*
       FROM dm_person_tmp t
           ,(SELECT person_id
                 FROM (SELECT DISTINCT  person_id
                       FROM dm_person_tmp
                      WHERE data_source_code = c_data_source_code
                        AND person_id > c_min_id
                      ORDER BY person_id)
              WHERE rownum < c_offset + 1) p
      WHERE t.data_source_code = c_data_source_code
        AND p.person_id +0 = t.person_id
      ORDER BY t.person_id;

   BEGIN

     -- Always Initialize min_id to zero
     ln_min_id := 0;

     -- Set max person_id as last_id because min,max will be used to iterate through the table
     SELECT max(person_id) INTO ln_last_id FROM dm_person_tmp;

     WHILE (ln_min_id < ln_last_id) LOOP

        OPEN tmp_cur(ln_min_id,ln_offset,in_data_source_code);
        LOOP
            FETCH tmp_cur BULK COLLECT INTO person_tmp_tab;

            -- Grab min and max person_id to serve as iterators to loop through and find dups
            ln_min_id := person_tmp_tab(person_tmp_tab.FIRST).person_id;
            ln_max_id := person_tmp_tab(person_tmp_tab.LAST).person_id;

            -- Use max and min and determine if any dup recs exists within that range
            DELETE FROM dm_person_tmp
             WHERE person_snapshot_id
                IN (SELECT person_snapshot_id
                      FROM ( SELECT /*+ index(t dm_person_tmp_ndx1) */
                                    t.person_id
                                   ,t.person_snapshot_id
                                   ,t.creation_date
                                   ,t.valid_to_date
                                   ,row_number() OVER (PARTITION BY t.person_id
                                                                   ,t.creation_date
                                                                   ,t.valid_to_date
                                                           ORDER BY t.person_id
                                                                   ,t.person_snapshot_id DESC
                                    ) as dup_count
                               FROM dm_person_tmp t
                              WHERE t.data_source_code = in_data_source_code
                                AND t.person_id >= ln_min_id
                                AND t.person_id <  ln_max_id
                              ORDER BY t.person_id
                           )
                     WHERE dup_count > 1
                   );

            ln_delete_cnt := SQL%ROWCOUNT;
            ln_dtotal_cnt := NVL(ln_dtotal_cnt,0) + ln_delete_cnt;
            COMMIT;

            -- Now set min_id equal to max_id to continue to move through tmp_cur
            ln_min_id := ln_max_id;

            EXIT WHEN tmp_cur%NOTFOUND;
        END LOOP; -- tmp_cur loop
        CLOSE tmp_cur;

     END LOOP;

     IF g_dbg_mode = 'Y' THEN
        g_log_msg := 'Total '||ln_dtotal_cnt||' duplicate records removed from dm_person_tmp';
     END IF;

     COMMIT;

   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := 'Unable to remove duplicates from dm_person_tmp table !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END remove_duplicates;

   ---------------------------------------------------------------------------
   -- Procedure Name : verify_eff_date
   -- Description    : Use lead() function to backfill valid_to_date in the
   --                  event that it's null and not the last record
   ---------------------------------------------------------------------------
   PROCEDURE verify_eff_date (in_data_source_code IN VARCHAR2)
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.verify_eff_date';
     ln_min_id            NUMBER;
     ln_max_id            NUMBER;
     ln_offset            NUMBER := 20000;
     ln_eff_cnt           NUMBER;

     -- example person_id (92672) from production
     -- as of 20100908 127601 person_id records exists w/ multiple

     CURSOR eff_cur(c_data_source_code IN VARCHAR2) IS
     select * from dm_person_cur_tmp
     WHERE data_source_code = c_data_source_code;

     CURSOR person_cur(c_data_source_code IN VARCHAR2
                      ,c_person_id in number) IS
     SELECT person_id
           ,person_snapshot_id
           ,creation_date
           ,valid_to_date
           ,LEAD(creation_date,1,NULL) OVER (PARTITION BY person_id
                                                 ORDER BY person_id
                                                         ,creation_date
            ) AS replace_valid_to_date
       FROM dm_person_tmp
      WHERE data_source_code = c_data_source_code
        AND person_id = c_person_id
      ORDER BY person_id,person_snapshot_id;

   BEGIN

   EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_person_cur_tmp';

     INSERT
       INTO dm_person_cur_tmp
       SELECT person_id,data_source_code,count(*)
              FROM dm_person_tmp
             WHERE valid_to_date IS NULL
             GROUP BY person_id,data_source_code
     HAVING count(*) > 1;

     IF g_dbg_mode = 'Y' THEN
        g_log_msg := 'Backfill null valid_to_date records';
     END IF;

     FOR eff_rec IN eff_cur(in_data_source_code)
     LOOP
        FOR person_rec IN person_cur(in_data_source_code,eff_rec.person_id)
        LOOP
           IF person_rec.valid_to_date IS NULL AND
              person_rec.replace_valid_to_date IS NOT NULL
           THEN
              ln_eff_cnt := NVL(ln_eff_cnt,0) + 1;
              UPDATE dm_person_tmp
                 SET valid_to_date = person_rec.replace_valid_to_date
               WHERE data_source_code = in_data_source_code
                 AND person_snapshot_id = person_rec.person_snapshot_id;
           END IF;
        END LOOP;
     END LOOP;

     COMMIT;

     IF g_dbg_mode = 'Y' THEN
        g_log_msg := 'Total '||ln_eff_cnt||' records corrected for valid_to_date in dm_person_tmp';
     END IF;

   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := 'Unable to cleanup valid_to_date in dm_person_tmp table !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END verify_eff_date;

   ---------------------------------------------------------------------------
   -- Procedure Name : process_new_records
   -- Description    : Process new dm_person_dim records including initial load
   ---------------------------------------------------------------------------
   PROCEDURE process_new_records (in_data_source_code IN VARCHAR2)
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.process_new_records' ;
     ln_fo_count          NUMBER;
     ln_min_id            NUMBER;
     ln_max_id            NUMBER;
     ln_last_id           NUMBER;
     ln_offset            NUMBER := 100000;

     CURSOR dim_cur (c_min_id IN NUMBER
                    ,c_offset IN NUMBER
                    ,c_data_source_code IN VARCHAR2) IS
     SELECT dm_person_dim_seq.NEXTVAL person_dim_id
           ,data_source_code
           ,person_id
           ,person_snapshot_id
           ,person_type
           ,first_name
           ,last_name
           ,middle_name
           ,email_address
           ,org_id
           ,is_effective
           ,batch_id
           ,last_update_date
           ,valid_from_date
           ,valid_to_date
           ,version_id
       FROM (SELECT /*+ index(t dm_person_tmp_ndx1) */
                    t.data_source_code
                   ,t.person_id
                   ,t.person_snapshot_id
                   ,t.person_type
                   ,t.first_name
                   ,t.last_name
                   ,t.middle_name
                   ,t.email_address
                   ,t.org_id
                   ,CASE WHEN valid_to_date IS NULL THEN
                         'Y'
                    ELSE 'N'
                    END             as is_effective
                   ,g_msg_id        as batch_id
                   ,sysdate         as last_update_date
                   ,t.creation_date as valid_from_date
                   ,t.valid_to_date
                   ,ROW_NUMBER() OVER (PARTITION BY t.person_id
                                           ORDER BY t.person_id,t.person_snapshot_id
                                           NULLS LAST) as version_id
               FROM dm_person_tmp t
                   ,(SELECT person_id
                       FROM (SELECT DISTINCT  person_id
                               FROM dm_person_tmp
                              WHERE data_source_code = c_data_source_code
                                AND person_id > c_min_id
                                AND dim_record_type IN ('I','L')
                              ORDER BY person_id)
                      WHERE rownum < c_offset + 1) p
              WHERE t.data_source_code = c_data_source_code
                AND p.person_id +0 = t.person_id
              ORDER BY t.person_id
            );

     person_dim_tab         person_dim_tabtyp;

   BEGIN

     IF g_dbg_mode = 'Y' THEN
        g_log_msg := 'Insert new person records';
     END IF;

     ln_min_id := 0;
     SELECT max(person_id) INTO ln_max_id FROM dm_person_tmp;

     WHILE (ln_min_id < ln_max_id) LOOP

        -- Reset insert count variable
        ln_fo_count := 0;

        OPEN dim_cur (ln_min_id,ln_offset,in_data_source_code);
        LOOP
            FETCH dim_cur BULK COLLECT INTO person_dim_tab;

            -- Grab min and max person_id to iterate through loop and find dups
            ln_min_id := person_dim_tab(person_dim_tab.LAST).person_id;

            FORALL idx IN person_dim_tab.FIRST .. person_dim_tab.LAST
               INSERT INTO dm_person_dim VALUES person_dim_tab(idx);

            FOR i IN person_dim_tab.FIRST .. person_dim_tab.LAST
            LOOP
               ln_fo_count := NVL(ln_fo_count,0) + SQL%BULK_ROWCOUNT(i);
            END LOOP;

            COMMIT;

            IF g_dbg_mode = 'Y' THEN
               g_log_msg := ln_fo_count||' inserted into dm_person_dim';
            END IF;

            EXIT WHEN dim_cur%NOTFOUND;

        END LOOP;
        CLOSE dim_cur;

     END LOOP;

   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := 'Unable to load dm_person_tmp table !';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END process_new_records;

   ---------------------------------------------------------------------------
   -- Procedure Name : process_upd_records
   -- Description    : Process update dm_person_tmp records
   ---------------------------------------------------------------------------
   PROCEDURE process_upd_records (in_data_source_code IN VARCHAR2)
   IS
     lv_proc_name           VARCHAR2(100)   := g_pkg_name||'.process_upd_records';
     lv_dim_record_type     VARCHAR2(1);
     ln_person_dim_id       NUMBER;
     idx                    NUMBER := 0;

     ln_error_count         NUMBER;
     ln_update_count        NUMBER;
     ln_person_id           NUMBER;
     ln_person_snapshot_id  NUMBER;

     CURSOR person_dim_cur(c_data_source_code IN VARCHAR2) IS
     SELECT data_source_code
           ,person_id
           ,person_snapshot_id
           ,person_type
           ,first_name
           ,last_name
           ,middle_name
           ,org_id
           ,creation_date
           ,valid_to_date
       FROM dm_person_tmp
      WHERE data_source_code = c_data_source_code
        AND dim_record_type = 'U'
      ORDER BY person_id,creation_date;

     TYPE person_cur_tabtyp IS TABLE OF person_dim_cur%ROWTYPE INDEX BY PLS_INTEGER;
     person_cur_tab         person_cur_tabtyp;

     person_dim_tab         person_dim_tabtyp;
     version_dim_tab        version_dim_tabtyp;

     person_id_tab          number_tabtyp;
     version_id_tab         number_tabtyp;

     dml_errors EXCEPTION;
     PRAGMA EXCEPTION_INIT(dml_errors, -24381);

   BEGIN

     -- Update dm_person_dim for replacement records
     UPDATE /*+ index(dim dm_person_dim_u1) */ dm_person_dim dim
        SET dim.is_effective     = 'N'
           ,dim.last_update_date = sysdate
       WHERE dim.data_source_code = 'REGULAR'
         AND EXISTS (SELECT null
                       FROM ( SELECT dim2.person_id,max(dim2.person_snapshot_id) person_snapshot_id
                                FROM dm_person_dim dim2
                               WHERE dim2.data_source_code = 'REGULAR'
                                 AND EXISTS ( SELECT /*+ index(tmp dm_person_tmp_ndx3) */ null
                                                FROM dm_person_tmp tmp
                                               WHERE tmp.data_source_code = dim2.data_source_code
                                                 AND tmp.person_id        = dim2.person_id
                                                 AND tmp.dim_record_type  = 'U')
                               GROUP BY dim2.person_id
                            ) t
                      WHERE t.person_id = dim.person_id
                        AND t.person_snapshot_id = dim.person_snapshot_id
                     )
     RETURNING person_id, version_id
          BULK COLLECT INTO person_id_tab, version_id_tab;

     ln_update_count := person_id_tab.COUNT;

     IF g_dbg_mode = 'Y' THEN
        g_log_msg := 'Updated '||ln_update_count||' replacements records in dm_person_dim';
     END IF;

     -- Now setup version table
     FOR i IN person_id_tab.FIRST .. person_id_tab.LAST
     LOOP
         version_dim_tab(person_id_tab(i)).person_id  := person_id_tab(i);
         version_dim_tab(person_id_tab(i)).version_id := version_id_tab(i);
     END LOOP;

     -- Process records
     OPEN person_dim_cur(in_data_source_code);
     LOOP
         FETCH person_dim_cur BULK COLLECT INTO person_cur_tab;
		 EXIT WHEN person_dim_cur%NOTFOUND;

         -- Set values for dim table
         FOR i IN person_cur_tab.FIRST .. person_cur_tab.LAST
         LOOP
             idx := person_dim_tab.COUNT + 1;

             ln_person_id := person_cur_tab(i).person_id;
             ln_person_snapshot_id := person_cur_tab(i).person_snapshot_id;

             -- Grab Next dim id
             SELECT dm_person_dim_seq.NEXTVAL INTO ln_person_dim_id FROM dual;

             person_dim_tab(idx).person_dim_id      := ln_person_dim_id;
             person_dim_tab(idx).data_source_code   := person_cur_tab(i).data_source_code;
             person_dim_tab(idx).person_id          := person_cur_tab(i).person_id;
             person_dim_tab(idx).person_snapshot_id := person_cur_tab(i).person_snapshot_id;
             person_dim_tab(idx).person_type        := person_cur_tab(i).person_type;
             person_dim_tab(idx).first_name         := person_cur_tab(i).first_name;
             person_dim_tab(idx).last_name          := person_cur_tab(i).last_name;
             person_dim_tab(idx).middle_name        := person_cur_tab(i).middle_name;
             person_dim_tab(idx).org_id             := person_cur_tab(i).org_id;

             IF ( person_cur_tab(i).valid_to_date IS NULL ) THEN
                person_dim_tab(idx).is_effective := 'Y';
             ELSE
                person_dim_tab(idx).is_effective := 'N';
             END IF;

             person_dim_tab(idx).batch_id         := g_msg_id;
             person_dim_tab(idx).last_update_date := sysdate;
             person_dim_tab(idx).valid_from_date  := person_cur_tab(i).creation_date;
             person_dim_tab(idx).valid_to_date    := person_cur_tab(i).valid_to_date;

             IF version_dim_tab.EXISTS(ln_person_id) THEN
                version_dim_tab(ln_person_id).version_id :=
                  version_dim_tab(ln_person_id).version_id + 1;
                person_dim_tab(idx).version_id := version_dim_tab(ln_person_id).version_id;
             ELSE
                person_dim_tab(idx).version_id := NULL;
             END IF;

         END LOOP;

      
         -- Now insert new records
         FORALL j IN person_dim_tab.FIRST .. person_dim_tab.LAST
           INSERT INTO dm_person_dim VALUES person_dim_tab(j);

         ln_update_count := 0;
         FOR k IN person_dim_tab.FIRST .. person_dim_tab.LAST
         LOOP
            ln_update_count := ln_update_count + SQL%BULK_ROWCOUNT(k);
         END LOOP;
         
     END LOOP;
     CLOSE person_dim_cur;

     COMMIT;

   EXCEPTION
     WHEN OTHERS THEN
       g_app_err_msg := lv_proc_name||', Unable to process person dim records!';
       g_db_err_msg  := SQLERRM;
       RAISE g_exception;
   END process_upd_records;

  /*---------------------------------------------------------------------------
   * Procedure : redo_last_load
   * Desc      : backs out last load based on records within dm_person_tmp 
   *---------------------------------------------------------------------------*/
   PROCEDURE redo_last_load(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                            ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
   IS
     lv_proc_name           VARCHAR2(100)   := g_pkg_name||'.process_upd_records';
     ln_batch_id            NUMBER;
     ln_backout_count       NUMBER := 0;
   BEGIN

     --
     -- Get the sequence required for logging messages
     --
     BEGIN
       SELECT DM_MSG_LOG_SEQ.nextval INTO g_msg_id FROM dual;
     END;

     SELECT batch_id INTO ln_batch_id
       FROM dm_person_dim
      WHERE person_snapshot_id = (SELECT max(person_snapshot_id) FROM dm_person_dim);

     DELETE  /*+ index(dim ak1_dm_person_dim) */
       FROM dm_person_dim dim
      WHERE dim.data_source_code = in_data_source_code
        AND EXISTS (select /*+ index(tmp dm_person_tmp_ndx1) */ null
                      from dm_person_tmp tmp
                     where tmp.data_source_code = 'REGULAR'
                       and tmp.person_id = dim.person_id
                       and tmp.person_snapshot_id = dim.person_snapshot_id );

     ln_backout_count := SQL%ROWCOUNT;

     UPDATE dm_person_dim dim
        SET dim.is_effective     = 'Y'
           ,dim.valid_to_date    = NULL
           ,dim.last_update_date = sysdate
      WHERE dim.data_source_code = 'REGULAR'
        AND EXISTS (SELECT null
                      FROM (SELECT /*+ index(dim2 ak1_dm_person_dim) */
                                   dim2.person_id, max(dim2.person_snapshot_id) person_snapshot_id
                              FROM dm_person_dim dim2, dm_person_tmp tmp
                             WHERE dim2.data_source_code = in_data_source_code
                               AND tmp.data_source_code   = dim2.data_source_code
                               AND tmp.person_id          = dim2.person_id
                               AND tmp.person_snapshot_id <> dim2.person_snapshot_id
                               AND tmp.dim_record_type    ='U'
                             GROUP BY dim2.person_id) t
                      WHERE dim.person_id = t.person_id
                        AND dim.person_snapshot_id = t.person_snapshot_id
                  );

     ln_backout_count := SQL%ROWCOUNT;

     COMMIT;

   END redo_last_load;

  /*---------------------------------------------------------------------------
   * Procedure : main
   * Desc      : This proccedure contains all the steps involved in gathering
   *             and migrating persons information from data mart as well as
   *             Front office.
   *---------------------------------------------------------------------------*/
   PROCEDURE main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                 ,p_date_id           IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
                 ,in_remove_dups      IN VARCHAR2 DEFAULT 'Y'
                 ,in_verify_eff_date  IN VARCHAR2 DEFAULT 'Y'
                 ,in_dbg_mode         IN VARCHAR2 DEFAULT 'N')
   IS
     lv_proc_name         VARCHAR2(100)   := g_pkg_name||'.main';
     lv_initial_load      VARCHAR2(1)     := 'N';
     ln_msg_id            NUMBER;
     ln_sub_id            NUMBER;
     ln_count             NUMBER;
     ln_process_cnt       NUMBER;
     ln_err_num           NUMBER;
     lv_err_msg           VARCHAR2(4000)  := NULL;
     ln_err               NUMBER;
     ln_last_identifier   NUMBER;
     ln_new_identifier    NUMBER;
     ld_last_update_date  DATE;
     ld_new_update_date   DATE;
   BEGIN

dm_cube_utils.make_indexes_visible;

     -- Setup debug mode
     IF in_dbg_mode = 'Y' THEN g_dbg_mode := 'Y'; ELSE g_dbg_mode := 'N'; END IF;

     --
     -- Get the sequence required for logging messages
     --
     BEGIN
       SELECT DM_MSG_LOG_SEQ.nextval INTO g_msg_id FROM dual;
       SELECT max(person_snapshot_id) INTO ln_new_identifier FROM person_snapshot@FO_R;
       ld_new_update_date  := SYSDATE;
     END;

     BEGIN
       SELECT last_identifier,last_update_date
         INTO ln_last_identifier,ld_last_update_date
         FROM dm_cube_objects
        WHERE object_name = 'DM_PERSON_DIM';

        -- Determine if this is the initial run
        IF TRUNC(ld_last_update_date) = TRUNC(g_last_process_date) THEN
           lv_initial_load := 'Y';
        ELSE
           lv_initial_load := 'N';
        END IF;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         -- This indicates the initial load
         lv_initial_load := 'Y';
         ln_last_identifier := 0;
         --INSERT INTO dm_cube_objects (object_name,last_update_date,last_identifier)
         --VALUES ('DM_PERSON_DIM',sysdate,ln_last_identifier);
         NULL;
     END;

     --
     -- truncate tables
     --

     BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_person_tmp';
     EXCEPTION
       WHEN OTHERS THEN
            g_app_err_msg := 'Unable to trunacte dm work tables for person dim!';
            g_db_err_msg  := SQLERRM;
            RAISE g_exception;
     END;

     -- log the start of main process

     DM_UTIL_LOG.p_log_msg(g_msg_id,1,g_pkg_name,lv_proc_name,'I');

     --
     -- Step 1 : Run the process to gather person information into dm_person_tmp table
     --

     DM_UTIL_LOG.p_log_msg(g_msg_id,2,'Populate dm_person_tmp',lv_proc_name,'I');
     load_dm_person_tmp(in_data_source_code,ln_last_identifier,ln_new_identifier);
     DM_UTIL_LOG.p_log_msg(g_msg_id,2,null,null,'U');

     --
     -- Step 2 : Load person dim information
     --
     DM_UTIL_LOG.p_log_msg(g_msg_id,3,'Populate dm_person_dim table',lv_proc_name,'I');
     process_person_dim(in_data_source_code
                       ,ln_last_identifier
                       ,in_remove_dups
                       ,in_verify_eff_date);
     DM_UTIL_LOG.p_log_msg(g_msg_id,3,null,null,'U');

     --
     -- Update cube_objects
     --
     UPDATE dm_cube_objects
        SET last_update_date = ld_new_update_date ,
            last_identifier = ln_new_identifier
      WHERE object_name = 'DM_PERSON_DIM'
        AND object_source_code =in_data_source_code ;
        
        COMMIT;
           --
           -- added by Manoj.  update the load status
           -- 
           DM_UTIL_LOG.p_log_cube_load_status('DM_PERSON_DIM',
                                               in_data_source_code,
                                               'SPEND_CUBE-DIM',
                                               'COMPLETED',
                                               p_date_id);

     DM_UTIL_LOG.p_log_msg(g_msg_id,1,null,null,'U');
                                                       
   EXCEPTION
     WHEN g_exception THEN
       --
       -- user defined exception, Log and raise the application error.
       --
       Rollback;
       DM_UTIL_LOG.p_log_msg(g_msg_id,99,g_app_err_msg||' : '||g_db_err_msg,lv_proc_name,'I');
       DM_UTIL_LOG.p_log_msg(g_msg_id,99,null,null,'U');
       ln_err_num := DM_UTIL_LOG.f_log_error(g_msg_id
                                            ,g_app_err_msg
                                            ,g_db_err_msg
                                            ,lv_proc_name);
           --
           -- added by Manoj.  update the load status
           -- 
           DM_UTIL_LOG.p_log_cube_load_status('DM_PERSON_DIM',
                                               in_data_source_code,
                                               'SPEND_CUBE-DIM',
                                               'FAILED',
                                               p_date_id);
                                            
     WHEN OTHERS THEN
       --
       -- Unknown exception, Log and raise the application error.
       --
       Rollback;
       g_app_err_msg := 'Unknown Error !';
       g_db_err_msg  := SQLERRM;

       DM_UTIL_LOG.p_log_msg(g_msg_id,99,g_app_err_msg||' : '||g_db_err_msg,lv_proc_name,'I');
       DM_UTIL_LOG.p_log_msg(g_msg_id,99,null,null,'U');
       ln_err_num := DM_UTIL_LOG.f_log_error(g_msg_id
                                            ,g_app_err_msg
                                            ,g_db_err_msg
                                            ,lv_proc_name);
           --
           -- added by Manoj.  update the load status
           -- 
           DM_UTIL_LOG.p_log_cube_load_status('DM_PERSON_DIM',
                                               in_data_source_code,
                                               'SPEND_CUBE-DIM',
                                               'FAILED',
                                               p_date_id);

   END main;

END dm_person_dim_process;
/