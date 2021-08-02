create or replace PACKAGE lego_invoice AS

  /*  Table Reference 
      
      LEGO_OBJECT - metadata about which tables get loaded.  Intially consists of
                    LEGO_INVOICED_EXPD_DETAIL and LEGO_INVD_EXPD_DATE_RU.
                            
      LEGO_INVOICE_APPROVED - controls and starts the loading process for any object (table) listed 
                              in lego_object.  These are approved invoices whose details are 
                              ready to be pulled from FO and into the DM.  Partitioned by object_name
                              and source_name.
                              
      LEGO_BUYERS_BY_ENT_INV_GTT - Since the FO invoice table only holds owner_bus_org_id, we need to reach 
                                   back into FO (invoiced_buyer_supplier) to get and store all the APPROVED
                                   invoices and their actual buyer_org_id values for each buyer_enterprise_bus_org_id 
                                   that we just pulled and are now storing in lego_invoice_approved.  This data 
                                   set represents all invoices that exist in lego_invoice_approved that have not been
                                   loaded into the target table(s).                              
                              
      LEGO_PART_BY_ENTERPRISE_GTT - Holds data selected from user_tab_partitions that represent all 
                                    existing partitions (not subpartitions) and the comma-delimited
                                    list of buyer orgs (high_value).  Each partition represents an enterprise
                                    and the partition values are the buyer orgs under that enterprise.
                                    Since the high_value is a LONG data-type, we needed to perform an INSERT
                                    INTO or CTAS to convert it to a CLOB.  From there we can TO_CHAR the values
                                    and parse them out to create a row for each buyer org, to determine if there
                                    are new buyer orgs that joined the enterprise.  After the parsing, the data
                                    is populated in LEGO_PART_BY_ENT_BUYER_ORG_GTT.
                                    
                                    
      LEGO_PART_BY_ENT_BUYER_ORG_GTT - Based on lego_part_by_enterprise, once the high_value column is parsed,
                                       this is where we store a row for each buyer org of each enterprise
                                       that is representd in user_tab_partitions.  In other words, it answers 
                                       the question, "which buyer orgs are currently represented in each of my
                                       table's partitions?"
                                       
      LEGO_INVOICED_EXPD_DETAIL - Lowest level of invoice detail.  Should be used to build other rollups.
      
      LEGO_INVD_EXPD_DATE_RU    - Rollup for DM Custom Reporting.  Aggregated to level of expenditure_number,
                                  expenditure_date, transaction_type. */
 
    
  
  /* This is an off-cycle, manual run of the load that you can do outside of the 
     Refresh Mgr regular run.  It is helpful to use this on the first initial 
     load so that it does not interfere with the regular refresh process.  The
     input parameter for pi_start_ts can be set to indicate that you wish the 
     job to run at some day/time in the future as opposed to "right now." */
  PROCEDURE off_cycle_invoice_load (pi_object_name IN lego_object.object_name%TYPE,
                                    pi_source      IN lego_object.source_name%TYPE,
                                    pi_start_ts    IN TIMESTAMP DEFAULT SYSTIMESTAMP);
                                       
  /* This is a full "start over" reload of the detail table.  IT COULD DROP ALL
     PARTITIONS IN THE TABLE.  You can pass in a a value to indicate whether 
     you want to either drop ALL partitions or truncate the entire table. 
     Passing in value for pi_source will NOT just drop or truncate for that source
     because the source_name value is mixed within the partitions.  You pass in 
     the source_name to indicate which source you'd like to load follwing the 
     drop partition or truncate.  */
  PROCEDURE reload_invoices (pi_object_name     IN lego_object.object_name%TYPE,
                             pi_source          IN lego_object.source_name%TYPE,
                             pi_start_ts        IN TIMESTAMP DEFAULT SYSTIMESTAMP,
                             pi_drop_partition  IN BOOLEAN   DEFAULT FALSE); 
                                    
  /* This will allow you to drop a single partition in any invoice table.  After
     the partition is dropped, it will execute the off-cycle load,
     off_cycle_invoice_load, based on the input paramter value for the object
     and source you enter.  A value of 'ALL' for source will execute All surces.  
     Otherwise, you can specify only one source and it will run for only that 
     source.  Keep in mind that dropping a partition will wipe out all sources in
     that partition since each partition has potentially multiple sources.
     If no partition is dropped, for whatever reason, the off-cycle load will NOT run. */     
  PROCEDURE reload_part_invoice (pi_object_name          IN lego_object.object_name%TYPE,
                                 pi_source               IN lego_object.source_name%TYPE,
                                 pi_buyer_ent_bus_org_id IN lego_invoice_approved.buyer_enterprise_bus_org_id%TYPE,
                                 pi_start_ts             IN TIMESTAMP DEFAULT SYSTIMESTAMP);                                    
                                       
  /* This will allow you to remove the records for a single invoice.  It will remove 
     the record from LEGO_INVOICE_APPROVED and LEGO_INVD_EXPD_DATE_RU. Unable to 
     delete from LEGO_INVOICED_EXPD_DETAIL since it is a source for a FAST REFRESH MV. */     
  PROCEDURE remove_invoice (pi_source              IN lego_object.source_name%TYPE,                            
                            pi_owning_buyer_org_id IN lego_invoice_approved.owning_buyer_org_id%TYPE,
                            pi_buyer_org_id        IN lego_invd_expd_date_ru.buyer_org_id%TYPE,
                            pi_invoice_id          IN lego_invoice_approved.invoice_id%TYPE); 
                                  
  /* This is a job that will drop the DBMS_SCHEDULER job that is created only
     by the execution of off_cycle_invoice_load. This will not work for the 
     job created by the Refresh Mgr. An input parm for source is not needed
     because you cannot run loads for more than one source at a time for the 
     same table.  */
  PROCEDURE drop_oc_invd_exp_job (pi_object_name IN lego_object.object_name%TYPE);                                       
  
  
  /* This is the load job that is called only from the Refresh Mgr. It will
     handle a full, initial load or an incremental load. */
  PROCEDURE invoice_load (pi_object_name IN lego_object.object_name%TYPE,
                          pi_source      IN lego_object.source_name%TYPE);
                          
  /* This is a maintenance procedure to do thigns like create/drop index and 
     gather stats. pi_proces_stage is either BEGIN, MAINT, or END.  */
  PROCEDURE index_maint (pi_object_name   IN lego_object.object_name%TYPE,
                         pi_process_stage IN VARCHAR2);                          
  

  
END lego_invoice;
/