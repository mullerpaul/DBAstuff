

-- We are addressing the missing dependency info for WF JOB legos!
DECLARE 
  ln_count      NUMBER := 0;
BEGIN

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_MATCH'
    AND relies_on_object_name = 'LEGO_JOB_OPPORTUNITY';
    
  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_MATCH', 'WFPROD', 'LEGO_JOB_OPPORTUNITY', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_MATCH_STATS_BY_JOB'
    AND relies_on_object_name = 'LEGO_INTERVIEW';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_MATCH_STATS_BY_JOB', 'WFPROD', 'LEGO_INTERVIEW', 'WFPROD');
  END IF;


  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_MATCH_STATS_BY_JOB'
    AND relies_on_object_name = 'LEGO_JOB_OPPORTUNITY';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_MATCH_STATS_BY_JOB', 'WFPROD', 'LEGO_JOB_OPPORTUNITY', 'WFPROD');
  END IF;
  

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_MATCH_STATS_BY_JOB'
    AND relies_on_object_name = 'LEGO_MATCH';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_MATCH_STATS_BY_JOB', 'WFPROD', 'LEGO_MATCH', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_POSITION_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_BUS_ORG';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_POSITION_TIME_TO_FILL', 'WFPROD', 'LEGO_BUS_ORG', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_POSITION_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_JOB';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_POSITION_TIME_TO_FILL', 'WFPROD', 'LEGO_JOB', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_POSITION_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_JOB_RATES';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_POSITION_TIME_TO_FILL', 'WFPROD', 'LEGO_JOB_RATES', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_POSITION_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_JOB_WORK_LOCATION';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_POSITION_TIME_TO_FILL', 'WFPROD', 'LEGO_JOB_WORK_LOCATION', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_POSITION_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_PLACE';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_POSITION_TIME_TO_FILL', 'WFPROD', 'LEGO_PLACE', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_POSITION_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_POSITION_HISTORY';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_POSITION_TIME_TO_FILL', 'WFPROD', 'LEGO_POSITION_HISTORY', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_SOW_MILESTONE_INVOICE'
    AND relies_on_object_name = 'LEGO_PROJECT_AGREEMENT';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_SOW_MILESTONE_INVOICE', 'WFPROD', 'LEGO_PROJECT_AGREEMENT', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_ASSIGNMENT_EA';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_TIME_TO_FILL', 'WFPROD', 'LEGO_ASSIGNMENT_EA', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_ASSIGNMENT_WO';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_TIME_TO_FILL', 'WFPROD', 'LEGO_ASSIGNMENT_WO', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_JAVA_CONSTANT_LOOKUP';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_TIME_TO_FILL', 'WFPROD', 'LEGO_JAVA_CONSTANT_LOOKUP', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_JOB';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_TIME_TO_FILL', 'WFPROD', 'LEGO_JOB', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_JOB_OPPORTUNITY';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_TIME_TO_FILL', 'WFPROD', 'LEGO_JOB_OPPORTUNITY', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_TIME_TO_FILL'
    AND relies_on_object_name = 'LEGO_MATCH';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_TIME_TO_FILL', 'WFPROD', 'LEGO_MATCH', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_ADDRESS';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_ADDRESS', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_ASSIGNMENT_EA';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_ASSIGNMENT_EA', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_ASSIGNMENT_TA';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_ASSIGNMENT_TA', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_ASSIGNMENT_WO';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_ASSIGNMENT_WO', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_CONTACT_ADDRESS';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_CONTACT_ADDRESS', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_JOB';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_JOB', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_JOB_OPPORTUNITY';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_JOB_OPPORTUNITY', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_JOB_POSITION';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_JOB_POSITION', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_JOB_RATES';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_JOB_RATES', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_FILL_TREND'
    AND relies_on_object_name = 'LEGO_MATCH';

  IF ln_count = 0 THEN
    INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_FILL_TREND', 'WFPROD', 'LEGO_MATCH', 'WFPROD');
  END IF;

  SELECT COUNT(1)
  INTO ln_count
  FROM lego_refresh_dependency
  WHERE source_name = 'WFPROD'
    AND object_name = 'LEGO_JOB_OPPORTUNITY'
    AND relies_on_object_name = 'LEGO_JOB';

  IF ln_count = 0 THEN
     INSERT INTO lego_refresh_dependency
      (object_name, source_name, relies_on_object_name, relies_on_source_name)
    VALUES
      ('LEGO_JOB_OPPORTUNITY', 'WFPROD', 'LEGO_JOB', 'WFPROD');
  END IF;

  COMMIT;

END;
/


