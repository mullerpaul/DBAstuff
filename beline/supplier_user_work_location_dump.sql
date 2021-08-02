-- there are 3 addresses on person and 4 on supplier orgs!
-- which is the "supplier user work location"??
-- I don't think there is any way to know.
-- But what we can do is choose the fields that have the most rows populated with the "most unique" data 
select count(*),
       count(lp.primary_Address_guid), count(lp.home_address_guid), count(lp.work_address_guid),
       count(distinct lp.primary_Address_guid), count(distinct lp.home_address_guid), count(distinct lp.work_address_guid),
       count(lso.supplier_primary_address_guid), count(lso.supplier_hq_address_guid), count(lso.supplier_payment_address_guid), count(lso.supplier_notice_address_guid),
       count(distinct lso.supplier_primary_address_guid), count(distinct lso.supplier_hq_address_guid), count(distinct lso.supplier_payment_address_guid), count(distinct lso.supplier_notice_address_guid)
  from lego_person_vw lp,
       lego_supplier_org_vw lso
 where lp.bus_org_id = lso.supplier_org_id
;

-- lets focus on the "primary address" on the person and the "supplier primary" address on the supplier (though that one is close - the payment and notice addresses could just as well be it)
select lp.person_id, lp.display_name,
       lso.supplier_enterprise_name,
       -- la_p.*, la_s.*,   --for debugging and figuring out formatting.
       la_p.line1 || ' ' || la_p.city || ' ' || la_p.state || ' ' || la_p.postal_code as person_primary_address,
       la_s.line1 || ' ' || la_s.city || ' ' || la_s.state || ' ' || la_s.postal_code as supplier_primary_Address
  from lego_person_vw lp,
       lego_supplier_org_vw lso,
       lego_address la_p,  -- for person primary address
       lego_Address la_s   -- for supplier primary address 
 where lp.bus_org_id = lso.supplier_org_id
   and lp.primary_address_guid = la_p.address_guid(+)  --outer in case there is no address or the address lego is stale
   and lso.supplier_primary_address_guid = la_s.address_guid(+) --outer in case there is no address or the address lego is stale
;

-- that is really 'dumb' formatting.  There are many rows where that will not work well.
--- the person primary address seems to have a lot of less-than-stellar data.
