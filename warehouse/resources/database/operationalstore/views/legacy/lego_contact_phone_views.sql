/*******************************************************************************
SCRIPT NAME         lego_contact_phone_views.sql 
 
LEGO OBJECT NAME    LEGO_CONTACT_PHONE_VW
 
CREATED             9/26/2012
 
ORIGINAL AUTHOR     Derek Reiner

************************** MODIFICATION HISTORY ********************************

04/29/2014 - P.Muller     - IQN-14202 - removed unused columns from inline view and reformatted.

*******************************************************************************/ 

CREATE OR REPLACE FORCE VIEW lego_contact_phone_vw
AS
SELECT contact_info_id,
       address_id,
       phone_type,
       raw_address                     AS orig_phone_number,
       CAST (CASE 
               WHEN LENGTH (converted_address) >= 10 AND (INSTR (converted_address, '+') = 0 AND INSTR (converted_address, '=') = 0) 
                 THEN TRIM (REGEXP_REPLACE (converted_address, '[^\d]*1?\W*(\d{3})\W*(\d{3})\W*(\d{4})(\se?x?t?(\d*))?', '\1-\2-\3 \5')) 
               WHEN LENGTH (converted_address) = 7 
                 THEN REGEXP_REPLACE (converted_address, '[^\d]*(\d{3})(\d{4})', 'xxx-\1-\2')
               WHEN converted_address IS NULL 
                 THEN NULL 
               ELSE stage1_address 
             END AS VARCHAR2 (100))    AS phone_number
  FROM (SELECT contact_info_fk                       AS contact_info_id,
               address_id,
               name                                  AS phone_type,
               address                               AS raw_address,
               TRIM (REPLACE (TRANSLATE (SUBSTR (A.address, 0, INSTR (A.address, '&#') - 1) || 
                                         SUBSTR (A.address, INSTR (A.address, ';') + 1), '`|#:*"?~''', '        '),
                                          '=', '+')) AS stage1_address,
               REPLACE (TRIM (TRANSLATE (REPLACE (REPLACE (LOWER (SUBSTR (A.address, 0, INSTR (A.address, '&#') - 1) || 
                                                                  SUBSTR (A.address, INSTR (A.address, ';') + 1)), 
                                                           'fax'),
                                                  '=', '+'), 
                                         'abcdefghijklmnopqrstuvwyz:-.,#?|/`~_[]()''', '                                         ')),
                        ' ')                         AS converted_address
          FROM address a
         WHERE address_type = 'F'
           AND name <> 'REFERER'
           AND address IS NOT NULL
           AND INSTR (address, '@') = 0
           AND LENGTH (address) > 2)
 WHERE converted_address IS NULL
    OR converted_address NOT IN
                ('6',
                 '2',
                 '92',
                 'www.exactacorp.com',
                 'xxxxxxxxxx',
                 'xxxxxxxxx',
                 'xxxxxxxx',
                 'xxxxxxx',
                 'xxxxxx',
                 'xxxxx',
                 'xxxx',
                 'xxx',
                 'xx',
                 'x',
                 '*',
                 '99999999999',
                 'x0000000000',
                 '9999999999',
                 '0000000000',
                 '999999999',
                 '000000000',
                 '999999990',
                 '5555555555',
                 '9990009999',
                 '9999991111',
                 '1234567890',
                 '99999999',
                 '00000000',
                 '9999999',
                 '5555555',
                 '0000000',
                 '999999',
                 '000000',
                 '99999',
                 '00000',
                 '9999',
                 '0000',
                 '999',
                 '800',
                 '000',
                 '99',
                 '88',
                 '00',
                 '9',
                 '0')
/


