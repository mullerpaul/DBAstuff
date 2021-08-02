CREATE OR REPLACE FORCE VIEW lego_locale_pref_score_vw
AS
SELECT session_locale_pref, 
       data_locale_pref,
       score
  FROM lego_locale_pref_score
/


