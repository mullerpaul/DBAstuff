BEGIN
  EXECUTE IMMEDIATE 'REVOKE SELECT ON t_review_benchmarks FROM ro_iqprodm';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'REVOKE SELECT ON iqnlabs_benchmarks FROM ro_iqprodm';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/