--- update the synonym and refresh toggle table names so they are unique across this table.
UPDATE lego_refresh 
   SET synonym_name='PERSON_EMEA', refresh_object_name_1='PERSON_EMEA1', refresh_object_name_2='PERSON_EMEA2'
 WHERE object_name='LEGO_PERSON' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PERSON_IQP', refresh_object_name_1='PERSON_IQP1', refresh_object_name_2='PERSON_IQP2'
 WHERE object_name='LEGO_PERSON' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PERSON_WF', refresh_object_name_1='PERSON_WF1', refresh_object_name_2='PERSON_WF2'
 WHERE object_name='LEGO_PERSON' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='MANAGED_CAC_EMEA', refresh_object_name_1='MANAGED_CAC_EMEA1', refresh_object_name_2='MANAGED_CAC_EMEA2'
 WHERE object_name='LEGO_MANAGED_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='MANAGED_CAC_IQP', refresh_object_name_1='MANAGED_CAC_IQP1', refresh_object_name_2='MANAGED_CAC_IQP2'
 WHERE object_name='LEGO_MANAGED_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='MANAGED_CAC_WF', refresh_object_name_1='MANAGED_CAC_WF1', refresh_object_name_2='MANAGED_CAC_WF2'
 WHERE object_name='LEGO_MANAGED_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='MANAGED_PERSON_EMEA', refresh_object_name_1='MANAGED_PERSON_EMEA1', refresh_object_name_2='MANAGED_PERSON_EMEA2'
 WHERE object_name='LEGO_MANAGED_PERSON' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='MANAGED_PERSON_IQP', refresh_object_name_1='MANAGED_PERSON_IQP1', refresh_object_name_2='MANAGED_PERSON_IQP2'
 WHERE object_name='LEGO_MANAGED_PERSON' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='MANAGED_PERSON_WF', refresh_object_name_1='MANAGED_PERSON_WF1', refresh_object_name_2='MANAGED_PERSON_WF2'
 WHERE object_name='LEGO_MANAGED_PERSON' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_ASSIGNMENT_EMEA', refresh_object_name_1='SECURE_ASSIGNMENT_EMEA1', refresh_object_name_2='SECURE_ASSIGNMENT_EMEA2'
 WHERE object_name='LEGO_SECURE_ASSIGNMENT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_ASSIGNMENT_IQP', refresh_object_name_1='SECURE_ASSIGNMENT_IQP1', refresh_object_name_2='SECURE_ASSIGNMENT_IQP2'
 WHERE object_name='LEGO_SECURE_ASSIGNMENT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_ASSIGNMENT_WF', refresh_object_name_1='SECURE_ASSIGNMENT_WF1', refresh_object_name_2='SECURE_ASSIGNMENT_WF2'
 WHERE object_name='LEGO_SECURE_ASSIGNMENT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_JOB_EMEA', refresh_object_name_1='SECURE_JOB_EMEA1', refresh_object_name_2='SECURE_JOB_EMEA2'
 WHERE object_name='LEGO_SECURE_JOB' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_JOB_IQP', refresh_object_name_1='SECURE_JOB_IQP1', refresh_object_name_2='SECURE_JOB_IQP2'
 WHERE object_name='LEGO_SECURE_JOB' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_JOB_WF', refresh_object_name_1='SECURE_JOB_WF1', refresh_object_name_2='SECURE_JOB_WF2'
 WHERE object_name='LEGO_SECURE_JOB' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_PROJECT_AGREEMENT_EMEA', refresh_object_name_1='SECURE_PROJECT_AGREEMENT_EMEA1', refresh_object_name_2='SECURE_PROJECT_AGREEMENT_EMEA2'
 WHERE object_name='LEGO_SECURE_PROJECT_AGREEMENT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_PROJECT_AGREEMENT_IQP', refresh_object_name_1='SECURE_PROJECT_AGREEMENT_IQP1', refresh_object_name_2='SECURE_PROJECT_AGREEMENT_IQP2'
 WHERE object_name='LEGO_SECURE_PROJECT_AGREEMENT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_PROJECT_AGREEMENT_WF', refresh_object_name_1='SECURE_PROJECT_AGREEMENT_WF1', refresh_object_name_2='SECURE_PROJECT_AGREEMENT_WF2'
 WHERE object_name='LEGO_SECURE_PROJECT_AGREEMENT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGN_MANAGED_CAC_EMEA', refresh_object_name_1='ASSIGN_MANAGED_CAC_EMEA1', refresh_object_name_2='ASSIGN_MANAGED_CAC_EMEA2'
 WHERE object_name='LEGO_ASSIGN_MANAGED_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGN_MANAGED_CAC_IQP', refresh_object_name_1='ASSIGN_MANAGED_CAC_IQP1', refresh_object_name_2='ASSIGN_MANAGED_CAC_IQP2'
 WHERE object_name='LEGO_ASSIGN_MANAGED_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGN_MANAGED_CAC_WF', refresh_object_name_1='ASSIGN_MANAGED_CAC_WF1', refresh_object_name_2='ASSIGN_MANAGED_CAC_WF2'
 WHERE object_name='LEGO_ASSIGN_MANAGED_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_MANAGED_CAC_EMEA', refresh_object_name_1='EXPENSE_MANAGED_CAC_EMEA1', refresh_object_name_2='EXPENSE_MANAGED_CAC_EMEA2'
 WHERE object_name='LEGO_EXPENSE_MANAGED_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_MANAGED_CAC_IQP', refresh_object_name_1='EXPENSE_MANAGED_CAC_IQP1', refresh_object_name_2='EXPENSE_MANAGED_CAC_IQP2'
 WHERE object_name='LEGO_EXPENSE_MANAGED_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_MANAGED_CAC_WF', refresh_object_name_1='EXPENSE_MANAGED_CAC_WF1', refresh_object_name_2='EXPENSE_MANAGED_CAC_WF2'
 WHERE object_name='LEGO_EXPENSE_MANAGED_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_MANAGED_CAC_EMEA', refresh_object_name_1='JOB_MANAGED_CAC_EMEA1', refresh_object_name_2='JOB_MANAGED_CAC_EMEA2'
 WHERE object_name='LEGO_JOB_MANAGED_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_MANAGED_CAC_IQP', refresh_object_name_1='JOB_MANAGED_CAC_IQP1', refresh_object_name_2='JOB_MANAGED_CAC_IQP2'
 WHERE object_name='LEGO_JOB_MANAGED_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_MANAGED_CAC_WF', refresh_object_name_1='JOB_MANAGED_CAC_WF1', refresh_object_name_2='JOB_MANAGED_CAC_WF2'
 WHERE object_name='LEGO_JOB_MANAGED_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PA_MANAGED_CAC_EMEA', refresh_object_name_1='PA_MANAGED_CAC_EMEA1', refresh_object_name_2='PA_MANAGED_CAC_EMEA2'
 WHERE object_name='LEGO_PA_MANAGED_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PA_MANAGED_CAC_IQP', refresh_object_name_1='PA_MANAGED_CAC_IQP1', refresh_object_name_2='PA_MANAGED_CAC_IQP2'
 WHERE object_name='LEGO_PA_MANAGED_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PA_MANAGED_CAC_WF', refresh_object_name_1='PA_MANAGED_CAC_WF1', refresh_object_name_2='PA_MANAGED_CAC_WF2'
 WHERE object_name='LEGO_PA_MANAGED_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_MANAGED_CAC_EMEA', refresh_object_name_1='TIMECARD_MANAGED_CAC_EMEA1', refresh_object_name_2='TIMECARD_MANAGED_CAC_EMEA2'
 WHERE object_name='LEGO_TIMECARD_MANAGED_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_MANAGED_CAC_IQP', refresh_object_name_1='TIMECARD_MANAGED_CAC_IQP1', refresh_object_name_2='TIMECARD_MANAGED_CAC_IQP2'
 WHERE object_name='LEGO_TIMECARD_MANAGED_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_MANAGED_CAC_WF', refresh_object_name_1='TIMECARD_MANAGED_CAC_WF1', refresh_object_name_2='TIMECARD_MANAGED_CAC_WF2'
 WHERE object_name='LEGO_TIMECARD_MANAGED_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_ASSIGNMENT_EMEA', refresh_object_name_1='SLOT_ASSIGNMENT_EMEA1', refresh_object_name_2='SLOT_ASSIGNMENT_EMEA2'
 WHERE object_name='LEGO_SLOT_ASSIGNMENT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_ASSIGNMENT_IQP', refresh_object_name_1='SLOT_ASSIGNMENT_IQP1', refresh_object_name_2='SLOT_ASSIGNMENT_IQP2'
 WHERE object_name='LEGO_SLOT_ASSIGNMENT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_ASSIGNMENT_WF', refresh_object_name_1='SLOT_ASSIGNMENT_WF1', refresh_object_name_2='SLOT_ASSIGNMENT_WF2'
 WHERE object_name='LEGO_SLOT_ASSIGNMENT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_EXPENSE_REPORT_EMEA', refresh_object_name_1='SLOT_EXPENSE_REPORT_EMEA1', refresh_object_name_2='SLOT_EXPENSE_REPORT_EMEA2'
 WHERE object_name='LEGO_SLOT_EXPENSE_REPORT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_EXPENSE_REPORT_IQP', refresh_object_name_1='SLOT_EXPENSE_REPORT_IQP1', refresh_object_name_2='SLOT_EXPENSE_REPORT_IQP2'
 WHERE object_name='LEGO_SLOT_EXPENSE_REPORT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_EXPENSE_REPORT_WF', refresh_object_name_1='SLOT_EXPENSE_REPORT_WF1', refresh_object_name_2='SLOT_EXPENSE_REPORT_WF2'
 WHERE object_name='LEGO_SLOT_EXPENSE_REPORT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_JOB_EMEA', refresh_object_name_1='SLOT_JOB_EMEA1', refresh_object_name_2='SLOT_JOB_EMEA2'
 WHERE object_name='LEGO_SLOT_JOB' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_JOB_IQP', refresh_object_name_1='SLOT_JOB_IQP1', refresh_object_name_2='SLOT_JOB_IQP2'
 WHERE object_name='LEGO_SLOT_JOB' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_JOB_WF', refresh_object_name_1='SLOT_JOB_WF1', refresh_object_name_2='SLOT_JOB_WF2'
 WHERE object_name='LEGO_SLOT_JOB' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_PROJECT_AGREEMENT_EMEA', refresh_object_name_1='SLOT_PROJECT_AGREEMENT_EMEA1', refresh_object_name_2='SLOT_PROJECT_AGREEMENT_EMEA2'
 WHERE object_name='LEGO_SLOT_PROJECT_AGREEMENT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_PROJECT_AGREEMENT_IQP', refresh_object_name_1='SLOT_PROJECT_AGREEMENT_IQP1', refresh_object_name_2='SLOT_PROJECT_AGREEMENT_IQP2'
 WHERE object_name='LEGO_SLOT_PROJECT_AGREEMENT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_PROJECT_AGREEMENT_WF', refresh_object_name_1='SLOT_PROJECT_AGREEMENT_WF1', refresh_object_name_2='SLOT_PROJECT_AGREEMENT_WF2'
 WHERE object_name='LEGO_SLOT_PROJECT_AGREEMENT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_TIMECARD_EMEA', refresh_object_name_1='SLOT_TIMECARD_EMEA1', refresh_object_name_2='SLOT_TIMECARD_EMEA2'
 WHERE object_name='LEGO_SLOT_TIMECARD' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_TIMECARD_IQP', refresh_object_name_1='SLOT_TIMECARD_IQP1', refresh_object_name_2='SLOT_TIMECARD_IQP2'
 WHERE object_name='LEGO_SLOT_TIMECARD' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SLOT_TIMECARD_WF', refresh_object_name_1='SLOT_TIMECARD_WF1', refresh_object_name_2='SLOT_TIMECARD_WF2'
 WHERE object_name='LEGO_SLOT_TIMECARD' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_INV_ASSGNMT_EMEA', refresh_object_name_1='SECURE_INV_ASSGNMT_EMEA1', refresh_object_name_2='SECURE_INV_ASSGNMT_EMEA2'
 WHERE object_name='LEGO_SECURE_INV_ASSGNMT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_INV_ASSGNMT_IQP', refresh_object_name_1='SECURE_INV_ASSGNMT_IQP1', refresh_object_name_2='SECURE_INV_ASSGNMT_IQP2'
 WHERE object_name='LEGO_SECURE_INV_ASSGNMT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_INV_ASSGNMT_WF', refresh_object_name_1='SECURE_INV_ASSGNMT_WF1', refresh_object_name_2='SECURE_INV_ASSGNMT_WF2'
 WHERE object_name='LEGO_SECURE_INV_ASSGNMT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_INV_PRJ_AGR_EMEA', refresh_object_name_1='SECURE_INV_PRJ_AGR_EMEA1', refresh_object_name_2='SECURE_INV_PRJ_AGR_EMEA2'
 WHERE object_name='LEGO_SECURE_INV_PRJ_AGR' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_INV_PRJ_AGR_IQP', refresh_object_name_1='SECURE_INV_PRJ_AGR_IQP1', refresh_object_name_2='SECURE_INV_PRJ_AGR_IQP2'
 WHERE object_name='LEGO_SECURE_INV_PRJ_AGR' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SECURE_INV_PRJ_AGR_WF', refresh_object_name_1='SECURE_INV_PRJ_AGR_WF1', refresh_object_name_2='SECURE_INV_PRJ_AGR_WF2'
 WHERE object_name='LEGO_SECURE_INV_PRJ_AGR' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_EMEA', refresh_object_name_1='BUS_ORG_EMEA1', refresh_object_name_2='BUS_ORG_EMEA2'
 WHERE object_name='LEGO_BUS_ORG' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_IQP', refresh_object_name_1='BUS_ORG_IQP1', refresh_object_name_2='BUS_ORG_IQP2'
 WHERE object_name='LEGO_BUS_ORG' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_WF', refresh_object_name_1='BUS_ORG_WF1', refresh_object_name_2='BUS_ORG_WF2'
 WHERE object_name='LEGO_BUS_ORG' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='LOCALES_BY_BUYER_ORG_EMEA', refresh_object_name_1='LOCALES_BY_BUYER_ORG_EMEA1', refresh_object_name_2='LOCALES_BY_BUYER_ORG_EMEA2'
 WHERE object_name='LEGO_LOCALES_BY_BUYER_ORG' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='LOCALES_BY_BUYER_ORG_IQP', refresh_object_name_1='LOCALES_BY_BUYER_ORG_IQP1', refresh_object_name_2='LOCALES_BY_BUYER_ORG_IQP2'
 WHERE object_name='LEGO_LOCALES_BY_BUYER_ORG' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='LOCALES_BY_BUYER_ORG_WF', refresh_object_name_1='LOCALES_BY_BUYER_ORG_WF1', refresh_object_name_2='LOCALES_BY_BUYER_ORG_WF2'
 WHERE object_name='LEGO_LOCALES_BY_BUYER_ORG' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='LOCALE_PREF_SCORE_EMEA', refresh_object_name_1='LOCALE_PREF_SCORE_EMEA1', refresh_object_name_2='LOCALE_PREF_SCORE_EMEA2'
 WHERE object_name='LEGO_LOCALE_PREF_SCORE' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='LOCALE_PREF_SCORE_IQP', refresh_object_name_1='LOCALE_PREF_SCORE_IQP1', refresh_object_name_2='LOCALE_PREF_SCORE_IQP2'
 WHERE object_name='LEGO_LOCALE_PREF_SCORE' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='LOCALE_PREF_SCORE_WF', refresh_object_name_1='LOCALE_PREF_SCORE_WF1', refresh_object_name_2='LOCALE_PREF_SCORE_WF2'
 WHERE object_name='LEGO_LOCALE_PREF_SCORE' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CURRENCY_CONV_RATES_EMEA', refresh_object_name_1='CURRENCY_CONV_RATES_EMEA1', refresh_object_name_2='CURRENCY_CONV_RATES_EMEA2'
 WHERE object_name='LEGO_CURRENCY_CONV_RATES' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='CURRENCY_CONV_RATES_IQP', refresh_object_name_1='CURRENCY_CONV_RATES_IQP1', refresh_object_name_2='CURRENCY_CONV_RATES_IQP2'
 WHERE object_name='LEGO_CURRENCY_CONV_RATES' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CURRENCY_CONV_RATES_WF', refresh_object_name_1='CURRENCY_CONV_RATES_WF1', refresh_object_name_2='CURRENCY_CONV_RATES_WF2'
 WHERE object_name='LEGO_CURRENCY_CONV_RATES' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JAVA_CONSTANT_LOOKUP_EMEA', refresh_object_name_1='JAVA_CONSTANT_LOOKUP_EMEA1', refresh_object_name_2='JAVA_CONSTANT_LOOKUP_EMEA2'
 WHERE object_name='LEGO_JAVA_CONSTANT_LOOKUP' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JAVA_CONSTANT_LOOKUP_IQP', refresh_object_name_1='JAVA_CONSTANT_LOOKUP_IQP1', refresh_object_name_2='JAVA_CONSTANT_LOOKUP_IQP2'
 WHERE object_name='LEGO_JAVA_CONSTANT_LOOKUP' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JAVA_CONSTANT_LOOKUP_WF', refresh_object_name_1='JAVA_CONSTANT_LOOKUP_WF1', refresh_object_name_2='JAVA_CONSTANT_LOOKUP_WF2'
 WHERE object_name='LEGO_JAVA_CONSTANT_LOOKUP' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_CAC_EMEA', refresh_object_name_1='JOB_CAC_EMEA1', refresh_object_name_2='JOB_CAC_EMEA2'
 WHERE object_name='LEGO_JOB_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_CAC_IQP', refresh_object_name_1='JOB_CAC_IQP1', refresh_object_name_2='JOB_CAC_IQP2'
 WHERE object_name='LEGO_JOB_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_CAC_WF', refresh_object_name_1='JOB_CAC_WF1', refresh_object_name_2='JOB_CAC_WF2'
 WHERE object_name='LEGO_JOB_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_OPPORTUNITY_EMEA', refresh_object_name_1='JOB_OPPORTUNITY_EMEA1', refresh_object_name_2='JOB_OPPORTUNITY_EMEA2'
 WHERE object_name='LEGO_JOB_OPPORTUNITY' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_OPPORTUNITY_IQP', refresh_object_name_1='JOB_OPPORTUNITY_IQP1', refresh_object_name_2='JOB_OPPORTUNITY_IQP2'
 WHERE object_name='LEGO_JOB_OPPORTUNITY' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_OPPORTUNITY_WF', refresh_object_name_1='JOB_OPPORTUNITY_WF1', refresh_object_name_2='JOB_OPPORTUNITY_WF2'
 WHERE object_name='LEGO_JOB_OPPORTUNITY' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_SUPPLIER_EMEA', refresh_object_name_1='JOB_SUPPLIER_EMEA1', refresh_object_name_2='JOB_SUPPLIER_EMEA2'
 WHERE object_name='LEGO_JOB_SUPPLIER' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_SUPPLIER_IQP', refresh_object_name_1='JOB_SUPPLIER_IQP1', refresh_object_name_2='JOB_SUPPLIER_IQP2'
 WHERE object_name='LEGO_JOB_SUPPLIER' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_SUPPLIER_WF', refresh_object_name_1='JOB_SUPPLIER_WF1', refresh_object_name_2='JOB_SUPPLIER_WF2'
 WHERE object_name='LEGO_JOB_SUPPLIER' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_WORK_LOCATION_EMEA', refresh_object_name_1='JOB_WORK_LOCATION_EMEA1', refresh_object_name_2='JOB_WORK_LOCATION_EMEA2'
 WHERE object_name='LEGO_JOB_WORK_LOCATION' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_WORK_LOCATION_IQP', refresh_object_name_1='JOB_WORK_LOCATION_IQP1', refresh_object_name_2='JOB_WORK_LOCATION_IQP2'
 WHERE object_name='LEGO_JOB_WORK_LOCATION' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_WORK_LOCATION_WF', refresh_object_name_1='JOB_WORK_LOCATION_WF1', refresh_object_name_2='JOB_WORK_LOCATION_WF2'
 WHERE object_name='LEGO_JOB_WORK_LOCATION' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_EMEA', refresh_object_name_1='JOB_EMEA1', refresh_object_name_2='JOB_EMEA2'
 WHERE object_name='LEGO_JOB' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_IQP', refresh_object_name_1='JOB_IQP1', refresh_object_name_2='JOB_IQP2'
 WHERE object_name='LEGO_JOB' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_WF', refresh_object_name_1='JOB_WF1', refresh_object_name_2='JOB_WF2'
 WHERE object_name='LEGO_JOB' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_UDF_ENUM_EMEA', refresh_object_name_1='JOB_UDF_ENUM_EMEA1', refresh_object_name_2='JOB_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_JOB_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_UDF_ENUM_IQP', refresh_object_name_1='JOB_UDF_ENUM_IQP1', refresh_object_name_2='JOB_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_JOB_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_UDF_ENUM_WF', refresh_object_name_1='JOB_UDF_ENUM_WF1', refresh_object_name_2='JOB_UDF_ENUM_WF2'
 WHERE object_name='LEGO_JOB_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_UDF_NOENUM_EMEA', refresh_object_name_1='JOB_UDF_NOENUM_EMEA1', refresh_object_name_2='JOB_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_JOB_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_UDF_NOENUM_IQP', refresh_object_name_1='JOB_UDF_NOENUM_IQP1', refresh_object_name_2='JOB_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_JOB_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='JOB_UDF_NOENUM_WF', refresh_object_name_1='JOB_UDF_NOENUM_WF1', refresh_object_name_2='JOB_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_JOB_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RATECARD_EMEA', refresh_object_name_1='RATECARD_EMEA1', refresh_object_name_2='RATECARD_EMEA2'
 WHERE object_name='LEGO_RATECARD' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='RATECARD_IQP', refresh_object_name_1='RATECARD_IQP1', refresh_object_name_2='RATECARD_IQP2'
 WHERE object_name='LEGO_RATECARD' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RATECARD_WF', refresh_object_name_1='RATECARD_WF1', refresh_object_name_2='RATECARD_WF2'
 WHERE object_name='LEGO_RATECARD' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_EMEA', refresh_object_name_1='RFX_EMEA1', refresh_object_name_2='RFX_EMEA2'
 WHERE object_name='LEGO_RFX' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_IQP', refresh_object_name_1='RFX_IQP1', refresh_object_name_2='RFX_IQP2'
 WHERE object_name='LEGO_RFX' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_WF', refresh_object_name_1='RFX_WF1', refresh_object_name_2='RFX_WF2'
 WHERE object_name='LEGO_RFX' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_CAC_EMEA', refresh_object_name_1='RFX_CAC_EMEA1', refresh_object_name_2='RFX_CAC_EMEA2'
 WHERE object_name='LEGO_RFX_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_CAC_IQP', refresh_object_name_1='RFX_CAC_IQP1', refresh_object_name_2='RFX_CAC_IQP2'
 WHERE object_name='LEGO_RFX_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_CAC_WF', refresh_object_name_1='RFX_CAC_WF1', refresh_object_name_2='RFX_CAC_WF2'
 WHERE object_name='LEGO_RFX_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_UDF_ENUM_EMEA', refresh_object_name_1='RFX_UDF_ENUM_EMEA1', refresh_object_name_2='RFX_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_RFX_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_UDF_ENUM_IQP', refresh_object_name_1='RFX_UDF_ENUM_IQP1', refresh_object_name_2='RFX_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_RFX_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_UDF_ENUM_WF', refresh_object_name_1='RFX_UDF_ENUM_WF1', refresh_object_name_2='RFX_UDF_ENUM_WF2'
 WHERE object_name='LEGO_RFX_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_UDF_NOENUM_EMEA', refresh_object_name_1='RFX_UDF_NOENUM_EMEA1', refresh_object_name_2='RFX_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_RFX_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_UDF_NOENUM_IQP', refresh_object_name_1='RFX_UDF_NOENUM_IQP1', refresh_object_name_2='RFX_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_RFX_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RFX_UDF_NOENUM_WF', refresh_object_name_1='RFX_UDF_NOENUM_WF1', refresh_object_name_2='RFX_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_RFX_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_CAC_EMEA', refresh_object_name_1='ASSIGNMENT_CAC_EMEA1', refresh_object_name_2='ASSIGNMENT_CAC_EMEA2'
 WHERE object_name='LEGO_ASSIGNMENT_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_CAC_IQP', refresh_object_name_1='ASSIGNMENT_CAC_IQP1', refresh_object_name_2='ASSIGNMENT_CAC_IQP2'
 WHERE object_name='LEGO_ASSIGNMENT_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_CAC_WF', refresh_object_name_1='ASSIGNMENT_CAC_WF1', refresh_object_name_2='ASSIGNMENT_CAC_WF2'
 WHERE object_name='LEGO_ASSIGNMENT_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_EA_EMEA', refresh_object_name_1='ASSIGNMENT_EA_EMEA1', refresh_object_name_2='ASSIGNMENT_EA_EMEA2'
 WHERE object_name='LEGO_ASSIGNMENT_EA' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_EA_IQP', refresh_object_name_1='ASSIGNMENT_EA_IQP1', refresh_object_name_2='ASSIGNMENT_EA_IQP2'
 WHERE object_name='LEGO_ASSIGNMENT_EA' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_EA_WF', refresh_object_name_1='ASSIGNMENT_EA_WF1', refresh_object_name_2='ASSIGNMENT_EA_WF2'
 WHERE object_name='LEGO_ASSIGNMENT_EA' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_TA_EMEA', refresh_object_name_1='ASSIGNMENT_TA_EMEA1', refresh_object_name_2='ASSIGNMENT_TA_EMEA2'
 WHERE object_name='LEGO_ASSIGNMENT_TA' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_TA_IQP', refresh_object_name_1='ASSIGNMENT_TA_IQP1', refresh_object_name_2='ASSIGNMENT_TA_IQP2'
 WHERE object_name='LEGO_ASSIGNMENT_TA' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_TA_WF', refresh_object_name_1='ASSIGNMENT_TA_WF1', refresh_object_name_2='ASSIGNMENT_TA_WF2'
 WHERE object_name='LEGO_ASSIGNMENT_TA' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_WO_EMEA', refresh_object_name_1='ASSIGNMENT_WO_EMEA1', refresh_object_name_2='ASSIGNMENT_WO_EMEA2'
 WHERE object_name='LEGO_ASSIGNMENT_WO' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_WO_IQP', refresh_object_name_1='ASSIGNMENT_WO_IQP1', refresh_object_name_2='ASSIGNMENT_WO_IQP2'
 WHERE object_name='LEGO_ASSIGNMENT_WO' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGNMENT_WO_WF', refresh_object_name_1='ASSIGNMENT_WO_WF1', refresh_object_name_2='ASSIGNMENT_WO_WF2'
 WHERE object_name='LEGO_ASSIGNMENT_WO' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='WO_AMENDMENT_EMEA', refresh_object_name_1='WO_AMENDMENT_EMEA1', refresh_object_name_2='WO_AMENDMENT_EMEA2'
 WHERE object_name='LEGO_WO_AMENDMENT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='WO_AMENDMENT_IQP', refresh_object_name_1='WO_AMENDMENT_IQP1', refresh_object_name_2='WO_AMENDMENT_IQP2'
 WHERE object_name='LEGO_WO_AMENDMENT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='WO_AMENDMENT_WF', refresh_object_name_1='WO_AMENDMENT_WF1', refresh_object_name_2='WO_AMENDMENT_WF2'
 WHERE object_name='LEGO_WO_AMENDMENT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='MISSING_TIME_EMEA', refresh_object_name_1='MISSING_TIME_EMEA1', refresh_object_name_2='MISSING_TIME_EMEA2'
 WHERE object_name='LEGO_MISSING_TIME' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='MISSING_TIME_IQP', refresh_object_name_1='MISSING_TIME_IQP1', refresh_object_name_2='MISSING_TIME_IQP2'
 WHERE object_name='LEGO_MISSING_TIME' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='MISSING_TIME_WF', refresh_object_name_1='MISSING_TIME_WF1', refresh_object_name_2='MISSING_TIME_WF2'
 WHERE object_name='LEGO_MISSING_TIME' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_UDF_ENUM_EMEA', refresh_object_name_1='ASSGNMNT_UDF_ENUM_EMEA1', refresh_object_name_2='ASSGNMNT_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_ASSGNMNT_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_UDF_ENUM_IQP', refresh_object_name_1='ASSGNMNT_UDF_ENUM_IQP1', refresh_object_name_2='ASSGNMNT_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_ASSGNMNT_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_UDF_ENUM_WF', refresh_object_name_1='ASSGNMNT_UDF_ENUM_WF1', refresh_object_name_2='ASSGNMNT_UDF_ENUM_WF2'
 WHERE object_name='LEGO_ASSGNMNT_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_UDF_NOENUM_EMEA', refresh_object_name_1='ASSGNMNT_UDF_NOENUM_EMEA1', refresh_object_name_2='ASSGNMNT_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_ASSGNMNT_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_UDF_NOENUM_IQP', refresh_object_name_1='ASSGNMNT_UDF_NOENUM_IQP1', refresh_object_name_2='ASSGNMNT_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_ASSGNMNT_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_UDF_NOENUM_WF', refresh_object_name_1='ASSGNMNT_UDF_NOENUM_WF1', refresh_object_name_2='ASSGNMNT_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_ASSGNMNT_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_WOV_UDF_ENUM_EMEA', refresh_object_name_1='ASSGNMNT_WOV_UDF_ENUM_EMEA1', refresh_object_name_2='ASSGNMNT_WOV_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_ASSGNMNT_WOV_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_WOV_UDF_ENUM_IQP', refresh_object_name_1='ASSGNMNT_WOV_UDF_ENUM_IQP1', refresh_object_name_2='ASSGNMNT_WOV_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_ASSGNMNT_WOV_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_WOV_UDF_ENUM_WF', refresh_object_name_1='ASSGNMNT_WOV_UDF_ENUM_WF1', refresh_object_name_2='ASSGNMNT_WOV_UDF_ENUM_WF2'
 WHERE object_name='LEGO_ASSGNMNT_WOV_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_WOV_UDF_NOENUM_EMEA', refresh_object_name_1='ASSGNMNT_WOV_UDF_NOENUM_EMEA1', refresh_object_name_2='ASSGNMNT_WOV_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_ASSGNMNT_WOV_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_WOV_UDF_NOENUM_IQP', refresh_object_name_1='ASSGNMNT_WOV_UDF_NOENUM_IQP1', refresh_object_name_2='ASSGNMNT_WOV_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_ASSGNMNT_WOV_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSGNMNT_WOV_UDF_NOENUM_WF', refresh_object_name_1='ASSGNMNT_WOV_UDF_NOENUM_WF1', refresh_object_name_2='ASSGNMNT_WOV_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_ASSGNMNT_WOV_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TENURE_EMEA', refresh_object_name_1='TENURE_EMEA1', refresh_object_name_2='TENURE_EMEA2'
 WHERE object_name='LEGO_TENURE' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='TENURE_IQP', refresh_object_name_1='TENURE_IQP1', refresh_object_name_2='TENURE_IQP2'
 WHERE object_name='LEGO_TENURE' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TENURE_WF', refresh_object_name_1='TENURE_WF1', refresh_object_name_2='TENURE_WF2'
 WHERE object_name='LEGO_TENURE' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='WORKER_ED_UDF_ENUM_EMEA', refresh_object_name_1='WORKER_ED_UDF_ENUM_EMEA1', refresh_object_name_2='WORKER_ED_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_WORKER_ED_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='WORKER_ED_UDF_ENUM_IQP', refresh_object_name_1='WORKER_ED_UDF_ENUM_IQP1', refresh_object_name_2='WORKER_ED_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_WORKER_ED_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='WORKER_ED_UDF_ENUM_WF', refresh_object_name_1='WORKER_ED_UDF_ENUM_WF1', refresh_object_name_2='WORKER_ED_UDF_ENUM_WF2'
 WHERE object_name='LEGO_WORKER_ED_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='WORKER_ED_UDF_NOENUM_EMEA', refresh_object_name_1='WORKER_ED_UDF_NOENUM_EMEA1', refresh_object_name_2='WORKER_ED_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_WORKER_ED_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='WORKER_ED_UDF_NOENUM_IQP', refresh_object_name_1='WORKER_ED_UDF_NOENUM_IQP1', refresh_object_name_2='WORKER_ED_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_WORKER_ED_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='WORKER_ED_UDF_NOENUM_WF', refresh_object_name_1='WORKER_ED_UDF_NOENUM_WF1', refresh_object_name_2='WORKER_ED_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_WORKER_ED_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='MATCH_EMEA', refresh_object_name_1='MATCH_EMEA1', refresh_object_name_2='MATCH_EMEA2'
 WHERE object_name='LEGO_MATCH' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='MATCH_IQP', refresh_object_name_1='MATCH_IQP1', refresh_object_name_2='MATCH_IQP2'
 WHERE object_name='LEGO_MATCH' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='MATCH_WF', refresh_object_name_1='MATCH_WF1', refresh_object_name_2='MATCH_WF2'
 WHERE object_name='LEGO_MATCH' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIME_TO_FILL_EMEA', refresh_object_name_1='TIME_TO_FILL_EMEA1', refresh_object_name_2='TIME_TO_FILL_EMEA2'
 WHERE object_name='LEGO_TIME_TO_FILL' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='TIME_TO_FILL_IQP', refresh_object_name_1='TIME_TO_FILL_IQP1', refresh_object_name_2='TIME_TO_FILL_IQP2'
 WHERE object_name='LEGO_TIME_TO_FILL' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIME_TO_FILL_WF', refresh_object_name_1='TIME_TO_FILL_WF1', refresh_object_name_2='TIME_TO_FILL_WF2'
 WHERE object_name='LEGO_TIME_TO_FILL' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EVALUATION_EMEA', refresh_object_name_1='EVALUATION_EMEA1', refresh_object_name_2='EVALUATION_EMEA2'
 WHERE object_name='LEGO_EVALUATION' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='EVALUATION_IQP', refresh_object_name_1='EVALUATION_IQP1', refresh_object_name_2='EVALUATION_IQP2'
 WHERE object_name='LEGO_EVALUATION' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EVALUATION_WF', refresh_object_name_1='EVALUATION_WF1', refresh_object_name_2='EVALUATION_WF2'
 WHERE object_name='LEGO_EVALUATION' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_EMEA', refresh_object_name_1='EXPENSE_EMEA1', refresh_object_name_2='EXPENSE_EMEA2'
 WHERE object_name='LEGO_EXPENSE' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_IQP', refresh_object_name_1='EXPENSE_IQP1', refresh_object_name_2='EXPENSE_IQP2'
 WHERE object_name='LEGO_EXPENSE' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_WF', refresh_object_name_1='EXPENSE_WF1', refresh_object_name_2='EXPENSE_WF2'
 WHERE object_name='LEGO_EXPENSE' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ERLI_UDF_ENUM_EMEA', refresh_object_name_1='EXPENSE_ERLI_UDF_ENUM_EMEA1', refresh_object_name_2='EXPENSE_ERLI_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_EXPENSE_ERLI_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ERLI_UDF_ENUM_IQP', refresh_object_name_1='EXPENSE_ERLI_UDF_ENUM_IQP1', refresh_object_name_2='EXPENSE_ERLI_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_EXPENSE_ERLI_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ERLI_UDF_ENUM_WF', refresh_object_name_1='EXPENSE_ERLI_UDF_ENUM_WF1', refresh_object_name_2='EXPENSE_ERLI_UDF_ENUM_WF2'
 WHERE object_name='LEGO_EXPENSE_ERLI_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ERLI_UDF_NOENUM_EMEA', refresh_object_name_1='EXPENSE_ERLI_UDF_NOENUM_EMEA1', refresh_object_name_2='EXPENSE_ERLI_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_EXPENSE_ERLI_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ERLI_UDF_NOENUM_IQP', refresh_object_name_1='EXPENSE_ERLI_UDF_NOENUM_IQP1', refresh_object_name_2='EXPENSE_ERLI_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_EXPENSE_ERLI_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ERLI_UDF_NOENUM_WF', refresh_object_name_1='EXPENSE_ERLI_UDF_NOENUM_WF1', refresh_object_name_2='EXPENSE_ERLI_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_EXPENSE_ERLI_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ER_UDF_ENUM_EMEA', refresh_object_name_1='EXPENSE_ER_UDF_ENUM_EMEA1', refresh_object_name_2='EXPENSE_ER_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_EXPENSE_ER_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ER_UDF_ENUM_IQP', refresh_object_name_1='EXPENSE_ER_UDF_ENUM_IQP1', refresh_object_name_2='EXPENSE_ER_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_EXPENSE_ER_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ER_UDF_ENUM_WF', refresh_object_name_1='EXPENSE_ER_UDF_ENUM_WF1', refresh_object_name_2='EXPENSE_ER_UDF_ENUM_WF2'
 WHERE object_name='LEGO_EXPENSE_ER_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ER_UDF_NOENUM_EMEA', refresh_object_name_1='EXPENSE_ER_UDF_NOENUM_EMEA1', refresh_object_name_2='EXPENSE_ER_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_EXPENSE_ER_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ER_UDF_NOENUM_IQP', refresh_object_name_1='EXPENSE_ER_UDF_NOENUM_IQP1', refresh_object_name_2='EXPENSE_ER_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_EXPENSE_ER_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='EXPENSE_ER_UDF_NOENUM_WF', refresh_object_name_1='EXPENSE_ER_UDF_NOENUM_WF1', refresh_object_name_2='EXPENSE_ER_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_EXPENSE_ER_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SC_ASSIGNMENT_DETAIL_EMEA', refresh_object_name_1='SC_ASSIGNMENT_DETAIL_EMEA1', refresh_object_name_2='SC_ASSIGNMENT_DETAIL_EMEA2'
 WHERE object_name='LEGO_SC_ASSIGNMENT_DETAIL' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SC_ASSIGNMENT_DETAIL_IQP', refresh_object_name_1='SC_ASSIGNMENT_DETAIL_IQP1', refresh_object_name_2='SC_ASSIGNMENT_DETAIL_IQP2'
 WHERE object_name='LEGO_SC_ASSIGNMENT_DETAIL' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SC_ASSIGNMENT_DETAIL_WF', refresh_object_name_1='SC_ASSIGNMENT_DETAIL_WF1', refresh_object_name_2='SC_ASSIGNMENT_DETAIL_WF2'
 WHERE object_name='LEGO_SC_ASSIGNMENT_DETAIL' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SC_INTERVIEW_DETAIL_EMEA', refresh_object_name_1='SC_INTERVIEW_DETAIL_EMEA1', refresh_object_name_2='SC_INTERVIEW_DETAIL_EMEA2'
 WHERE object_name='LEGO_SC_INTERVIEW_DETAIL' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SC_INTERVIEW_DETAIL_IQP', refresh_object_name_1='SC_INTERVIEW_DETAIL_IQP1', refresh_object_name_2='SC_INTERVIEW_DETAIL_IQP2'
 WHERE object_name='LEGO_SC_INTERVIEW_DETAIL' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SC_INTERVIEW_DETAIL_WF', refresh_object_name_1='SC_INTERVIEW_DETAIL_WF1', refresh_object_name_2='SC_INTERVIEW_DETAIL_WF2'
 WHERE object_name='LEGO_SC_INTERVIEW_DETAIL' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SC_MATCH_DETAIL_EMEA', refresh_object_name_1='SC_MATCH_DETAIL_EMEA1', refresh_object_name_2='SC_MATCH_DETAIL_EMEA2'
 WHERE object_name='LEGO_SC_MATCH_DETAIL' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SC_MATCH_DETAIL_IQP', refresh_object_name_1='SC_MATCH_DETAIL_IQP1', refresh_object_name_2='SC_MATCH_DETAIL_IQP2'
 WHERE object_name='LEGO_SC_MATCH_DETAIL' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SC_MATCH_DETAIL_WF', refresh_object_name_1='SC_MATCH_DETAIL_WF1', refresh_object_name_2='SC_MATCH_DETAIL_WF2'
 WHERE object_name='LEGO_SC_MATCH_DETAIL' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SC_PREFERRED_SUPPLIER_EMEA', refresh_object_name_1='SC_PREFERRED_SUPPLIER_EMEA1', refresh_object_name_2='SC_PREFERRED_SUPPLIER_EMEA2'
 WHERE object_name='LEGO_SC_PREFERRED_SUPPLIER' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SC_PREFERRED_SUPPLIER_IQP', refresh_object_name_1='SC_PREFERRED_SUPPLIER_IQP1', refresh_object_name_2='SC_PREFERRED_SUPPLIER_IQP2'
 WHERE object_name='LEGO_SC_PREFERRED_SUPPLIER' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SC_PREFERRED_SUPPLIER_WF', refresh_object_name_1='SC_PREFERRED_SUPPLIER_WF1', refresh_object_name_2='SC_PREFERRED_SUPPLIER_WF2'
 WHERE object_name='LEGO_SC_PREFERRED_SUPPLIER' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SUPPLIER_SCORECARD_SUM_EMEA', refresh_object_name_1='SUPPLIER_SCORECARD_SUM_EMEA1', refresh_object_name_2='SUPPLIER_SCORECARD_SUM_EMEA2'
 WHERE object_name='LEGO_SUPPLIER_SCORECARD_SUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='SUPPLIER_SCORECARD_SUM_IQP', refresh_object_name_1='SUPPLIER_SCORECARD_SUM_IQP1', refresh_object_name_2='SUPPLIER_SCORECARD_SUM_IQP2'
 WHERE object_name='LEGO_SUPPLIER_SCORECARD_SUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='SUPPLIER_SCORECARD_SUM_WF', refresh_object_name_1='SUPPLIER_SCORECARD_SUM_WF1', refresh_object_name_2='SUPPLIER_SCORECARD_SUM_WF2'
 WHERE object_name='LEGO_SUPPLIER_SCORECARD_SUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_EMEA', refresh_object_name_1=NULL, refresh_object_name_2=NULL
 WHERE object_name='LEGO_TIMECARD' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_IQP', refresh_object_name_1=NULL, refresh_object_name_2=NULL
 WHERE object_name='LEGO_TIMECARD' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_WF', refresh_object_name_1=NULL, refresh_object_name_2=NULL
 WHERE object_name='LEGO_TIMECARD' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_TE_UDF_ENUM_EMEA', refresh_object_name_1='TIMECARD_TE_UDF_ENUM_EMEA1', refresh_object_name_2='TIMECARD_TE_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_TIMECARD_TE_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_TE_UDF_ENUM_IQP', refresh_object_name_1='TIMECARD_TE_UDF_ENUM_IQP1', refresh_object_name_2='TIMECARD_TE_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_TIMECARD_TE_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_TE_UDF_ENUM_WF', refresh_object_name_1='TIMECARD_TE_UDF_ENUM_WF1', refresh_object_name_2='TIMECARD_TE_UDF_ENUM_WF2'
 WHERE object_name='LEGO_TIMECARD_TE_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_TE_UDF_NOENUM_EMEA', refresh_object_name_1='TIMECARD_TE_UDF_NOENUM_EMEA1', refresh_object_name_2='TIMECARD_TE_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_TIMECARD_TE_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_TE_UDF_NOENUM_IQP', refresh_object_name_1='TIMECARD_TE_UDF_NOENUM_IQP1', refresh_object_name_2='TIMECARD_TE_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_TIMECARD_TE_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_TE_UDF_NOENUM_WF', refresh_object_name_1='TIMECARD_TE_UDF_NOENUM_WF1', refresh_object_name_2='TIMECARD_TE_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_TIMECARD_TE_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_T_UDF_ENUM_EMEA', refresh_object_name_1='TIMECARD_T_UDF_ENUM_EMEA1', refresh_object_name_2='TIMECARD_T_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_TIMECARD_T_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_T_UDF_ENUM_IQP', refresh_object_name_1='TIMECARD_T_UDF_ENUM_IQP1', refresh_object_name_2='TIMECARD_T_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_TIMECARD_T_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_T_UDF_ENUM_WF', refresh_object_name_1='TIMECARD_T_UDF_ENUM_WF1', refresh_object_name_2='TIMECARD_T_UDF_ENUM_WF2'
 WHERE object_name='LEGO_TIMECARD_T_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_T_UDF_NOENUM_EMEA', refresh_object_name_1='TIMECARD_T_UDF_NOENUM_EMEA1', refresh_object_name_2='TIMECARD_T_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_TIMECARD_T_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_T_UDF_NOENUM_IQP', refresh_object_name_1='TIMECARD_T_UDF_NOENUM_IQP1', refresh_object_name_2='TIMECARD_T_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_TIMECARD_T_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='TIMECARD_T_UDF_NOENUM_WF', refresh_object_name_1='TIMECARD_T_UDF_NOENUM_WF1', refresh_object_name_2='TIMECARD_T_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_TIMECARD_T_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_UDF_ENUM_EMEA', refresh_object_name_1='BUS_ORG_UDF_ENUM_EMEA1', refresh_object_name_2='BUS_ORG_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_BUS_ORG_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_UDF_ENUM_IQP', refresh_object_name_1='BUS_ORG_UDF_ENUM_IQP1', refresh_object_name_2='BUS_ORG_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_BUS_ORG_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_UDF_ENUM_WF', refresh_object_name_1='BUS_ORG_UDF_ENUM_WF1', refresh_object_name_2='BUS_ORG_UDF_ENUM_WF2'
 WHERE object_name='LEGO_BUS_ORG_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_UDF_NOENUM_EMEA', refresh_object_name_1='BUS_ORG_UDF_NOENUM_EMEA1', refresh_object_name_2='BUS_ORG_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_BUS_ORG_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_UDF_NOENUM_IQP', refresh_object_name_1='BUS_ORG_UDF_NOENUM_IQP1', refresh_object_name_2='BUS_ORG_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_BUS_ORG_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='BUS_ORG_UDF_NOENUM_WF', refresh_object_name_1='BUS_ORG_UDF_NOENUM_WF1', refresh_object_name_2='BUS_ORG_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_BUS_ORG_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CANDIDATE_UDF_ENUM_EMEA', refresh_object_name_1='CANDIDATE_UDF_ENUM_EMEA1', refresh_object_name_2='CANDIDATE_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_CANDIDATE_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='CANDIDATE_UDF_ENUM_IQP', refresh_object_name_1='CANDIDATE_UDF_ENUM_IQP1', refresh_object_name_2='CANDIDATE_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_CANDIDATE_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CANDIDATE_UDF_ENUM_WF', refresh_object_name_1='CANDIDATE_UDF_ENUM_WF1', refresh_object_name_2='CANDIDATE_UDF_ENUM_WF2'
 WHERE object_name='LEGO_CANDIDATE_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CANDIDATE_UDF_NOENUM_EMEA', refresh_object_name_1='CANDIDATE_UDF_NOENUM_EMEA1', refresh_object_name_2='CANDIDATE_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_CANDIDATE_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='CANDIDATE_UDF_NOENUM_IQP', refresh_object_name_1='CANDIDATE_UDF_NOENUM_IQP1', refresh_object_name_2='CANDIDATE_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_CANDIDATE_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CANDIDATE_UDF_NOENUM_WF', refresh_object_name_1='CANDIDATE_UDF_NOENUM_WF1', refresh_object_name_2='CANDIDATE_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_CANDIDATE_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PERSON_UDF_ENUM_EMEA', refresh_object_name_1='PERSON_UDF_ENUM_EMEA1', refresh_object_name_2='PERSON_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_PERSON_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PERSON_UDF_ENUM_IQP', refresh_object_name_1='PERSON_UDF_ENUM_IQP1', refresh_object_name_2='PERSON_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_PERSON_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PERSON_UDF_ENUM_WF', refresh_object_name_1='PERSON_UDF_ENUM_WF1', refresh_object_name_2='PERSON_UDF_ENUM_WF2'
 WHERE object_name='LEGO_PERSON_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PERSON_UDF_NOENUM_EMEA', refresh_object_name_1='PERSON_UDF_NOENUM_EMEA1', refresh_object_name_2='PERSON_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_PERSON_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PERSON_UDF_NOENUM_IQP', refresh_object_name_1='PERSON_UDF_NOENUM_IQP1', refresh_object_name_2='PERSON_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_PERSON_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PERSON_UDF_NOENUM_WF', refresh_object_name_1='PERSON_UDF_NOENUM_WF1', refresh_object_name_2='PERSON_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_PERSON_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ALL_ORGS_CALENDAR_EMEA', refresh_object_name_1='ALL_ORGS_CALENDAR_EMEA1', refresh_object_name_2='ALL_ORGS_CALENDAR_EMEA2'
 WHERE object_name='LEGO_ALL_ORGS_CALENDAR' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ALL_ORGS_CALENDAR_IQP', refresh_object_name_1='ALL_ORGS_CALENDAR_IQP1', refresh_object_name_2='ALL_ORGS_CALENDAR_IQP2'
 WHERE object_name='LEGO_ALL_ORGS_CALENDAR' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ALL_ORGS_CALENDAR_WF', refresh_object_name_1='ALL_ORGS_CALENDAR_WF1', refresh_object_name_2='ALL_ORGS_CALENDAR_WF2'
 WHERE object_name='LEGO_ALL_ORGS_CALENDAR' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='APPROVAL_EMEA', refresh_object_name_1=NULL, refresh_object_name_2=NULL
 WHERE object_name='LEGO_APPROVAL' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='APPROVAL_IQP', refresh_object_name_1=NULL, refresh_object_name_2=NULL
 WHERE object_name='LEGO_APPROVAL' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='APPROVAL_WF', refresh_object_name_1=NULL, refresh_object_name_2=NULL
 WHERE object_name='LEGO_APPROVAL' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PA_CAC_EMEA', refresh_object_name_1='PA_CAC_EMEA1', refresh_object_name_2='PA_CAC_EMEA2'
 WHERE object_name='LEGO_PA_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PA_CAC_IQP', refresh_object_name_1='PA_CAC_IQP1', refresh_object_name_2='PA_CAC_IQP2'
 WHERE object_name='LEGO_PA_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PA_CAC_WF', refresh_object_name_1='PA_CAC_WF1', refresh_object_name_2='PA_CAC_WF2'
 WHERE object_name='LEGO_PA_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_EMEA', refresh_object_name_1='PROJECT_EMEA1', refresh_object_name_2='PROJECT_EMEA2'
 WHERE object_name='LEGO_PROJECT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_IQP', refresh_object_name_1='PROJECT_IQP1', refresh_object_name_2='PROJECT_IQP2'
 WHERE object_name='LEGO_PROJECT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_WF', refresh_object_name_1='PROJECT_WF1', refresh_object_name_2='PROJECT_WF2'
 WHERE object_name='LEGO_PROJECT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_AGREEMENT_EMEA', refresh_object_name_1='PROJECT_AGREEMENT_EMEA1', refresh_object_name_2='PROJECT_AGREEMENT_EMEA2'
 WHERE object_name='LEGO_PROJECT_AGREEMENT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_AGREEMENT_IQP', refresh_object_name_1='PROJECT_AGREEMENT_IQP1', refresh_object_name_2='PROJECT_AGREEMENT_IQP2'
 WHERE object_name='LEGO_PROJECT_AGREEMENT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_AGREEMENT_WF', refresh_object_name_1='PROJECT_AGREEMENT_WF1', refresh_object_name_2='PROJECT_AGREEMENT_WF2'
 WHERE object_name='LEGO_PROJECT_AGREEMENT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_CAC_EMEA', refresh_object_name_1='PROJECT_CAC_EMEA1', refresh_object_name_2='PROJECT_CAC_EMEA2'
 WHERE object_name='LEGO_PROJECT_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_CAC_IQP', refresh_object_name_1='PROJECT_CAC_IQP1', refresh_object_name_2='PROJECT_CAC_IQP2'
 WHERE object_name='LEGO_PROJECT_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_CAC_WF', refresh_object_name_1='PROJECT_CAC_WF1', refresh_object_name_2='PROJECT_CAC_WF2'
 WHERE object_name='LEGO_PROJECT_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PAYMENT_REQUEST_EMEA', refresh_object_name_1='PAYMENT_REQUEST_EMEA1', refresh_object_name_2='PAYMENT_REQUEST_EMEA2'
 WHERE object_name='LEGO_PAYMENT_REQUEST' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PAYMENT_REQUEST_IQP', refresh_object_name_1='PAYMENT_REQUEST_IQP1', refresh_object_name_2='PAYMENT_REQUEST_IQP2'
 WHERE object_name='LEGO_PAYMENT_REQUEST' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PAYMENT_REQUEST_WF', refresh_object_name_1='PAYMENT_REQUEST_WF1', refresh_object_name_2='PAYMENT_REQUEST_WF2'
 WHERE object_name='LEGO_PAYMENT_REQUEST' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PA_GEO_DESC_EMEA', refresh_object_name_1='PA_GEO_DESC_EMEA1', refresh_object_name_2='PA_GEO_DESC_EMEA2'
 WHERE object_name='LEGO_PA_GEO_DESC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PA_GEO_DESC_IQP', refresh_object_name_1='PA_GEO_DESC_IQP1', refresh_object_name_2='PA_GEO_DESC_IQP2'
 WHERE object_name='LEGO_PA_GEO_DESC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PA_GEO_DESC_WF', refresh_object_name_1='PA_GEO_DESC_WF1', refresh_object_name_2='PA_GEO_DESC_WF2'
 WHERE object_name='LEGO_PA_GEO_DESC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_UDF_ENUM_EMEA', refresh_object_name_1='PROJECT_UDF_ENUM_EMEA1', refresh_object_name_2='PROJECT_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_PROJECT_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_UDF_ENUM_IQP', refresh_object_name_1='PROJECT_UDF_ENUM_IQP1', refresh_object_name_2='PROJECT_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_PROJECT_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_UDF_ENUM_WF', refresh_object_name_1='PROJECT_UDF_ENUM_WF1', refresh_object_name_2='PROJECT_UDF_ENUM_WF2'
 WHERE object_name='LEGO_PROJECT_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_UDF_NOENUM_EMEA', refresh_object_name_1='PROJECT_UDF_NOENUM_EMEA1', refresh_object_name_2='PROJECT_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_PROJECT_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_UDF_NOENUM_IQP', refresh_object_name_1='PROJECT_UDF_NOENUM_IQP1', refresh_object_name_2='PROJECT_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_PROJECT_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJECT_UDF_NOENUM_WF', refresh_object_name_1='PROJECT_UDF_NOENUM_WF1', refresh_object_name_2='PROJECT_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_PROJECT_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGREEMENT_PYMNT_EMEA', refresh_object_name_1='PROJ_AGREEMENT_PYMNT_EMEA1', refresh_object_name_2='PROJ_AGREEMENT_PYMNT_EMEA2'
 WHERE object_name='LEGO_PROJ_AGREEMENT_PYMNT' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGREEMENT_PYMNT_IQP', refresh_object_name_1='PROJ_AGREEMENT_PYMNT_IQP1', refresh_object_name_2='PROJ_AGREEMENT_PYMNT_IQP2'
 WHERE object_name='LEGO_PROJ_AGREEMENT_PYMNT' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGREEMENT_PYMNT_WF', refresh_object_name_1='PROJ_AGREEMENT_PYMNT_WF1', refresh_object_name_2='PROJ_AGREEMENT_PYMNT_WF2'
 WHERE object_name='LEGO_PROJ_AGREEMENT_PYMNT' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGRMT_PA_UDF_ENUM_EMEA', refresh_object_name_1='PROJ_AGRMT_PA_UDF_ENUM_EMEA1', refresh_object_name_2='PROJ_AGRMT_PA_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_PROJ_AGRMT_PA_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGRMT_PA_UDF_ENUM_IQP', refresh_object_name_1='PROJ_AGRMT_PA_UDF_ENUM_IQP1', refresh_object_name_2='PROJ_AGRMT_PA_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_PROJ_AGRMT_PA_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGRMT_PA_UDF_ENUM_WF', refresh_object_name_1='PROJ_AGRMT_PA_UDF_ENUM_WF1', refresh_object_name_2='PROJ_AGRMT_PA_UDF_ENUM_WF2'
 WHERE object_name='LEGO_PROJ_AGRMT_PA_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGRMT_PA_UDF_NOENUM_EMEA', refresh_object_name_1='PROJ_AGRMT_PA_UDF_NOENUM_EMEA1', refresh_object_name_2='PROJ_AGRMT_PA_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_PROJ_AGRMT_PA_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGRMT_PA_UDF_NOENUM_IQP', refresh_object_name_1='PROJ_AGRMT_PA_UDF_NOENUM_IQP1', refresh_object_name_2='PROJ_AGRMT_PA_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_PROJ_AGRMT_PA_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PROJ_AGRMT_PA_UDF_NOENUM_WF', refresh_object_name_1='PROJ_AGRMT_PA_UDF_NOENUM_WF1', refresh_object_name_2='PROJ_AGRMT_PA_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_PROJ_AGRMT_PA_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MID_UDF_ENUM_EMEA', refresh_object_name_1='PYMNT_REQ_MID_UDF_ENUM_EMEA1', refresh_object_name_2='PYMNT_REQ_MID_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_PYMNT_REQ_MID_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MID_UDF_ENUM_IQP', refresh_object_name_1='PYMNT_REQ_MID_UDF_ENUM_IQP1', refresh_object_name_2='PYMNT_REQ_MID_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_PYMNT_REQ_MID_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MID_UDF_ENUM_WF', refresh_object_name_1='PYMNT_REQ_MID_UDF_ENUM_WF1', refresh_object_name_2='PYMNT_REQ_MID_UDF_ENUM_WF2'
 WHERE object_name='LEGO_PYMNT_REQ_MID_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MID_UDF_NOENUM_EMEA', refresh_object_name_1='PYMNT_REQ_MID_UDF_NOENUM_EMEA1', refresh_object_name_2='PYMNT_REQ_MID_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_PYMNT_REQ_MID_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MID_UDF_NOENUM_IQP', refresh_object_name_1='PYMNT_REQ_MID_UDF_NOENUM_IQP1', refresh_object_name_2='PYMNT_REQ_MID_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_PYMNT_REQ_MID_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MID_UDF_NOENUM_WF', refresh_object_name_1='PYMNT_REQ_MID_UDF_NOENUM_WF1', refresh_object_name_2='PYMNT_REQ_MID_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_PYMNT_REQ_MID_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MI_UDF_ENUM_EMEA', refresh_object_name_1='PYMNT_REQ_MI_UDF_ENUM_EMEA1', refresh_object_name_2='PYMNT_REQ_MI_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_PYMNT_REQ_MI_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MI_UDF_ENUM_IQP', refresh_object_name_1='PYMNT_REQ_MI_UDF_ENUM_IQP1', refresh_object_name_2='PYMNT_REQ_MI_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_PYMNT_REQ_MI_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MI_UDF_ENUM_WF', refresh_object_name_1='PYMNT_REQ_MI_UDF_ENUM_WF1', refresh_object_name_2='PYMNT_REQ_MI_UDF_ENUM_WF2'
 WHERE object_name='LEGO_PYMNT_REQ_MI_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MI_UDF_NOENUM_EMEA', refresh_object_name_1='PYMNT_REQ_MI_UDF_NOENUM_EMEA1', refresh_object_name_2='PYMNT_REQ_MI_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_PYMNT_REQ_MI_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MI_UDF_NOENUM_IQP', refresh_object_name_1='PYMNT_REQ_MI_UDF_NOENUM_IQP1', refresh_object_name_2='PYMNT_REQ_MI_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_PYMNT_REQ_MI_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PYMNT_REQ_MI_UDF_NOENUM_WF', refresh_object_name_1='PYMNT_REQ_MI_UDF_NOENUM_WF1', refresh_object_name_2='PYMNT_REQ_MI_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_PYMNT_REQ_MI_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='REQUEST_TO_BUY_EMEA', refresh_object_name_1='REQUEST_TO_BUY_EMEA1', refresh_object_name_2='REQUEST_TO_BUY_EMEA2'
 WHERE object_name='LEGO_REQUEST_TO_BUY' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='REQUEST_TO_BUY_IQP', refresh_object_name_1='REQUEST_TO_BUY_IQP1', refresh_object_name_2='REQUEST_TO_BUY_IQP2'
 WHERE object_name='LEGO_REQUEST_TO_BUY' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='REQUEST_TO_BUY_WF', refresh_object_name_1='REQUEST_TO_BUY_WF1', refresh_object_name_2='REQUEST_TO_BUY_WF2'
 WHERE object_name='LEGO_REQUEST_TO_BUY' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='REQUEST_TO_BUY_CAC_EMEA', refresh_object_name_1='REQUEST_TO_BUY_CAC_EMEA1', refresh_object_name_2='REQUEST_TO_BUY_CAC_EMEA2'
 WHERE object_name='LEGO_REQUEST_TO_BUY_CAC' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='REQUEST_TO_BUY_CAC_IQP', refresh_object_name_1='REQUEST_TO_BUY_CAC_IQP1', refresh_object_name_2='REQUEST_TO_BUY_CAC_IQP2'
 WHERE object_name='LEGO_REQUEST_TO_BUY_CAC' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='REQUEST_TO_BUY_CAC_WF', refresh_object_name_1='REQUEST_TO_BUY_CAC_WF1', refresh_object_name_2='REQUEST_TO_BUY_CAC_WF2'
 WHERE object_name='LEGO_REQUEST_TO_BUY_CAC' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RQ_TO_BUY_RTB_UDF_ENUM_EMEA', refresh_object_name_1='RQ_TO_BUY_RTB_UDF_ENUM_EMEA1', refresh_object_name_2='RQ_TO_BUY_RTB_UDF_ENUM_EMEA2'
 WHERE object_name='LEGO_RQ_TO_BUY_RTB_UDF_ENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='RQ_TO_BUY_RTB_UDF_ENUM_IQP', refresh_object_name_1='RQ_TO_BUY_RTB_UDF_ENUM_IQP1', refresh_object_name_2='RQ_TO_BUY_RTB_UDF_ENUM_IQP2'
 WHERE object_name='LEGO_RQ_TO_BUY_RTB_UDF_ENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RQ_TO_BUY_RTB_UDF_ENUM_WF', refresh_object_name_1='RQ_TO_BUY_RTB_UDF_ENUM_WF1', refresh_object_name_2='RQ_TO_BUY_RTB_UDF_ENUM_WF2'
 WHERE object_name='LEGO_RQ_TO_BUY_RTB_UDF_ENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RQ_TO_BUY_RTB_UDF_NOENUM_EMEA', refresh_object_name_1='RQ_TO_BUY_RTB_UDF_NOENUM_EMEA1', refresh_object_name_2='RQ_TO_BUY_RTB_UDF_NOENUM_EMEA2'
 WHERE object_name='LEGO_RQ_TO_BUY_RTB_UDF_NOENUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='RQ_TO_BUY_RTB_UDF_NOENUM_IQP', refresh_object_name_1='RQ_TO_BUY_RTB_UDF_NOENUM_IQP1', refresh_object_name_2='RQ_TO_BUY_RTB_UDF_NOENUM_IQP2'
 WHERE object_name='LEGO_RQ_TO_BUY_RTB_UDF_NOENUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='RQ_TO_BUY_RTB_UDF_NOENUM_WF', refresh_object_name_1='RQ_TO_BUY_RTB_UDF_NOENUM_WF1', refresh_object_name_2='RQ_TO_BUY_RTB_UDF_NOENUM_WF2'
 WHERE object_name='LEGO_RQ_TO_BUY_RTB_UDF_NOENUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='INVOICE_EMEA', refresh_object_name_1='INVOICE_EMEA1', refresh_object_name_2='INVOICE_EMEA2'
 WHERE object_name='LEGO_INVOICE' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='INVOICE_IQP', refresh_object_name_1='INVOICE_IQP1', refresh_object_name_2='INVOICE_IQP2'
 WHERE object_name='LEGO_INVOICE' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='INVOICE_WF', refresh_object_name_1='INVOICE_WF1', refresh_object_name_2='INVOICE_WF2'
 WHERE object_name='LEGO_INVOICE' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='INV_SUPPLIER_SUBSET_EMEA', refresh_object_name_1='INV_SUPPLIER_SUBSET_EMEA1', refresh_object_name_2='INV_SUPPLIER_SUBSET_EMEA2'
 WHERE object_name='LEGO_INV_SUPPLIER_SUBSET' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='INV_SUPPLIER_SUBSET_IQP', refresh_object_name_1='INV_SUPPLIER_SUBSET_IQP1', refresh_object_name_2='INV_SUPPLIER_SUBSET_IQP2'
 WHERE object_name='LEGO_INV_SUPPLIER_SUBSET' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='INV_SUPPLIER_SUBSET_WF', refresh_object_name_1='INV_SUPPLIER_SUBSET_WF1', refresh_object_name_2='INV_SUPPLIER_SUBSET_WF2'
 WHERE object_name='LEGO_INV_SUPPLIER_SUBSET' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGN_PAYMENT_REQUEST_EMEA', refresh_object_name_1='ASSIGN_PAYMENT_REQUEST_EMEA1', refresh_object_name_2='ASSIGN_PAYMENT_REQUEST_EMEA2'
 WHERE object_name='LEGO_ASSIGN_PAYMENT_REQUEST' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGN_PAYMENT_REQUEST_IQP', refresh_object_name_1='ASSIGN_PAYMENT_REQUEST_IQP1', refresh_object_name_2='ASSIGN_PAYMENT_REQUEST_IQP2'
 WHERE object_name='LEGO_ASSIGN_PAYMENT_REQUEST' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='ASSIGN_PAYMENT_REQUEST_WF', refresh_object_name_1='ASSIGN_PAYMENT_REQUEST_WF1', refresh_object_name_2='ASSIGN_PAYMENT_REQUEST_WF2'
 WHERE object_name='LEGO_ASSIGN_PAYMENT_REQUEST' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='INVCD_EXPENDITURE_SUM_EMEA', refresh_object_name_1='INVCD_EXPENDITURE_SUM_EMEA1', refresh_object_name_2='INVCD_EXPENDITURE_SUM_EMEA2'
 WHERE object_name='LEGO_INVCD_EXPENDITURE_SUM' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='INVCD_EXPENDITURE_SUM_IQP', refresh_object_name_1='INVCD_EXPENDITURE_SUM_IQP1', refresh_object_name_2='INVCD_EXPENDITURE_SUM_IQP2'
 WHERE object_name='LEGO_INVCD_EXPENDITURE_SUM' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='INVCD_EXPENDITURE_SUM_WF', refresh_object_name_1='INVCD_EXPENDITURE_SUM_WF1', refresh_object_name_2='INVCD_EXPENDITURE_SUM_WF2'
 WHERE object_name='LEGO_INVCD_EXPENDITURE_SUM' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PA_CHANGE_REQUEST_EMEA', refresh_object_name_1='PA_CHANGE_REQUEST_EMEA1', refresh_object_name_2='PA_CHANGE_REQUEST_EMEA2'
 WHERE object_name='LEGO_PA_CHANGE_REQUEST' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='PA_CHANGE_REQUEST_IQP', refresh_object_name_1='PA_CHANGE_REQUEST_IQP1', refresh_object_name_2='PA_CHANGE_REQUEST_IQP2'
 WHERE object_name='LEGO_PA_CHANGE_REQUEST' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='PA_CHANGE_REQUEST_WF', refresh_object_name_1='PA_CHANGE_REQUEST_WF1', refresh_object_name_2='PA_CHANGE_REQUEST_WF2'
 WHERE object_name='LEGO_PA_CHANGE_REQUEST' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='REMITTANCE_EMEA', refresh_object_name_1='REMITTANCE_EMEA1', refresh_object_name_2='REMITTANCE_EMEA2'
 WHERE object_name='LEGO_REMITTANCE' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='REMITTANCE_IQP', refresh_object_name_1='REMITTANCE_IQP1', refresh_object_name_2='REMITTANCE_IQP2'
 WHERE object_name='LEGO_REMITTANCE' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='REMITTANCE_WF', refresh_object_name_1='REMITTANCE_WF1', refresh_object_name_2='REMITTANCE_WF2'
 WHERE object_name='LEGO_REMITTANCE' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='INTERVIEW_EMEA', refresh_object_name_1='INTERVIEW_EMEA1', refresh_object_name_2='INTERVIEW_EMEA2'
 WHERE object_name='LEGO_INTERVIEW' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='INTERVIEW_IQP', refresh_object_name_1='INTERVIEW_IQP1', refresh_object_name_2='INTERVIEW_IQP2'
 WHERE object_name='LEGO_INTERVIEW' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='INTERVIEW_WF', refresh_object_name_1='INTERVIEW_WF1', refresh_object_name_2='INTERVIEW_WF2'
 WHERE object_name='LEGO_INTERVIEW' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CAND_SEARCH_EMEA', refresh_object_name_1='CAND_SEARCH_EMEA1', refresh_object_name_2='CAND_SEARCH_EMEA2'
 WHERE object_name='LEGO_CAND_SEARCH' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='CAND_SEARCH_IQP', refresh_object_name_1='CAND_SEARCH_IQP1', refresh_object_name_2='CAND_SEARCH_IQP2'
 WHERE object_name='LEGO_CAND_SEARCH' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CAND_SEARCH_WF', refresh_object_name_1='CAND_SEARCH_WF1', refresh_object_name_2='CAND_SEARCH_WF2'
 WHERE object_name='LEGO_CAND_SEARCH' AND source_name='WFPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CAND_SEARCH_IDX_EMEA', refresh_object_name_1='CAND_SEARCH_IDX_EMEA1', refresh_object_name_2='CAND_SEARCH_IDX_EMEA2'
 WHERE object_name='LEGO_CAND_SEARCH_IDX' AND source_name='EMEA'
/
UPDATE lego_refresh 
   SET synonym_name='CAND_SEARCH_IDX_IQP', refresh_object_name_1='CAND_SEARCH_IDX_IQP1', refresh_object_name_2='CAND_SEARCH_IDX_IQP2'
 WHERE object_name='LEGO_CAND_SEARCH_IDX' AND source_name='USPROD'
/
UPDATE lego_refresh 
   SET synonym_name='CAND_SEARCH_IDX_WF', refresh_object_name_1='CAND_SEARCH_IDX_WF1', refresh_object_name_2='CAND_SEARCH_IDX_WF2'
 WHERE object_name='LEGO_CAND_SEARCH_IDX' AND source_name='WFPROD'
/


COMMIT
/
