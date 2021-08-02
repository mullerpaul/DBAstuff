/* ****************************************************************************
Name: DM_RATE_EVENTS_PROC

Purpose: This procedure is called by DBMS_SCHEDULER job, DM_RATE_EVENT_JOBS.
         It calls both rate event processes.
         
Modification History:

05/16/2016  jpullifrone IQN-32013 Add MV Refresh call for DM_ATOM_ASSIGN_XREF.  
08/01/2016  jpullifrone IQN-33792 Nothing changed here in this proc but noting that
                                  reference to this proc has been removed from FO
                                  Legacy deploy scripts.    
05/09/2017  jpullifrone IQN-37592 Add MV Refresh call for DM_ATOM_ASSIGN_XREF.  

******************************************************************************/
CREATE OR REPLACE PROCEDURE dm_rate_events_proc
AS
      CURSOR all_indexes IS
             SELECT DISTINCT std_country_id
               FROM dm_iqn_index
              WHERE index_type = 'N'
              ORDER BY std_country_id DESC;

      day_num NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'DD'));

      v_start_month DATE;
      v_end_month   DATE;

      v_start       NUMBER;
      v_end         NUMBER;
      v_open_count  NUMBER;
BEGIN
   dm_rate_event.p_main('REGULAR');
   dm_rate_event.p_main('WACHOVIA');
   dm_fotimecard_rate_event.process_batch('REGULAR');
   dm_fotimecard_rate_event.process_batch('WACHOVIA');
   --Perform complete refresh.  This MV is used to store standardized values by assignment.
   DBMS_MVIEW.REFRESH('DM_ATOM_ASSIGN_XREF','C');

   
   FOR an_index IN all_indexes
   LOOP
         --DBMS_OUTPUT.PUT_LINE('Working on country = ' || an_index.std_country_id);

         SELECT MIN(month_number) start_month, MAX(month_number) end_month, COUNT(*) open_count
           INTO v_start, v_end, v_open_count
           FROM dm_iqn_index
          WHERE index_status = 'Preliminary'
            AND index_type = 'N'
            AND std_country_id = an_index.std_country_id;

         IF (v_open_count > 0)
            THEN
                 --DBMS_OUTPUT.PUT_LINE('Open months before adjustment = ' || v_start || ' to ' || v_end);
                 IF (day_num > 20)
                    THEN
                          v_end := TO_NUMBER(TO_CHAR(TRUNC(SYSDATE, 'MM'), 'YYYYMM'));
                 END IF;
                 v_end_month   := TO_DATE(v_end   || '01', 'YYYYMMDD');
                 v_start_month := TO_DATE(v_start || '01', 'YYYYMMDD');

                 dm_fotimecard_rate_event.close_all_months(v_start, v_end, 'Y');
                 --DBMS_OUTPUT.PUT_LINE('running close_all_months  = ' || v_start || ' to ' || v_end);

                 dm_index.populate_index(p_date1 => v_start_month, p_date2 => v_end_month, p_country=> an_index.std_country_id, p_final_flag => 'N', p_upd_wts_flag => 'N');
                 --DBMS_OUTPUT.PUT_LINE('running populate_index  = ' || v_start_month || ' to ' || v_end_month);
            ELSE
                 --DBMS_OUTPUT.PUT_LINE('Nothing is open for country = ' || an_index.std_country_id);
                 IF (day_num > 20)
                    THEN
                          v_end := TO_NUMBER(TO_CHAR(TRUNC(SYSDATE, 'MM'), 'YYYYMM'));
                          v_end_month   := TO_DATE(v_end   || '01', 'YYYYMMDD');

                          dm_fotimecard_rate_event.close_all_months(v_end, v_end, 'Y');
                          --DBMS_OUTPUT.PUT_LINE('running close_all_months  = ' || v_end || ' to ' || v_end);
                          dm_index.populate_index(p_date1 => v_end_month, p_date2 => v_end_month, p_country=> an_index.std_country_id, p_final_flag => 'N', p_upd_wts_flag => 'N');
                          --DBMS_OUTPUT.PUT_LINE('running populate_index  = ' || v_end_month || ' to ' || v_end_month);
                 END IF;
         END IF;
   END LOOP;
END;
/

