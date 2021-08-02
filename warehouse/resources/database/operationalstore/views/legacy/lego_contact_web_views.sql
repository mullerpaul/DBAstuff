/* Formatted on 9/26/2012 8:59:00 AM (QP5 v5.163.1008.3004) */

CREATE OR REPLACE FORCE VIEW lego_contact_web_vw
AS
   SELECT contact_info_fk contact_info_id,
          address_id,
          name web_type,
          REGEXP_REPLACE (RTRIM (CASE WHEN SUBSTR (LOWER (REPLACE (address, '''')), 1, 7) IN ('hhtp://', 'http://', 'http:\\') THEN SUBSTR (LOWER (REPLACE (address, '''')), 8, 9999) WHEN SUBSTR (LOWER (REPLACE (address, '''')), 1, 8) IN ('https://') THEN SUBSTR (LOWER (REPLACE (address, '''')), 9, 9999) WHEN SUBSTR (LOWER (REPLACE (address, '''')), 1, 5) IN ('http.') THEN SUBSTR (LOWER (REPLACE (address, '''')), 6, 9999) WHEN SUBSTR (LOWER (REPLACE (address, '''')), 1, 4) IN ('www,') THEN 'www.' || SUBSTR (LOWER (REPLACE (address, '''')), 5, 9999) WHEN SUBSTR (LOWER (REPLACE (address, '''')), 1, 3) IN ('ww.') THEN 'www.' || SUBSTR (LOWER (REPLACE (address, '''')), 4, 9999) ELSE LOWER (REPLACE (address, '''')) END, '/'), '([&#[:digit:]]*)+;', ('\1')) web_address
     FROM address
    WHERE     contact_info_fk != -1
          AND address_type = 'E'
          AND name IN ('BusinessURL', 'Web')
          AND address IS NOT NULL
          AND address NOT IN ('nobody@otho.iqnavigator.com')
          AND address NOT LIKE 'null@%'
          AND INSTR (address, '@') = 0
          AND INSTR (address, ' ') = 0
          AND INSTR (address, '.') > 1
/
