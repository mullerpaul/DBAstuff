CREATE OR REPLACE FORCE VIEW jasper_currency_conv_gtt_vw
AS
SELECT to_currency_fk, from_conversion_date, to_conversion_date, to_currency_code
FROM (SELECT to_currency_fk, from_conversion_date, to_conversion_date, to_currency_code
        FROM (SELECT to_currency_fk, from_conversion_date, to_conversion_date, to_currency_code, '1' tab_id
                FROM jasper_currency_conv_gtt
               UNION ALL
              SELECT NULL to_currency_fk, NULL from_conversion_date, NULL to_conversion_date, NULL to_currency_code, '2' tab_id
                FROM dual)
       ORDER BY tab_id)
WHERE rownum =1
/
