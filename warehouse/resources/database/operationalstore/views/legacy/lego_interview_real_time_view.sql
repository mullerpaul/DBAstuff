CREATE OR REPLACE FORCE VIEW lego_interview_rt_vw
AS 
SELECT lj.job_id,
       lj.buyer_org_id, 
       lj.hiring_mgr_person_id, 
       lj.job_position_title, 
       lj.job_description,
       i.match_id, 
       i.created_date    AS interview_created_date, 
       i.interview_type, 
       i.title           AS interview_title, 
       i.location        AS interview_location, 
       i.interview_status, 
       ind.start_date    AS interview_start_date, 
       inn.note          AS interview_note
  FROM lego_job lj,   --using the synonym to get latest data but avoid currency conversion join in view. 
       interview i,
       interview_note inn,
       interview_date ind
 WHERE i.job_id = lj.job_id
   AND i.id = inn.interview_id(+)
   AND i.selected_date_id = ind.id(+)  --this join is different than that in the data source.  I believe this one is more correct
/
   
COMMENT ON TABLE lego_interview_rt_vw IS 'Real-time data from FO interview tables joined with LEGO_JOB'
/
COMMENT ON COLUMN lego_interview_rt_vw.job_id IS 'job_id from LEGO_JOB'
/
COMMENT ON COLUMN lego_interview_rt_vw.buyer_org_id IS 'buyer_org_id from LEGO_JOB'
/
COMMENT ON COLUMN lego_interview_rt_vw.hiring_mgr_person_id IS 'hiring_mgr_person_id from LEGO_JOB'
/
COMMENT ON COLUMN lego_interview_rt_vw.job_position_title IS 'job_position_title from LEGO_JOB'
/
COMMENT ON COLUMN lego_interview_rt_vw.job_description IS 'job_description from LEGO_JOB'
/
COMMENT ON COLUMN lego_interview_rt_vw.match_id IS 'Included as a join column to LEGO_MATCH'
/
COMMENT ON COLUMN lego_interview_rt_vw.interview_created_date IS 'From interview.created_date'
/
COMMENT ON COLUMN lego_interview_rt_vw.interview_type IS 'From interview.interview_type'
/
COMMENT ON COLUMN lego_interview_rt_vw.interview_title IS 'From interview.title'
/
COMMENT ON COLUMN lego_interview_rt_vw.interview_location IS 'From interview.location'
/
COMMENT ON COLUMN lego_interview_rt_vw.interview_status IS 'from interview.interview_status'
/
COMMENT ON COLUMN lego_interview_rt_vw.interview_start_date IS 'from interview_date.start_date'
/
COMMENT ON COLUMN lego_interview_rt_vw.interview_note IS 'From interview_note.note'
/

