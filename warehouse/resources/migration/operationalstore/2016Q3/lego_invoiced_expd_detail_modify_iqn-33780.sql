
BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE lego_invoiced_expd_detail RENAME COLUMN data_source TO source_name';
EXCEPTION 
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'ALTER TABLE lego_invoiced_expd_detail RENAME COLUMN detail_load_date TO load_date';
EXCEPTION 
  WHEN OTHERS THEN NULL;
END;
/
