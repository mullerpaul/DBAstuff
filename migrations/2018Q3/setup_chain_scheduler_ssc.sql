

BEGIN
  DBMS_SCHEDULER.create_chain (
    chain_name          => 'sched_ssc_mview_chain',
    rule_set_name       => NULL,
    evaluation_interval => NULL,
    comments            => 'A chain to create scheduler chains for Supplier Scorecard MViews');
END;
/


BEGIN

  DBMS_SCHEDULER.create_program (
    program_name   => 'sched_IQN_mv',
    program_type   => 'PLSQL_BLOCK',
    program_action => 'BEGIN
                        dbms_mview.refresh(''RELEASE_SUBMISSION_IQN_MV'',''C'', atomic_refresh => false);
                       END;',
    enabled        => TRUE,
    comments       => 'Program for first link in the chain');

  DBMS_SCHEDULER.create_program (
    program_name   => 'sched_Beeline_mv',
    program_type   => 'PLSQL_BLOCK',
    program_action => 'BEGIN
                          dbms_mview.refresh(''RELEASE_SUBMISSION_BEELINE_MV'',''C'', atomic_refresh => false);
                       END;',
    enabled        => TRUE,
    comments       => 'Program for second link in the chain');

  DBMS_SCHEDULER.create_program (
    program_name   => 'sched_supplier_mv',
    program_type   => 'PLSQL_BLOCK',
    program_action => 'BEGIN
                          dbms_mview.refresh(''SUPPLIER_NAME_MV'',''C'', atomic_refresh => false);
                       END;',
    enabled        => TRUE,
    comments       => 'Program for third link in the chain');
    
    DBMS_SCHEDULER.create_program (
    program_name   => 'sched_metric_mv',
    program_type   => 'PLSQL_BLOCK',
    program_action => 'BEGIN
                           dbms_mview.refresh(''METRIC_DATA_MV'',''C'', atomic_refresh => false);
                       END;',
    enabled        => TRUE,
    comments       => 'Program for fourth link in the chain');

END;
/

BEGIN

  DBMS_SCHEDULER.define_chain_step (
    chain_name   => 'sched_ssc_mview_chain',
    step_name    => 'step_1',
    program_name => 'sched_IQN_mv');

  DBMS_SCHEDULER.define_chain_step (
    chain_name   => 'sched_ssc_mview_chain',
    step_name    => 'step_2',
    program_name => 'sched_Beeline_mv');

  DBMS_SCHEDULER.define_chain_step (
    chain_name   => 'sched_ssc_mview_chain',
    step_name    => 'step_3',
    program_name => 'sched_supplier_mv');
    
  DBMS_SCHEDULER.define_chain_step (
    chain_name   => 'sched_ssc_mview_chain',
    step_name    => 'step_4',
    program_name => 'sched_metric_mv');

END;
/

BEGIN

  DBMS_SCHEDULER.define_chain_rule (
    chain_name => 'sched_ssc_mview_chain',
    condition  => 'TRUE',
    action     => 'START step_1',
    rule_name  => 'chain_rule_1',
    comments   => 'First link in the chain');

   DBMS_SCHEDULER.define_chain_rule (
    chain_name => 'sched_ssc_mview_chain',
    condition  => 'step_1 SUCCEEDED',
    action     => 'START step_2',
    rule_name  => 'chain_rule_2',
    comments   => '2nd link in the chain');

  DBMS_SCHEDULER.define_chain_rule (
    chain_name => 'sched_SSC_mview_chain',
    condition  => 'step_1 SUCCEEDED AND step_2 SUCCEEDED',
    action     => 'START step_3',
    rule_name  => 'chain_rule_3',
    comments   => 'Third link in the chain');
    
   DBMS_SCHEDULER.define_chain_rule (
    chain_name => 'sched_ssc_mview_chain',
    condition  => 'step_1 SUCCEEDED AND step_2 SUCCEEDED AND step_3 SUCCEEDED',
    rule_name  => 'chain_rule_4',
    action     => 'START step_4',
    comments   => 'fourth link in the chain');

END;
/


BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'sched_mview_job',
    job_type        => 'CHAIN',
    job_action      => 'sched_ssc_mview_chain',
    repeat_interval => 'freq=weekly',
    start_date      => trunc(next_day(sysdate, 'SATURDAY')) + 3/24, 
    enabled         => FALSE,
    COMMENTS        => 'This job is used for the refreshing of materialized views on Sunday at 2 a.m. each day.');
END;
/

BEGIN
  DBMS_SCHEDULER.enable ('sched_ssc_mview_chain');
END;
/

BEGIN
  DBMS_SCHEDULER.RUN_JOB(
    JOB_NAME            => 'sched_mview_job',
    USE_CURRENT_SESSION => FALSE);
END;
/


