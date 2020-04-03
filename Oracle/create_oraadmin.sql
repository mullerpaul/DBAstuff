PROMPT connecting as SYS

CONN / AS sysdba

PROMPT creating ORAADMIN user

CREATE USER oraadmin
IDENTIFIED BY tsg1admin
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
/
ALTER USER oraadmin QUOTA 50M ON users
/
GRANT analyze any, select any table, create session, create table, 
      create procedure, create view, create sequence, query rewrite
TO oraadmin
/
GRANT select_catalog_role TO oraadmin
/
GRANT select ON dba_free_space TO oraadmin
/
GRANT select ON dba_data_files TO oraadmin
/
GRANT select ON dba_tablespaces TO oraadmin
/

PROMPT connecting as ORAADMIN
CONN oraadmin/tsg1admin

CREATE TABLE admin_storage_by_tablespace
(snapshot_id NUMBER NOT NULL,
 snapshot_date DATE NOT NULL,
 tablespace VARCHAR2(30) NOT NULL,
 total_mb NUMBER NOT NULL,
 used_mb NUMBER NOT NULL,
 free_mb NUMBER NOT NULL,
 percent_used NUMBER NOT NULL,
 extendable VARCHAR2(3))
TABLESPACE users
/
ALTER TABLE admin_storage_by_tablespace
ADD CONSTRAINT admin_storage_by_tablespace_pk
PRIMARY KEY (snapshot_id, tablespace)
/
CREATE SEQUENCE admin_storage_seq 
START WITH 1
/
CREATE OR REPLACE PROCEDURE admin_record_storage_data
AS
  my_id NUMBER;
  my_time DATE;
BEGIN
  my_time := SYSDATE;
  SELECT admin_storage_seq.nextval INTO my_id FROM dual;
  
  INSERT INTO admin_storage_by_tablespace
    (snapshot_id, snapshot_date, tablespace, total_mb, used_mb, free_mb, percent_used, extendable)
  SELECT my_id, my_time, d.tablespace_name,
         NVL (a.bytes / (1024*1024), 0),
         NVL (a.bytes - NVL (f.bytes, 0), 0) / (1024*1024),
         NVL (f.bytes, 0) / (1024*1024),
         NVL (100 * (a.bytes - NVL (f.bytes, 0)) / a.bytes, 0),
         a.extendable
  FROM dba_tablespaces d,
         (SELECT tablespace_name, SUM(bytes) AS bytes,
                 MAX(CASE WHEN (autoextensible = 'YES' AND bytes < maxbytes)
                          THEN 'Yes' ELSE NULL END) AS extendable
          FROM dba_data_files
          GROUP BY tablespace_name) a,
         (SELECT tablespace_name, SUM (BYTES) BYTES
          FROM dba_free_space
          GROUP BY tablespace_name) f
  WHERE d.tablespace_name = a.tablespace_name(+)
  AND d.tablespace_name = f.tablespace_name(+)
  AND NOT (d.extent_management LIKE 'LOCAL' AND d.CONTENTS LIKE 'TEMPORARY');
END;
/
DECLARE
  v_job NUMBER;
BEGIN
  DBMS_JOB.SUBMIT(v_job,'BEGIN admin_record_storage_data; END;',SYSDATE,'TRUNC(SYSDATE)+1+7/24');
END;
/
CREATE OR REPLACE VIEW admin_full_tablespace_view
AS
SELECT TO_CHAR(snapshot_date,'Mon-DD hh24:mi') AS sampledate, tablespace, 
       ROUND(total_mb, 1) AS Total, ROUND(used_mb, 1) AS Used,
       ROUND(free_mb, 1) AS Free, ROUND(percent_used,2) AS Percent,
       extendable
FROM admin_storage_by_tablespace
WHERE snapshot_date > SYSDATE - 1
AND percent_used > 85
/
CREATE OR REPLACE VIEW admin_tblspc_growth_hist_view
AS
SELECT a.tablespace,
       ROUND(a.used_mb - NVL(b.used_mb,0), 1) AS usage_one_week,
       ROUND(a.used_mb - NVL(c.used_mb,0), 1) AS usage_one_month,
       ROUND(a.total_mb - NVL(b.total_mb,0), 1) AS allocated_one_week,
       ROUND(a.total_mb - NVL(c.total_mb,0), 1) AS allocated_one_month
FROM admin_storage_by_tablespace a,
     admin_storage_by_tablespace b,
     admin_storage_by_tablespace c
WHERE TRUNC(a.snapshot_date,'DD') - 7 = TRUNC(b.snapshot_date (+),'DD')
AND TRUNC(a.snapshot_date,'DD') - 30 = TRUNC(c.snapshot_date (+),'DD')
AND a.tablespace = b.tablespace (+)
AND a.tablespace = c.tablespace (+)
AND a.snapshot_date > SYSDATE - 1
/
CREATE TABLE admin_gather_stats_for_schema
(schemaname VARCHAR2(30) PRIMARY KEY,
 est_percent NUMBER,
 method VARCHAR2(40))
TABLESPACE users
/
CREATE TABLE admin_gather_stats_history
(schemaname VARCHAR2(30),
 start_time DATE,
 end_time DATE,
 comments VARCHAR2(64))
TABLESPACE users
/
INSERT INTO admin_gather_stats_for_schema
SELECT DISTINCT owner, 20, 'FOR ALL COLUMNS SIZE 1'
FROM dba_tables
WHERE owner NOT IN ('DBSNMP','OUTLN','PERFSTAT','PROFILER','ORACLE','SYS','SYSTEM','WMSYS','ORAADMIN')
/
CREATE OR REPLACE PROCEDURE admin_gather_stats
AS
  CURSOR schemanames_cur IS
    SELECT schemaname, est_percent, method
    FROM admin_gather_stats_for_schema;
  lv_startdate DATE;
BEGIN
  FOR the_schema IN schemanames_cur LOOP
    BEGIN
      lv_startdate := SYSDATE;
      DBMS_STATS.GATHER_SCHEMA_STATS(ownname => the_schema.schemaname,
        estimate_percent => the_schema.est_percent,
        method_opt => the_schema.method,
        granularity => 'ALL',
        cascade => TRUE);
      INSERT INTO admin_gather_stats_history (schemaname, start_time, end_time, comments)
      VALUES (the_schema.schemaname, lv_startdate, SYSDATE, 'No Errors');
    EXCEPTION
      WHEN others THEN
        DECLARE
          the_sqlcode  NUMBER := SQLCODE;
          the_sqlerrm  VARCHAR2(512) := SQLERRM;
        BEGIN
          INSERT INTO admin_gather_stats_history (schemaname, start_time, end_time, comments)
          VALUES (the_schema.schemaname, lv_startdate, SYSDATE, 'Error ' || TO_CHAR (the_sqlcode) ||
            ': ' || SUBSTR (the_sqlerrm, 1, 48));
        END;
    END;
  END LOOP;
  COMMIT;
END admin_gather_stats;
/

GRANT all ON admin_storage_by_tablespace TO oracle
/
GRANT all ON admin_gather_stats_for_schema TO oracle
/
GRANT all ON admin_gather_stats_history TO oracle
/
GRANT select ON admin_full_tablespace_view TO oracle
/
GRANT select ON admin_tblspc_growth_hist_view TO oracle
/


PROMPT connecting as ORACLE
CONN /

PROMPT Creating private synonyms in ORACLE schema for ORAADMIN objects

CREATE SYNONYM full FOR oraadmin.admin_full_tablespace_view
/
CREATE SYNONYM storage FOR oraadmin.admin_storage_by_tablespace
/
CREATE SYNONYM stats_hist FOR oraadmin.admin_gather_stats_history
/
CREATE SYNONYM stats_setup FOR oraadmin.admin_gather_stats_for_schema
/

EXIT

