--wrapping these in execute immediates so they don't error in non-standard envs like dm01 and im01. jpullifrone
BEGIN
  EXECUTE IMMEDIATE 'REVOKE SELECT ON lego_invoice_approved FROM iqprodm';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'REVOKE SELECT ON lego_buyers_by_ent_inv_gtt FROM iqprodm';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'REVOKE SELECT ON lego_part_by_enterprise_gtt FROM iqprodm';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'REVOKE SELECT ON lego_part_by_ent_buyer_org_gtt FROM iqprodm';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
