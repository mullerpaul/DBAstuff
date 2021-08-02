/*******************************************************************************
SCRIPT NAME         lego_java_constant_lookup.sql 
 
LEGO OBJECT NAME    LEGO_JAVA_CONSTANT_LOOKUP
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

04/04/2014 - E.Clark      - IQN-15392 - Added RATE_TYPE (RES_RATE_BASIS) - Release 12.0.3
04/07/2014 - E.Clark      - IQN-15422 - Added PROJECT_AGREEMENT_PHASE and PAVersionState - Release 12.0.3
04/09/2014 - E.Clark      - IQN-13331 - Added MATCH_STATE - Release 12.0.3
04/11/2014 - E.Clark      - IQN-15353 - Added JP - Release 12.0.3
04/11/2014 - E.Clark      - IQN-15396 - Added MilestoneStatus - Release 12.0.3
04/15/2014 - E.Clark      - IQN-15394 - Added PROJECT_RFX_PHASE and RFxBidType - Release 12.0.3
04/17/2014 - J.Pullifrone - IQN-15420 - Added OVERALL_EVAL (lego_evaluation) - Release 12.1
04/21/2014 - J.Pullifrone - IQN-15419 - Added REQUEST_TO_BUY_PHASE (lego_request_to_buy) - Release 12.1
04/24/2014 - J.Pullifrone - IQN-15402 - Added DELIVERABLE_TYPE (lego_pa_change_request) - Release 12.1
01/27/2016 - P.Muller                 - Modifications for DB links, multiple sources, and remote SCN
03/29/2016 = J.Pullifrone             - Added TIMECARD_STATE 
08/16/2016 = J.Pullifrone             - Added EXPENSE_STATUS 
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_java_constant_lookup.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JAVA_CONSTANT_LOOKUP'; 

v_clob CLOB :=
     q'{SELECT constant_type, 
               constant_value, 
               constant_description, 
               UPPER(locale_fk) AS locale_fk
          FROM java_constant_lookup@db_link_name AS OF SCN source_db_SCN
         WHERE constant_type IN 
                  ('ASGNMT_STATE',
                  'RELOCATION_ASS',
                  'SOURCING_METHOD',
                  'ASSIGNMENT_PHASE',
                  'ASGNMT_APPROVAL_STATE',
                  'COUNTRY',
                  'JOB_CATEGORY',
                  'JOB_LEVEL',
                  'JOB_PHASE',
                  'JOB_STATE',
                  'PLACE',
                  'SEARCHABLE_ASGNMT_STATE',
                  'RES_RATE_BASIS',
                  'PAVersionState',
                  'PROJECT_AGREEMENT_PHASE',
                  'MATCH_STATE',
                  'JP',
                  'MilestoneStatus',
                  'PROJECT_RFX_PHASE',
                  'RFxBidType',
                  'OVERALL_EVAL',
                  'REQUEST_TO_BUY_PHASE',
                  'DELIVERABLE_TYPE',
                  'TIMECARD_STATE',
                  'ExpenseStatus'
                  )
        ORDER BY locale_fk}';
     
v_partition_clause VARCHAR2(4000) :=
      q'{PARTITION BY LIST (constant_type)
   (PARTITION p0  VALUES  ('ASGNMT_STATE'),
    PARTITION p1  VALUES  ('RELOCATION_ASS'),
    PARTITION p2  VALUES  ('SOURCING_METHOD'),
    PARTITION p3  VALUES  ('ASSIGNMENT_PHASE'),
    PARTITION p4  VALUES  ('ASGNMT_APPROVAL_STATE'),
    PARTITION p5  VALUES  ('COUNTRY'),
    PARTITION p6  VALUES  ('JOB_CATEGORY'),
    PARTITION p7  VALUES  ('JOB_LEVEL'),
    PARTITION p8  VALUES  ('JOB_PHASE'),
    PARTITION p9  VALUES  ('JOB_STATE'),
    PARTITION p10 VALUES  ('PLACE'),
    PARTITION p11 VALUES  ('SEARCHABLE_ASGNMT_STATE'),
    PARTITION p12 VALUES  ('RES_RATE_BASIS'),
    PARTITION p13 VALUES  ('PAVersionState'),
    PARTITION p14 VALUES  ('PROJECT_AGREEMENT_PHASE'),
    PARTITION p15 VALUES  ('MATCH_STATE'),
    PARTITION p16 VALUES  ('JP'),
    PARTITION p17 VALUES  ('MilestoneStatus'),
    PARTITION p18 VALUES  ('PROJECT_RFX_PHASE'),
    PARTITION p19 VALUES  ('RFxBidType'),
    PARTITION p20 VALUES  ('OVERALL_EVAL'),
    PARTITION p21 VALUES  ('REQUEST_TO_BUY_PHASE'),
    PARTITION p22 VALUES  ('DELIVERABLE_TYPE'),
    PARTITION p23 VALUES  ('TIMECARD_STATE'),
    PARTITION p24 VALUES  ('ExpenseStatus')
    )}';

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql      = v_clob,
         partition_clause = v_partition_clause
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/

