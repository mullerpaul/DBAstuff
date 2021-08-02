CREATE OR REPLACE FORCE VIEW available_orgs_view 
AS
SELECT bol1.descendant_bus_org_fk AS available_org_id
  FROM bus_org_lineage bol1, 
       bus_org_lineage bol2, 
       organization_assignment_vw oa
 WHERE bol1.descendant_bus_org_fk = bol2.descendant_bus_org_fk
   AND bol1.ancestor_bus_org_fk   = (SELECT IQN_SESSION_CONTEXT_PKG.get_current_org FROM dual)
   AND bol2.ancestor_bus_org_fk   = oa.organization_fk
   AND oa.is_enabled              = 1
   AND oa.owning_person_fk        = (SELECT IQN_SESSION_CONTEXT_PKG.get_current_user FROM dual)
   AND oa.organization_scope      = 'ALL_DESCENDANTS'
 UNION
SELECT bol.descendant_bus_org_fk AS available_org_id
  FROM bus_org_lineage bol, 
       organization_assignment_vw oa
 WHERE bol.ancestor_bus_org_fk    = (SELECT IQN_SESSION_CONTEXT_PKG.get_current_org FROM dual)
   AND bol.descendant_bus_org_fk  = oa.organization_fk
   AND oa.is_enabled              = 1
   AND oa.owning_person_fk        = (SELECT IQN_SESSION_CONTEXT_PKG.get_current_user FROM dual)
   AND oa.organization_scope      = 'ORGANIZATION_ONLY'
 UNION
SELECT bol1.descendant_bus_org_fk AS available_org_id
  FROM bus_org_lineage bol1
 WHERE bol1.ancestor_bus_org_fk   = (SELECT IQN_SESSION_CONTEXT_PKG.get_current_org FROM dual)
   AND (SELECT IQN_SESSION_CONTEXT_PKG.get_current_user_is_admin FROM dual) = 'Y'
/
