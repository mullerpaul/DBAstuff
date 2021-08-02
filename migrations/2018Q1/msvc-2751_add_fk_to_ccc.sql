ALTER TABLE client_category_coefficient
ADD CONSTRAINT client_ctgry_coefficient_fk01
FOREIGN KEY (last_txn_guid)
REFERENCES transaction_log 
/

