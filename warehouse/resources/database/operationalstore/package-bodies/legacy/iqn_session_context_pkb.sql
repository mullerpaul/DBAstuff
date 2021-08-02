CREATE OR REPLACE PACKAGE BODY iqn_session_context_pkg AS

   g_source        CONSTANT VARCHAR2(30) := 'IQN_SESSION_CONTEXT_PKG';
   gc_curr_schema  CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');

   PROCEDURE setup_iqn_session_context
      (pi_currentUser         IN NUMBER, 
       pi_currentOrg          IN NUMBER, 
       pi_currentUserIsAdmin  IN CHAR DEFAULT 'N', 
       pi_currentLocalePreference IN NUMBER DEFAULT 0, 
       pi_currentLocaleString IN VARCHAR2 DEFAULT 'en_US')
   AS
      v_source VARCHAR2(30) := 'SETUP_IQN_SESSION_CONTEXT';
   BEGIN
      logger_pkg.set_source(v_source);
      logger_pkg.set_code_location('SET VARS');

      logger_pkg.debug('Set CURRENT_USER to ' || pi_currentUser || ' in ' || gc_curr_schema);
      dbms_session.set_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_USER', pi_currentUser);

      logger_pkg.debug('Set CURRENT_ORG to ' || pi_currentOrg|| ' in ' || gc_curr_schema);
      dbms_session.set_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_ORG', pi_currentOrg);

      logger_pkg.debug('Set CURRENT_USER_IS_ADMIN to ' || pi_currentUserIsAdmin || ' in ' || gc_curr_schema);
      dbms_session.set_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_USER_IS_ADMIN', pi_currentUserIsAdmin);

      logger_pkg.debug('Set CURRENT_LOCALE_PREFERENCE to ' || pi_currentLocalePreference || ' in ' || gc_curr_schema);
      dbms_session.set_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_LOCALE_PREFERENCE', pi_currentLocalePreference);

      logger_pkg.debug('Set CURRENT_LOCALE_STRING to ' || pi_currentLocaleString || ' in ' || gc_curr_schema);
      dbms_session.set_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_LOCALE_STRING', pi_currentLocaleString);

      logger_pkg.unset_source(v_source);
   END setup_iqn_session_context;

   FUNCTION get_current_user
      RETURN NUMBER AS
   BEGIN
      RETURN sys_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_USER');
   END get_current_user;

   FUNCTION get_current_org
      RETURN NUMBER AS
   BEGIN
      RETURN sys_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_ORG');
   END get_current_org;

   FUNCTION get_current_user_is_admin
      RETURN CHAR AS
   BEGIN
      RETURN sys_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_USER_IS_ADMIN');
   END get_current_user_is_admin;

   FUNCTION get_current_locale_preference
      RETURN NUMBER AS
   BEGIN
      RETURN NVL(sys_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_LOCALE_PREFERENCE'),0);
   END get_current_locale_preference;

   FUNCTION get_current_locale_string
      RETURN VARCHAR2 AS
   BEGIN
      RETURN NVL(sys_context(gc_curr_schema || '_IQN_SESSION_CONTEXT', 'CURRENT_LOCALE_STRING'),'en_US');
   END get_current_locale_string;

END iqn_session_context_pkg;
/





