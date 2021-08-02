CREATE OR REPLACE PACKAGE iqn_session_context_pkg AS
/**
  Purpose: Package to set information about the current context (e.g. current user, currently selected org)
  into session context for use from the database side
**/

   PROCEDURE setup_iqn_session_context
      (pi_currentUser         IN NUMBER,
       pi_currentOrg          IN NUMBER,
       pi_currentUserIsAdmin  IN CHAR DEFAULT 'N',
       pi_currentLocalePreference IN NUMBER DEFAULT 0,
       pi_currentLocaleString IN VARCHAR2 DEFAULT 'en_US');

   FUNCTION get_current_user RETURN NUMBER;

   FUNCTION get_current_org RETURN NUMBER;

   FUNCTION get_current_user_is_admin RETURN CHAR;

   FUNCTION get_current_locale_preference RETURN NUMBER;

   FUNCTION get_current_locale_string RETURN VARCHAR2;

END iqn_session_context_pkg;
/


