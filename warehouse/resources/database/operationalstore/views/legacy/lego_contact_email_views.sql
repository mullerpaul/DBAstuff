/* Formatted on 9/26/2012 8:59:00 AM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE FORCE VIEW lego_contact_email_vw
AS
   SELECT contact_info_fk contact_info_id,
          address_id,
          name email_type,
          REGEXP_REPLACE (LOWER (REPLACE (address, '''')), '([&#[:digit:]]*)+;', ('\1')) email_address
     FROM address
    WHERE     contact_info_fk != -1
          AND address_type = 'E'
          AND name NOT IN ('BusinessURL', 'Web')
          AND address IS NOT NULL
          AND address NOT IN ('nobody@otho.iqnavigator.com')
          AND address NOT LIKE 'null@%'
          AND INSTR (address, '@') > 1
          AND INSTR (address, ' ') = 0
          AND INSTR (address, '.') > 1
/
