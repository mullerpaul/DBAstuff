--- now that we have changed the signature of the convergence-search refresh run init procedure, 
--- we must also change the call stored in the the scheduler job to match.
DECLARE
    lv_new_action VARCHAR2(1000) := 
q'{DECLARE
    lv_bitbucket   TIMESTAMP;
BEGIN
    lego_refresh_conv_search.start_refresh_run(
        allowable_latency_minutes   => 80,
        refresh_runtime_utc_out     => lv_bitbucket
    );
END;
}';
BEGIN
    dbms_scheduler.set_attribute(
        name        => 'TEMP_REFRESH_CONV_SEARCH_LEGOS',
        attribute   => 'JOB_ACTION',
        value       => lv_new_action
    );
END;
/

