DECLARE
  e_program_does_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT (e_program_does_not_exist, -27476);
BEGIN
  BEGIN
    dbms_scheduler.drop_program('LEGO_REFRESH_OBJECT_PROGRAM');
  EXCEPTION
    WHEN e_program_does_not_exist
      THEN NULL;    --suppress "program does not exist" error
  END;
  BEGIN
    dbms_scheduler.drop_program('LEGO_REFRESH_RELEASE_PROGRAM');
  EXCEPTION
    WHEN e_program_does_not_exist
      THEN NULL;    --suppress "program does not exist" error
  END;
  BEGIN
    dbms_scheduler.drop_program('LEGO_REFRESH_2PASS_PROGRAM');
  EXCEPTION
    WHEN e_program_does_not_exist
      THEN NULL;    --suppress "program does not exist" error
  END;
END;
/

BEGIN
  dbms_scheduler.create_program(
    program_name => 'LEGO_REFRESH_OBJECT_PROGRAM',
    program_type => 'STORED_PROCEDURE',
    program_action => 'lego_refresh_mgr_pkg.refresh_object',
    number_of_arguments => 4,
    comments => 'The package LEGO_REFRESH_MGR_PKG creates jobs which use this program.');

  dbms_scheduler.define_program_argument(
    program_name => 'LEGO_REFRESH_OBJECT_PROGRAM',
    argument_position => 1,
    argument_name => 'REFRESH_OBJECT_NAME',
    argument_type => 'VARCHAR2');

  dbms_scheduler.define_program_argument(
    program_name => 'LEGO_REFRESH_OBJECT_PROGRAM',
    argument_position => 2,
    argument_name => 'SOURCE',
    argument_type => 'VARCHAR2');

	dbms_scheduler.define_program_argument(
    program_name => 'LEGO_REFRESH_OBJECT_PROGRAM',
    argument_position => 3,
    argument_name => 'RUNTIME',
    argument_type => 'TIMESTAMP');

  dbms_scheduler.define_program_argument(
    program_name => 'LEGO_REFRESH_OBJECT_PROGRAM',
    argument_position => 4,
    argument_name => 'SCN',
    argument_type => 'NUMBER');

  dbms_scheduler.enable('LEGO_REFRESH_OBJECT_PROGRAM');
END;
/

BEGIN
  dbms_scheduler.create_program(
    program_name => 'LEGO_REFRESH_RELEASE_PROGRAM',
    program_type => 'STORED_PROCEDURE',
    program_action => 'lego_refresh_mgr_pkg.release_worker',
    number_of_arguments => 2,
    comments => 'The package LEGO_REFRESH_MGR_PKG creates jobs which use this program.');

  dbms_scheduler.define_program_argument(
    program_name => 'LEGO_REFRESH_RELEASE_PROGRAM',
    argument_position => 1,
    argument_name => 'RUNTIME',
    argument_type => 'TIMESTAMP');
    
  dbms_scheduler.define_program_argument(
    program_name => 'LEGO_REFRESH_RELEASE_PROGRAM',
    argument_position => 2,
    argument_name => 'FIRSTPASSFLAG',
    argument_type => 'VARCHAR2');    

  dbms_scheduler.enable('LEGO_REFRESH_RELEASE_PROGRAM');
END;
/

BEGIN
  dbms_scheduler.create_program(
    program_name => 'LEGO_REFRESH_2PASS_PROGRAM',
    program_type => 'STORED_PROCEDURE',
    program_action => 'lego_refresh_mgr_pkg.start_second_pass',
    number_of_arguments => 1,
    comments => 'The package LEGO_REFRESH_MGR_PKG creates jobs which use this program.');

  dbms_scheduler.define_program_argument(
    program_name => 'LEGO_REFRESH_2PASS_PROGRAM',
    argument_position => 1,
    argument_name => 'RUNTIME',
    argument_type => 'TIMESTAMP');
  
  dbms_scheduler.enable('LEGO_REFRESH_2PASS_PROGRAM');
END;
/



