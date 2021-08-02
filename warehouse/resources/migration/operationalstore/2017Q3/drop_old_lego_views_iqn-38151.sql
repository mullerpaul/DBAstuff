DECLARE
  lv_no_such_view EXCEPTION;
  PRAGMA EXCEPTION_INIT(lv_no_such_view, -942);

BEGIN

BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW bo_curr_conv_gl_daily_rates_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_address_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_approval_workflow_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_assignment_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_assignment_cac_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_assignment_dashboard_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_assignment_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_assign_managed_cac_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_assign_payment_request_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_bus_org_hq_addr_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_bus_org_notice_addr_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_bus_org_payment_addr_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_bus_org_primary_addr_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_buyer_org_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_calendar_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_contact_address_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_contact_email_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_contact_phone_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_contact_web_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_currency_conv_rates_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_evaluation_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_expenditures_sum_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_expense_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_expense_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_interview_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_invoice_detail_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_invoice_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_inv_supplier_subset_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_job_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_job_cac_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_job_opportunity_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_job_supplier_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_job_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_job_work_location_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_match_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_missing_time_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_mi_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_payment_request_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_pa_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_pa_change_request_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_pa_geo_desc_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_pa_managed_cac_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_act_hiring_mgr_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_cam_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_contractor_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_creator_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_hiring_mgr_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_owner_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_pa_manager_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_project_mgr_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_sar_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_person_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_place_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_project_agreement_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_project_agree_cac_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_project_cac_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_project_rfx_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_project_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_proj_agreement_payment_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_pr_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_p_res_prop_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_ratecard_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_refresh_all_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_refresh_current_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_refresh_object_state_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_remittance_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_reqs_by_status_nonsec_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_reqs_by_status_sec_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_request_to_buy_cac_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_request_to_buy_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_req_to_buy_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_rfx_cac_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_rfx_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_supplier_org_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_timecard_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_timecard_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_time_to_fill_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_workorder_approvals_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW lego_wo_amendment_vw';
EXCEPTION
  WHEN lv_no_such_view THEN NULL;
END;


END;
/