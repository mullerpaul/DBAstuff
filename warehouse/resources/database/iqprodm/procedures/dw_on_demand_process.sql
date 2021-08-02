Create or replace procedure DW_ON_DEMAND_PROCESS( in_fact_type IN VARCHAR2 DEFAULT 'NONE')
IS
/*****************************************************
 * Parameter     		Purpose
 --------------------------------------------
 * TIME_TO_FILL  		Refresh Time To Fill FACT only
 * INVOICE_FACT  		Refresh Invoice Spend FACT only
 * INVOICE_HC_FACT 		Refresh Invoice Headcount FACT only
 * HC_FACT         		Refresh Headcount FACT only
 * No arguments    		Refresh all FACTs 
 ******************************************************/   
	ln_date_id NUMBER := TO_NUMBER(TO_CHAR(sysdate,'YYYYMMDD'));
BEGIN
    DM_CURRENCY_CONVERSION_DATA.populate_rates;

    DIM_DAILY_PROCESS;

    IF ( upper(in_fact_type) = 'TIME_TO_FILL' ) THEN
            dm_tt_fill_fact_process.p_main;
    ELSIF ( upper(in_fact_type) = 'INVOICE_FACT' ) THEN
        fo_data.p_main@FO_R;
        fo_minislice.p_main@FO_R;
        invoice_spend_all_process;
        DM_INVOICED_CAC_DIM_PROCESS.p_main('REGULAR',ln_date_id);
        upd_cube_dim_load_status(ln_date_id,'SPEND_CUBE-DIM');
        dm_invoice_fact_process.p_main;
    ELSIF ( upper(in_fact_type) = 'INVOICE_HC_FACT' ) THEN
        fo_data.p_main@FO_R;
        fo_minislice.p_main@FO_R;
        invoice_spend_all_process;
        dm_inv_headcount_fact_process.p_main;
    ELSIF ( upper(in_fact_type) = 'HC_FACT' ) THEN
        dm_headcount_fact_process.p_main;
    ELSE --refresh all Facts
        fo_data.p_main@FO_R;
        fo_minislice.p_main@FO_R;
        invoice_spend_all_process;
        DM_INVOICED_CAC_DIM_PROCESS.p_main('REGULAR',ln_date_id);
        upd_cube_dim_load_status(ln_date_id,'SPEND_CUBE-DIM');
        dm_invoice_fact_process.p_main;
        dm_inv_headcount_fact_process.p_main;
        dm_headcount_fact_process.p_main;
        dm_tt_fill_fact_process.p_main;
    END IF;

END DW_ON_DEMAND_PROCESS;
/

