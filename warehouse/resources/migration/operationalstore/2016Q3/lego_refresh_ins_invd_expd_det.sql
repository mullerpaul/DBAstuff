INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name,
     refresh_procedure_name)
  VALUES
    ('LEGO_INVOICED_EXPD_DETAIL',
     'USPROD',
     'PROCEDURE ONLY',
     'EVERY FOUR HOURS',
     22,
     1,
     NULL,
     NULL,
     NULL,
     NULL,
     'lego_invoice.load_invoiced_exp_detail')
/     

INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name,
     refresh_procedure_name)
  VALUES
    ('LEGO_INVOICED_EXPD_DETAIL',
     'WFPROD',
     'PROCEDURE ONLY',
     'EVERY FOUR HOURS',
     22,
     2,
     NULL,
     NULL,
     NULL,
     NULL,
     'lego_invoice.load_invoiced_exp_detail')
/
COMMIT
/     