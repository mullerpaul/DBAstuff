/* The purpose of this script is to create a sequence to be used with the DM_CURRENCY_DIM table.
   The script assumes that the table already exists (which is a reasonable assumption) and is not already using a sequence.  */

DECLARE

  v_last_seq_id PLS_INTEGER;

BEGIN

  SELECT MAX(currency_dim_id) + 1
    INTO v_last_seq_id
    FROM dm_currency_dim;

  EXECUTE IMMEDIATE 'CREATE SEQUENCE dm_currency_dim_seq
                       MINVALUE 1
                       INCREMENT BY 1
                       START WITH '||v_last_seq_id;
END;
/