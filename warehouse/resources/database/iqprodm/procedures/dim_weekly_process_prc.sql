CREATE OR REPLACE PROCEDURE DIM_WEEKLY_PROCESS
AS
  ln_date_id NUMBER := TO_NUMBER(TO_CHAR(sysdate,'YYYYMMDD'));
BEGIN
       /*
       ** Alter session so that process/optimizer
       ** can see all invisible indexes
       */
       dm_cube_utils.make_indexes_visible;

 DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_JOB_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
 DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_ASSIGNMENT_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
 DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_PERSON_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
 DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_INVOICED_CAC_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
 DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_PROJECT_AGREEMENT_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
 DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_DATE_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade =>TRUE, no_invalidate=>FALSE);
 DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_RATECARD_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
 DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_GEO_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);

END;
/
