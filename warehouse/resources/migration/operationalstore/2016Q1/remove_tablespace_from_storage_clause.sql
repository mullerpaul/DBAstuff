-- We no longer have LEGO_USERS tablespace.  Its been replaced with the WAREHOUSE_BF tablespace in prod.
-- BUT, since thats our schema's default tablespace AND thats the only tablespace where we will have any 
-- access, there is really no need to specify a tablespace in our table (or index) creates.  

UPDATE lego_refresh
   SET storage_clause = 'NOLOGGING'
 WHERE (storage_clause LIKE 'NOLOGGING TABLESPACE LEGO_USERS%' OR storage_clause = 'TABLESPACE lego_users')
/

UPDATE lego_refresh
   SET storage_clause = REPLACE (storage_clause, 'TABLESPACE LEGO_USERS')
 WHERE NOT (storage_clause LIKE 'NOLOGGING TABLESPACE LEGO_USERS%' OR storage_clause = 'TABLESPACE lego_users')
   AND storage_clause LIKE '(user_id,%'
/

COMMIT
/

