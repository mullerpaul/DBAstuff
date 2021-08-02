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
    ('LEGO_INVD_EXPD_DATE_RU',
     'USPROD',
     'PROCEDURE ONLY',
     'EVERY FOUR HOURS',
     22,
     3,
     NULL,
     NULL,
     NULL,
     NULL,
     'lego_invoice.invoice_load')
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
    ('LEGO_INVD_EXPD_DATE_RU',
     'WFPROD',
     'PROCEDURE ONLY',
     'EVERY FOUR HOURS',
     22,
     4,
     NULL,
     NULL,
     NULL,
     NULL,
     'lego_invoice.invoice_load')
/
COMMIT
/     