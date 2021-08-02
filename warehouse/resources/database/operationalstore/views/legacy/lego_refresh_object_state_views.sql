CREATE OR REPLACE FORCE VIEW lego_refresh_object_state_vw
   (object_name, 
    refresh_method, 
    refresh_schedule, 
    next_refresh_time,
    synonym_name, 
    curr_table_name, 
    refresh_sql,
    refresh_object_name_1, 
    refresh_object_name_2, 
    exadata_storage_clause, 
    partition_column_name, 
    partition_clause, 
    subpartition_column_name, 
    subpartition_clause, 
    num_partitions_to_swap,
    refresh_procedure_name)
AS
SELECT lr.object_name,
       lr.refresh_method,
       lr.refresh_schedule,
       lr.next_refresh_time,
       us.synonym_name,
       us.table_name AS curr_table_name,
       lr.refresh_sql,
       lr.refresh_object_name_1,
       lr.refresh_object_name_2,
       lr.exadata_storage_clause,
       lr.partition_column_name,
       lr.partition_clause,
       lr.subpartition_column_name,
       lr.subpartition_clause,
       lr.num_partitions_to_swap,
       lr.refresh_procedure_name
  FROM lego_refresh lr, 
       user_synonyms us
 WHERE lr.object_name = us.synonym_name(+)
/



