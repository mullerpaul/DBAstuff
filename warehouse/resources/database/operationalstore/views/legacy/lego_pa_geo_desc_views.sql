CREATE OR REPLACE FORCE VIEW LEGO_PA_GEO_DESC_VW
AS
SELECT lp.project_agreement_version_id,
       LISTAGG(NVL(pa_place_jcl.constant_description, lp.pa_geo_desc),'; ')  WITHIN GROUP (ORDER BY NVL(pa_place_jcl.constant_description, lp.pa_geo_desc)) AS pa_geo_desc
  FROM lego_pa_geo_desc lp,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'PLACE'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) pa_place_jcl,
       (SELECT lp2.project_agreement_version_id
          FROM lego_pa_geo_desc lp2,
               (SELECT constant_value, constant_description
                  FROM lego_java_constant_lookup
                 WHERE constant_type    = 'PLACE'
                   AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) pa2_place_jcl
         WHERE lp2.place_id = pa2_place_jcl.constant_value(+) 
         GROUP BY lp2.project_agreement_version_id
         HAVING SUM(LENGTH(NVL(pa2_place_jcl.constant_description, lp2.pa_geo_desc))) + (COUNT(NVL(pa2_place_jcl.constant_description, lp2.pa_geo_desc)) *2) -2 < 4000
        ) pav_cnt
WHERE lp.place_id = pa_place_jcl.constant_value(+)
  AND lp.project_agreement_version_id = pav_cnt.project_agreement_version_id
GROUP BY lp.project_agreement_version_id
/

