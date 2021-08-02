CREATE OR REPLACE FORCE VIEW lego_reqs_by_status_sec_vw
AS
SELECT job_id, 
       buyer_org_id, 
       NVL(jcl.constant_description, l.job_state) AS job_state
  FROM lego_reqs_by_status_sec l,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type = 'JOB_STATE'
           AND locale_fk     = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) jcl
 WHERE l.job_state_id = jcl.constant_value(+)
/

