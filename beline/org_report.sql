-- can we make a nice report which shows org hierarchy, and nice stats like if each org has invoices, assignments, projects, etc?
-- i think so.  And it shouldn't be to tough.

-- lets start with a list of clients (top-level orgs) which are recieving invoices.
-- I'll ASSUME thats a good way to know if a client is "Active" or not.

select --count(distinct lbo.bus_org_Type)
       distinct lbo.buyer_enterprise_name
  from iqprod.invoice i,
--       iqprodd.lego_bus_org_1 lbo
       iqprodd.lego_buyer_org_vw lbo
 where i.business_organization_fk = lbo.buyer_org_id
   and i.create_date > trunc(add_months(sysdate, -3), 'MM')
   ;
-- good - only buyers get invoices (just checking!)  we can switch to the buyer view   
--after changing over and counting distinct enterprise name , we find 108 distinct clients getting invoices.  Thats in the right ballpark.

  with who_gets_invoices  -- a proxy for "Active" clients
    as (select distinct x.buyer_enterprise_name
          from iqprod.invoice i,
               iqprodd.lego_buyer_org_vw x
         where i.business_organization_fk = x.buyer_org_id
           and i.create_date > trunc(add_months(sysdate, -3), 'MM')),   -- has to be a recent invoice
       org_data
    as (select lbo.buyer_enterprise_name, lbo.buyer_managing_org_name, 
               lbo.buyer_org_id, lbo.buyer_parent_bus_org_id, lbo.buyer_rule_org_id,
               lbo.buyer_name, lbo.inheritance_mode, 
               inherit_org.buyer_name as inherit_org_name, 
               CASE 
                 WHEN exists (select NULL from invoice i 
                               where i.business_organization_fk = lbo.buyer_org_id 
                                 and i.create_date > trunc(add_months(sysdate, -3), 'MM'))
                   THEN 'Y'
                 ELSE 'N'
               END as has_invoices,  
               CASE 
                 WHEN exists (select NULL from assignment_continuity ac 
                               where ac.owning_buyer_firm_fk = lbo.buyer_firm_id 
                                 and ac.has_ever_been_effective = 1
                                 and ac.is_archived = 0)
                   THEN 'Y'
                 ELSE 'N'
               END as has_assignments,  
               CASE 
                 WHEN exists (select NULL from iqprod.project p 
                               where p.buyer_firm_fk = lbo.buyer_firm_id)
                   THEN 'Y'
                 ELSE 'N'
               END as has_projects  
          from iqprodd.lego_buyer_org_vw lbo,
               who_gets_invoices w,
               iqprodd.lego_buyer_org_vw inherit_org
         where lbo.buyer_enterprise_name = w.buyer_enterprise_name
           and lbo.buyer_rule_org_id = inherit_org.buyer_org_id)
select buyer_enterprise_name, buyer_managing_org_name, 
       level as org_depth,
       lpad(' ', 3 * (level - 1), ' ') || buyer_name as buyer_org_name,
       has_invoices, has_assignments, has_projects, 
       CASE when inheritance_mode = 'INHERIT_ALL' then inherit_org_name else 'none' end as inheritance_from
  from org_data
connect by prior buyer_org_id = buyer_parent_bus_org_id
start with buyer_parent_bus_org_id is null
;

  -- verified that inheritance_mode maps directly buyer_org_id = buyer_rule_org_id.  
  -- If mode is none, then the two org values are the same.  If mode is ALL, the org ids are different.
  -- added self-join to the org view in the ORG_DATA block to get the inherited from org name.  use CASE
  -- in main query to display the name in case of inheritance.  Else show "none"
