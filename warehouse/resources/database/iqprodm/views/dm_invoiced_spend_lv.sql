/****************************************************
 * Name: dm_invoiced_spend_lv  ( lv--> local view)
 * Date: 11/26/08
 * Author: Manoj
 *****************************************************
 MODIFICATION HISTORY
 * Author        Date        Jira   History
 * -----------------------------------------------------------------
 * J.Pullifrone 08/10/2016   IQN-33780 change to point to new table,
                             lego_invd_expd_date_ru.
   J.Pullifrone 09/12/2016   IQN-34535 view was overwritten during 16.10 
                             release.  Nothing changing here.

   The following fields are NOT set in the original view and therefore are set 
   to NULL here as well.
   
   invoice_number_supplier
   invoice_due_date
   supp_invoice_number
   supp_invoice_date */
  
CREATE OR REPLACE FORCE VIEW dm_invoiced_spend_lv AS
SELECT buyer_org_id    AS buyer_bus_org_fk,               
       buyer_name      AS buyer_bus_org_name,             
       supplier_org_id AS supplier_bus_org_fk,            
       supplier_name   AS supplier_bus_org_name,          
       invoice_id      AS invoice_number,                 
       NULL AS invoice_number_supplier,        
       invoice_date,                   
       NULL AS invoice_due_date,               
       expenditure_number,             
       transaction_type,               
       expenditure_date,               
       week_ending_date,               
       work_order_id,                  
       work_order_type,                
       customer_supplier_internal_id,  
       accounting_code,                
       buyer_resource_id,              
       buyer_fee,                      
       supplier_fee,                   
       total_fee,                      
       cac1_segment1_value AS cac1_seg1_value,                
       cac1_segment2_value AS cac1_seg2_value,                
       cac1_segment3_value AS cac1_seg3_value,                
       cac1_segment4_value AS cac1_seg4_value,                
       cac1_segment5_value AS cac1_seg5_value,                
       cac2_segment1_value AS cac2_seg1_value,                
       cac2_segment2_value AS cac2_seg2_value,                
       cac2_segment3_value AS cac2_seg3_value,                
       cac2_segment4_value AS cac2_seg4_value,                
       cac2_segment5_value AS cac2_seg5_value,                
       contractor_name AS curr_contractor_full_name,      
       contractor_person_id,           
       currency,                       
       hiring_mgr_name AS hm_full_name,                   
       hiring_mgr_person_id AS hm_person_id,                   
       spend_category,                 
       spend_type,                     
       buyer_adjusted_amount,          
       supplier_reimbursement_amount,            
       quantity,
       base_bill_rate,
       buyer_adjusted_bill_rate,
       base_pay_rate, 
       supplier_reimbursement_rate, 
       markup_pct, 
       job_title, 
       supplier_reference_num, 
       assignment_start_date, 
       assignment_end_date, 
       expenditure_approved_date, 
       expenditure_approver,      
       expenditure_approver_pid,      
       job_id,       
       job_category,
       job_level,
       supplier_resource_id,
       project_agreement_id,
       project_agreement_name,
       NULL AS supp_invoice_number,
       NULL AS supp_invoice_date
  FROM operationalstore.lego_invd_expd_date_ru
/  