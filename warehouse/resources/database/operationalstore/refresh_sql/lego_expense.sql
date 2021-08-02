/*******************************************************************************
SCRIPT NAME         lego_expense.sql 
 
LEGO OBJECT NAME    LEGO_EXPENSE
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2   
08/20/2014 - J.Pullifrone - IQN-18776 - removed invoice_id and added invoiced_amount - Release 12.2.0                                 
07/27/2016 - jpullifrone  - IQN-33503 - modifications for DB links, multiple sources, and remote SCN, removed jcl
08/08/2016 - jpullifrone  - IQN-33780 - splitting out expense approvals for performance and comporting with granularity
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_expense.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_EXPENSE'; 

  v_clob CLOB :=            
q'{SELECT erl.expense_report_line_item_id   AS  expense_report_line_item_id,
         er.expense_report_id              AS  expense_report_id,
         bfr.business_org_fk               AS  buyer_org_id,
         sfr.business_org_fk               AS  supplier_org_id,
         erl.assignment_continuity_fk      AS  assignment_continuity_id,
         erl.cost_alloc_code1_fk           AS  cac1_identifier,
         erl.cost_alloc_code2_fk           AS  cac2_identifier,
         er.creator_fk                     AS  creator_person_id,
         er.project_agmt_fk                AS  project_agreement_id,
         er.approval_workflow_fk           AS  approval_workflow_id,
         erl.udf_collection_fk             AS  erli_udf_collection_id,
         er.udf_collection_fk              AS  er_udf_collection_id,
         er.expense_report_number          AS  expense_report_number,
         er.state                          AS  expense_status_id,
         --NVL(expense_status.constant_description,'Unknown')  AS expense_status,
         erl.expense_week_ending_date      AS  week_ending_date,
         erl.date_of_expense               AS  expense_expenditure_date,
         erl.amount                        AS  num_units,
         CASE WHEN et.is_unit_based = 1 THEN 
            eer.amount
         ELSE
            NULL
         END                               AS  per_unit_amount,
         erl.total_amount                  AS  expense_amount,
         et.name                           AS  expense_type,
         er.purpose                        AS  expense_purpose,
         erl.justification                 AS  expense_justification,
         --ies.invoiced_amount,
         cac1.start_date AS cac1_start_date,
         cac1.end_date   AS cac1_end_date,
         cac1.cac_guid   AS cac1_guid,
         cac2.start_date AS cac2_start_date,
         cac2.end_date   AS cac2_end_date,
         cac2.cac_guid   AS cac2_guid,
         cu.value        AS  expense_currency_id,
         cu.description  AS  expense_currency
    FROM expense_entry_rule@db_link_name AS OF SCN source_db_SCN eer,
         expense_type@db_link_name AS OF SCN source_db_SCN et,
         expense_report_line_item@db_link_name AS OF SCN source_db_SCN erl,
         expense_report@db_link_name AS OF SCN source_db_SCN er,
         assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
         assignment_edition@db_link_name AS OF SCN source_db_SCN ae,
         firm_role@db_link_name AS OF SCN source_db_SCN sfr,
         firm_role@db_link_name AS OF SCN source_db_SCN bfr,
         currency_unit@db_link_name cu,
         --lego_invcd_expenditure_sum ies,
         --(SELECT constant_value, constant_description
         --   FROM java_constant_lookup
         --  WHERE constant_type    = 'ExpenseStatus'
         --    AND UPPER(locale_fk) = 'EN_US') expense_status,
         (SELECT lcc.cac_id, 
                 lcc.start_date,
                 lcc.end_date,
                 lcc.cac_guid
            FROM lego_cac_collection@db_link_name lcc ) cac1,
         (SELECT lcc.cac_id, 
                 lcc.start_date,
                 lcc.end_date,
                 lcc.cac_guid
            FROM lego_cac_collection@db_link_name lcc ) cac2
   WHERE er.expense_report_id            = erl.expense_report_fk
     AND erl.expense_week_ending_date    >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
     AND erl.assignment_continuity_fk    = ac.assignment_continuity_id
     AND ac.owning_buyer_firm_fk         = bfr.firm_id
     AND ac.owning_supply_firm_fk        = sfr.firm_id
     AND et.expense_type_id              = erl.expense_type_fk
     AND er.state                        != 7 -- canceled
     AND erl.expense_entry_rule_fk       = eer.expense_entry_rule_id(+)
     AND ac.current_edition_fk           = ae.assignment_edition_id
     AND ac.assignment_continuity_id     = ae.assignment_continuity_fk
     AND ac.currency_unit_fk             = cu.value
     --AND er.state                        = expense_status.constant_value(+)
     AND erl.cost_alloc_code1_fk         = cac1.cac_id(+)
     AND erl.cost_alloc_code2_fk         = cac2.cac_id(+)
     --AND erl.expense_report_line_item_id = ies.expenditure_id(+)
     --AND ies.expenditure_type(+)         = 'Expense'
     }';              
         

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql = v_clob
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

