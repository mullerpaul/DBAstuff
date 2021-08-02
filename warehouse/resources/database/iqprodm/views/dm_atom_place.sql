CREATE OR REPLACE FORCE VIEW dm_atom_place AS
WITH region AS (
SELECT rpm.std_place_id, rg.std_country_id, rg.std_region_id, rg.std_region_desc
  FROM dm_region_place_map rpm, 
       dm_regions rg
 WHERE rg.std_region_id      = rpm.std_region_id
   AND rg.std_region_type_id = 6)
SELECT atm.assignment_continuity_id,
       atm.std_buyerorg_id,
       db.std_buyerorg_name,
       atm.std_supplierorg_id,
       ds.std_supplierorg_name,       
       p.std_place_id,
       p.std_country_id,
       p.std_state,
       p.std_city,
       p.std_country_name AS std_country,
       p.std_postal_code,  
       region.std_region_id,    
       region.std_region_desc AS std_region,       
       c.cmsa_code,
       c.cmsa_name,
       c.metro_name,
       c.primary_state_code AS cmsa_primary_state_code,
       c.primary_city_name  AS cmsa_primary_city_name,
       c.latitude AS cmsa_primary_city_lat,
       c.longitude AS cmsa_primary_city_long,
       atm.buyer_org_id,
       atm.supplier_org_id,
       atm.data_source_code
 FROM dm_places p, 
      region,
      dm_cmsa c,
      dm_buyers db,
      dm_suppliers ds,
      dm_atom_assign_xref atm
WHERE p.std_place_id         = region.std_place_id
  AND p.std_country_id       = region.std_country_id
  AND p.cmsa_code            = c.cmsa_code
  AND atm.std_place_id       = p.std_place_id        
  AND atm.std_buyerorg_id    = db.std_buyerorg_id
  AND atm.std_supplierorg_id = ds.std_supplierorg_id 
/
