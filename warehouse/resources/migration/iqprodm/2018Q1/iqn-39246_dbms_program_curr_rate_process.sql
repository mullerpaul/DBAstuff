--create program to refresh DM_CURRENCY_CONVERSION_RATES table.
DECLARE
 le_already_exists EXCEPTION;
 PRAGMA exception_init (le_already_exists, -27477);
 
BEGIN
  DBMS_SCHEDULER.CREATE_PROGRAM(program_name   => 'DM_PG_CURR_RATE_PROCESS',
                                program_type   => 'STORED_PROCEDURE',
                                program_action => 'dm_currency_conversion_data.populate_rates',
                                enabled        => TRUE, 
                                comments       => 'Program for currency process');
EXCEPTION
  WHEN le_already_exists THEN 
    NULL;
  WHEN OTHERS THEN
    RAISE;
END;
/
