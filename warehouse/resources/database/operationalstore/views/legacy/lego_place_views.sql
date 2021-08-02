/* Formatted on 11/14/2012 2:12:12 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE FORCE VIEW lego_place_vw
AS
   SELECT p.VALUE place_id,
          p.TYPE place_type,
          sp.VALUE standard_place_id,
          sp.description standard_place_desc,
          p.business_org_fk buyer_org_id,
          p.line1,
          p.line2,
          p.line3,
          p.line4,
          NVL (TRIM (TRANSLATE (p.city, ',-', '  ')), TRIM (TRANSLATE (sp.city, ',-', '  '))) city
          , p.county,
          NVL (p.state, sp.state) state,
          NVL (c.VALUE, sc.VALUE) country_id,
          NVL (c.description, sc.description) country,
          NVL (c.country_code, sc.country_code) country_code,
          p.postal_code,
          p.attribute1,
          p.attribute2,
          p.attribute3,
          p.attribute4,
          p.attribute5,
          TRIM (TRANSLATE (sp.city, ',-', '  ')) standard_city,
          sp.state standard_state,
          sc.description standard_country,
          sc.country_code standard_country_code
     FROM place p, country c, place sp, country sc
    WHERE     p.country = c.VALUE(+)
          AND p.standard_place_fk = sp.VALUE(+)
          AND sp.country = sc.VALUE(+)
/
