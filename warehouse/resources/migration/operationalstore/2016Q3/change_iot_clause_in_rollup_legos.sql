-- req by status
UPDATE lego_refresh
   SET storage_clause = q'{(login_user_id, login_org_id, current_phase, jc_description, requisition_count, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_org_id, login_user_id, current_phase, jc_description)) ORGANIZATION INDEX COMPRESS 1 NOLOGGING}'
 WHERE object_name = 'LEGO_REQ_BY_STATUS_ROW_ROLLUP'
/
UPDATE lego_refresh
   SET storage_clause = q'{(login_user_id, login_org_id, current_phase, jc_description, requisition_count, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_org_id, login_user_id, current_phase, jc_description)) ORGANIZATION INDEX COMPRESS 2 NOLOGGING}'
 WHERE object_name = 'LEGO_REQ_BY_STATUS_ORG_ROLLUP'
/

-- monthly assignment count and spend
UPDATE lego_refresh
   SET storage_clause = q'{(login_user_id, login_org_id, month_start, monthly_assignment_count, monthly_invoiced_buyer_spend, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_user_id, login_org_id, month_start)) ORGANIZATION INDEX COMPRESS 2 NOLOGGING}'
 WHERE object_name IN ('LEGO_MNTH_ASGN_CNTSPND_ORGROLL','LEGO_MNTH_ASGN_CNTSPND_ROWROLL')
/

-- upcoming ends
UPDATE lego_refresh
   SET storage_clause = q'{(login_user_id, login_org_id, days_until_assignment_end, job_category, assignment_count, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_user_id, login_org_id, days_until_assignment_end, job_category)) ORGANIZATION INDEX COMPRESS 2 NOLOGGING}'
 WHERE object_name = 'LEGO_UPCOMING_ENDS_ROW_ROLLUP'
/
UPDATE lego_refresh
   SET storage_clause = q'{(login_user_id, login_org_id, days_until_assignment_end, job_category, assignment_count, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_user_id, login_org_id, days_until_assignment_end, job_category)) ORGANIZATION INDEX COMPRESS 1 NOLOGGING}'
 WHERE object_name = 'LEGO_UPCOMING_ENDS_ORG_ROLLUP'
/

-- assignments by state
UPDATE lego_refresh
   SET storage_clause = q'{(login_user_id, login_org_id, cmsa_primary_state_code, effective_assgn_count, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_user_id, login_org_id, cmsa_primary_state_code)) ORGANIZATION INDEX COMPRESS 1 NOLOGGING}'
 WHERE object_name = 'LEGO_ASSGN_LOC_ST_ATOM_RR'
/
UPDATE lego_refresh
   SET storage_clause = q'{(login_org_id, login_user_id, cmsa_primary_state_code, effective_assgn_count, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_user_id, login_org_id, cmsa_primary_state_code)) ORGANIZATION INDEX COMPRESS 2 NOLOGGING}'
 WHERE object_name = 'LEGO_ASSGN_LOC_ST_ATOM_OR'
/

--- woot!
COMMIT
/


