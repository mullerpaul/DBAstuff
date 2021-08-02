/* The purpose of this script is to drop and recreate the sequence, curr_conv_dim_seq, which is used for DM_CURRENCY_CONVERSION_RATES.
   Doing this because the sequence is out of sync with the table. */

DECLARE

  v_last_seq_id PLS_INTEGER;

BEGIN

  EXECUTE IMMEDIATE 'DROP SEQUENCE curr_conv_dim_seq';

  SELECT MAX(curr_conv_dim_id) + 1
    INTO v_last_seq_id
    FROM dm_currency_conversion_rates;

  EXECUTE IMMEDIATE 'CREATE SEQUENCE curr_conv_dim_seq
                       MINVALUE 1
                       INCREMENT BY 1
                       START WITH '||v_last_seq_id;
END;
/