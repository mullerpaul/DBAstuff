/* IQN-42131 
 * Invoice incorectly created and approved for Accenture Portugal December Invoice 257634
 * After running a script to update the invoice date from 12/31/2019 to 12/31/2018 in IQPROD schema,
 * this migration script will delete invoice 257634 so the legos process can pick up the latest changes
 */
BEGIN
    operationalstore.lego_invoice.remove_invoice(
		pi_source 				=> 'USPROD', 
		pi_owning_buyer_org_id 	=> 141771, 
		pi_buyer_org_id 		=> 141771, 
		pi_invoice_id 			=> 257634 
	);

END;
/
