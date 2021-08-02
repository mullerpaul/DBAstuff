DECLARE

v_sql VARCHAR2(1000) := NULL;
v_db_name VARCHAR2(30) := NULL;

CURSOR cur_jobs is SELECT job_name FROM user_scheduler_jobs where job_name like 'DM%';
CURSOR cur_chain is SELECT chain_name FROM user_scheduler_chains where chain_name like 'DM%';
CURSOR cur_schedule is SELECT schedule_name FROM user_scheduler_schedules where schedule_name like 'DM%';
CURSOR cur_prog is select program_name  from user_scheduler_programs where program_name  like 'DM%';

Cursor Cur is select job  from all_jobs where what in ( 'DM_CURRENCY_CONVERSION_DATA.populate_rates;','DIM_DAILY_PROCESS;','inv_hc_fact_daily_process;',
'invoice_fact_daily_process;','DM_INVOICED_SPEND.p_main;','tt_fill_fact_daily_process;','hc_fact_daily_process;','DM_RATE_EVENTS_PROC;',
'DBMS_UTILITY.compile_schema(USER);','DM_FO_METRIC_GRAPH.main;','dm_populate_spend_summary.p_main;','DIM_WEEKLY_PROCESS;','invoice_spend_all_process;') ;

BEGIN

v_db_name := sys_context('USERENV','DB_NAME');

--Drop all dbms_jobs before scheduling through dbms_scheduler.

/*******************************
IF ( v_db_name = 'IQM' ) THEN
dbms_output.put_line('Drop and create jobs');

Begin
 For C1 in Cur
   Loop
     SYS.DBMS_JOB.REMOVE(C1.job);
   End Loop;
End;


for c1 in cur_jobs
 Loop
  v_sql := 'BEGIN DBMS_SCHEDULER.DROP_JOB('||chr(39)||c1.job_name||chr(39)||'); END;';
  EXECUTE IMMEDIATE v_sql;
 End Loop;

for c2 in cur_chain
 Loop
     v_sql := 'BEGIN DBMS_SCHEDULER.DISABLE('||chr(39)||c2.chain_name||chr(39)||'); END;';
  	EXECUTE IMMEDIATE v_sql;
     v_sql := 'BEGIN DBMS_SCHEDULER.DROP_CHAIN('||chr(39)||c2.chain_name||chr(39)||'); END;';
  	EXECUTE IMMEDIATE v_sql;
 End Loop;

for c3 in cur_schedule
 Loop
   v_sql := 'BEGIN DBMS_SCHEDULER.DROP_SCHEDULE('||chr(39)||c3.schedule_name||chr(39)||'); END;';
  EXECUTE IMMEDIATE v_sql;
 End Loop;

for c4 in cur_prog
 Loop
   v_sql := 'BEGIN DBMS_SCHEDULER.DROP_PROGRAM('||chr(39)||c4.program_name||chr(39)||'); END;';
  EXECUTE IMMEDIATE v_sql;
 End Loop;

BEGIN

-- DM_SCHED_HOURLY_JOBS 	--> Runs every hour
-- DM_SCHED_DAILY_JOBS  	--> Runs daily at 7pm
-- DM_SCHED_SATURDAY_7AM_JOBS  	--> Runs saturday at 7am
-- DM_SCHED_SATURDAY_5AM_JOBS --> Runs saturday at 5am
-- DM_SCHED_SATURDAY_6AM_JOBS --> Runs saturday at 6am

 DBMS_SCHEDULER.CREATE_SCHEDULE(schedule_name 	=> 'DM_SCHED_HOURLY_JOBS',
                                start_date 	=> trunc(sysdate)+7/24,
                                repeat_interval => 'FREQ=HOURLY',
                                comments 		=>'Runs hourly');

 DBMS_SCHEDULER.CREATE_SCHEDULE(schedule_name 	=> 'DM_SCHED_DAILY_JOBS',
                                 start_date 	=> trunc(sysdate)+19/24,
                                 repeat_interval => 'FREQ=DAILY; BYDAY=MON,TUE,WED,THU,FRI,SAT,SUN; BYHOUR=19;',
                                 comments 		=>'Run at 7pm all days');

 DBMS_SCHEDULER.CREATE_SCHEDULE(schedule_name 	=> 'DM_SCHED_SATURDAY_7AM_JOBS',
                                 start_date 	=> trunc(sysdate)+7/24,
                                 repeat_interval => 'FREQ=WEEKLY; BYDAY=SAT; BYHOUR=7;',
                                 comments 		=>'Run at 7am on Saturday');

DBMS_SCHEDULER.CREATE_SCHEDULE(schedule_name 	=> 'DM_SCHED_SATURDAY_6AM_JOBS',
                                 start_date 	=> trunc(sysdate)+6/24,
                                 repeat_interval => 'FREQ=WEEKLY; BYDAY=SAT; BYHOUR=6;',
                                 comments 		=>'Run at 7am on Saturday');


 DBMS_SCHEDULER.CREATE_SCHEDULE(schedule_name 	=> 'DM_SCHED_SATURDAY_5AM_JOBS',
                                 start_date 	=> trunc(sysdate)+5/24,
                                 repeat_interval => 'FREQ=WEEKLY; BYDAY=SAT; BYHOUR=5;',
                                 comments 		=>'Run at 5am on Saturday');

 DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_DIM_DAILY_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'DIM_DAILY_PROCESS',
                               enabled        => TRUE,
                               comments       => 'Program for daily dimension process');

 DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_TT_FILL_FACT_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'TT_FILL_FACT_DAILY_PROCESS',
                               enabled        => TRUE,
                               comments       => 'Program for time to fill fact process');

 DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_HC_FACT_DAILY_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'HC_FACT_DAILY_PROCESS',
                               enabled        => TRUE,
                               comments       => 'Program for hc fact process');

 DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_INV_HC_FACT_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'INV_HC_FACT_DAILY_PROCESS',
                               enabled        => TRUE,
                               comments       => 'Program for invoice headcount fact process');

 DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_INVOICE_FACT_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'INVOICE_FACT_DAILY_PROCESS',
                               enabled        => TRUE,
                               comments       => 'Program for invoice fact process');

DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_INVOICE_SPEND_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'INVOICE_SPEND_ALL_PROCESS',
                               enabled        => TRUE,
                               comments       => 'Program for invoice spend all process');

DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_DIM_WEEKLY_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'DIM_WEEKLY_PROCESS',
                               enabled        => TRUE,
                               comments       => 'Program for Weekly process');

DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_COMPILE_OBJECTS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'COMPILE_OBJECTS',
                               enabled        => TRUE,
                               comments       => 'Program for Compiling objects');

DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_RATE_EVENTS_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'DM_RATE_EVENTS_PROC',
                               enabled        => TRUE,
                               comments       => 'Program for rate event process');

DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_FO_METRIC_GRAPH_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'DM_FO_METRIC_GRAPH.main',
                               enabled        => TRUE,
                               comments       => 'Program for metric graph process');

DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_CURR_RATE_PROCESS',
                               program_type   => 'STORED_PROCEDURE',
                               program_action => 'DM_CURRENCY_CONVERSION_DATA.populate_rates',
                               enabled        => TRUE,
                               comments       => 'Program for currency process');
                                                       
DBMS_SCHEDULER.CREATE_CHAIN(chain_name =>  'DM_CHAIN_DAILY');
  
DBMS_SCHEDULER.DEFINE_CHAIN_STEP(CHAIN_NAME  => 'DM_CHAIN_DAILY', STEP_NAME  =>  'STEP1', PROGRAM_NAME =>  'DM_PG_DIM_DAILY_PROCESS');
DBMS_SCHEDULER.DEFINE_CHAIN_STEP(CHAIN_NAME  => 'DM_CHAIN_DAILY', STEP_NAME  =>  'STEP2', PROGRAM_NAME =>  'DM_PG_TT_FILL_FACT_PROCESS');
DBMS_SCHEDULER.DEFINE_CHAIN_STEP(CHAIN_NAME  => 'DM_CHAIN_DAILY', STEP_NAME  =>  'STEP3', PROGRAM_NAME =>  'DM_PG_HC_FACT_DAILY_PROCESS');
DBMS_SCHEDULER.DEFINE_CHAIN_STEP(CHAIN_NAME  => 'DM_CHAIN_DAILY', STEP_NAME  =>  'STEP4', PROGRAM_NAME =>  'DM_PG_INV_HC_FACT_PROCESS');
DBMS_SCHEDULER.DEFINE_CHAIN_STEP(CHAIN_NAME  => 'DM_CHAIN_DAILY', STEP_NAME  =>  'STEP5', PROGRAM_NAME =>  'DM_PG_INVOICE_FACT_PROCESS');
  
DBMS_SCHEDULER.DEFINE_CHAIN_RULE(CHAIN_NAME  => 'DM_CHAIN_DAILY', rule_name  => 'DM_CHAIN_RULE1', condition => 'TRUE', action => 'START STEP1');
DBMS_SCHEDULER.DEFINE_CHAIN_RULE(CHAIN_NAME  => 'DM_CHAIN_DAILY', rule_name  => 'DM_CHAIN_RULE2', condition => 'STEP1 COMPLETED', action => 'Start STEP2, STEP3, STEP4, STEP5');
DBMS_SCHEDULER.DEFINE_CHAIN_RULE(CHAIN_NAME  => 'DM_CHAIN_DAILY', rule_name  => 'DM_CHAIN_RULE3', condition => 'STEP2 COMPLETED AND STEP3 COMPLETED AND STEP4 COMPLETED AND STEP5 COMPLETED', action => 'END');
  
DBMS_SCHEDULER.ENABLE('DM_CHAIN_DAILY');

DBMS_SCHEDULER.CREATE_JOB( job_name => 'DM_CHAIN_DAILY_JOBS',job_type => 'CHAIN', job_action => 'DM_CHAIN_DAILY',schedule_name => 'DM_SCHED_DAILY_JOBS', enabled => TRUE);  

DBMS_SCHEDULER.CREATE_JOB( job_name => 'DM_HOURLY_JOBS',program_name => 'DM_PG_INVOICE_SPEND_PROCESS',schedule_name => 'DM_SCHED_HOURLY_JOBS', enabled => TRUE);

DBMS_SCHEDULER.CREATE_JOB( job_name => 'DM_COMPILE_JOBS',program_name => 'DM_PG_COMPILE_OBJECTS',schedule_name => 'DM_SCHED_SATURDAY_5AM_JOBS', enabled => TRUE); 

DBMS_SCHEDULER.CREATE_JOB( job_name => 'DM_CURRENCY_RATE_JOBS',program_name => 'DM_PG_CURR_RATE_PROCESS',schedule_name => 'DM_SCHED_SATURDAY_6AM_JOBS', enabled => TRUE); 

DBMS_SCHEDULER.CREATE_JOB( job_name => 'DM_WEEKLY_JOBS',program_name => 'DM_PG_DIM_WEEKLY_PROCESS',schedule_name => 'DM_SCHED_SATURDAY_7AM_JOBS', enabled => TRUE); 

DBMS_SCHEDULER.CREATE_JOB( job_name => 'DM_RATE_EVENT_JOBS',program_name => 'DM_PG_RATE_EVENTS_PROCESS',schedule_name => 'DM_SCHED_SATURDAY_7AM_JOBS', enabled => TRUE); 

DBMS_SCHEDULER.CREATE_JOB( job_name => 'DM_FO_METRIC_GRAPH_JOBS',program_name => 'DM_PG_FO_METRIC_GRAPH_PROCESS',schedule_name => 'DM_SCHED_SATURDAY_7AM_JOBS', enabled => TRUE); 
                                              
END;

ELSE
 dbms_output.put_line('Skipped.....Drop and create jobs');
END IF;

*******************************/


END;
/
