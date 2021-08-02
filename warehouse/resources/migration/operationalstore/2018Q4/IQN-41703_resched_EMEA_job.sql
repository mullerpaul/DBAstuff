DECLARE
    lc_emea_prod_instance_name   CONSTANT VARCHAR2(10) := 'PR01';
    lv_instance_name             VARCHAR2(30);

BEGIN
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source('IQN-41703');
    logger_pkg.info('modify invoice lego schedule in EMEA prod only to refresh twice daily');

    /* This script does things differently in different environments.
       THIS IS A BAD IDEA!!!  

       Please don't use this script as an excuse to make more scripts like this.
       Unfortunately, we are having to do it this time.  See the ticket to see why. */

    SELECT global_name
      INTO lv_instance_name
      FROM global_name;

    IF lv_instance_name = lc_emea_prod_instance_name THEN
        /* Running in EMEA prod env.  Set session timezone then modify repeat interval. 
           (I'm not sure the TZ modification is required; but I've gotten in the habit of
            doing it every time i'm working with scheduler jobs in EMEA database.)
           The new schedule syntax should cause the job to run 2x daily, at 09:08 and 21:08. */
        EXECUTE IMMEDIATE ( 'ALTER SESSION SET time_zone = dbtimezone' );
        dbms_scheduler.set_attribute(
            name        => 'TEMP_REFRESH_INVOICE_LEGOS',
            attribute   => 'REPEAT_INTERVAL',
            value       => 'freq=hourly; byhour=9,21; byminute=8'
        );

    ELSE
        /* not running in EMEA prod env, do nothing */
        logger_pkg.info('This is '
                          || lv_instance_name
                          || ' not '
                          || lc_emea_prod_instance_name
                          || ' so this script does nothing.');
    END IF;

    logger_pkg.unset_source('IQN-41703');
END;
/
