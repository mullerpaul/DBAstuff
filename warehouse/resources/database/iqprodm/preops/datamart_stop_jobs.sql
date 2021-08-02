/**********************************************************************
 This script is for stopping all running datamart dbms_scheduler jobs 
 to avoid conflict with Build process.
 **********************************************************************/
Declare
  v_db_name VARCHAR2(30) := NULL;
  Cursor cur_chain_jobs is select distinct job_name 
                          from (select job_name from USER_SCHEDULER_RUNNING_CHAINS where job_name like 'DM%'
			                union all
			                select job_name from USER_SCHEDULER_RUNNING_JOBS where job_name like 'DM%');
Begin
  v_db_name := sys_context('USERENV','DB_NAME');

  IF ( v_db_name <> 'IQM' ) THEN

	dbms_output.put_line('Stopping dbms_scheduler Jobs Running in non-production database');

 	For c1 in cur_chain_jobs
 	Loop
  		DBMS_SCHEDULER.STOP_JOB( job_name => c1.job_name);
 	End Loop;
 
  END IF;

  EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK;
End;
/
