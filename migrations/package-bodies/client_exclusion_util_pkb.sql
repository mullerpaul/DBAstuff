CREATE OR REPLACE PACKAGE BODY client_exclusion_util
AS
/******************************************************************************
   NAME:       client_exclusion_util
   PURPOSE:    public functions and procedures which maintain client specific
               exclusions to scoring.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   MSVC-608   04/24/2017  Paul Muller      Created this package.
   MSVC-613   05/08/2017  Paul Muller      Added writes to transaction_log table.
   MSVC-612   06/19/2017  Joe Pullifrone   Convert txn log timestamps to UTC.

******************************************************************************/

  FUNCTION is_valid_type(fi_exclusion_type IN VARCHAR2)
  RETURN BOOLEAN
  IS
    lv_result BOOLEAN := FALSE;
  BEGIN  
    IF (fi_exclusion_type = 'candidate' OR fi_exclusion_type = 'requisition')
      THEN lv_result := TRUE;
    END IF;
    
    RETURN lv_result;
  END is_valid_type;
  
  -----------------------------------------------------------
  PROCEDURE add_exclusion (pi_client_guid    IN RAW,
                           pi_exclusion_type IN VARCHAR2,
                           pi_exclusion_guid IN RAW,
                           pi_txn_guid       IN RAW,
                           pi_session_guid   IN RAW,
                           pi_request_guid   IN RAW)
  IS 
    lv_request_timestamp TIMESTAMP := sys_extract_utc(SYSTIMESTAMP);
    lv_new_exclusion_pk  RAW(16) := sys_guid();
    
  BEGIN
    /* Current design is for this to NOT include a commit or rollback and instead rely 
       on the caller to end transaction.  We may want to revisit this decision later.  */
       
    /*  Move this check into the ELSE of the case?  */
    IF NOT is_valid_type(pi_exclusion_type)
      THEN raise_application_error(-20001, 'Exclusion type must be candidate or requisition');
    END IF;
    
    CASE pi_exclusion_type
      WHEN 'candidate' THEN
        INSERT INTO transaction_log
          (txn_guid, session_guid, request_guid, 
           request_timestamp, processed_timestamp,
           bus_org_guid, 
           entity_name, entity_guid_1,
           message_text)
        VALUES
          (pi_txn_guid, pi_session_guid, pi_request_guid,
           lv_request_timestamp, sys_extract_utc(SYSTIMESTAMP),
           pi_client_guid,
           'excluded_candidate', lv_new_exclusion_pk,
           'Adding exclusion for candidate ' || rawtohex(pi_exclusion_guid) ||
           ' into EXCLUDED_CANDIDATE. New PK is ' || rawtohex(lv_new_exclusion_pk));
          
        INSERT INTO excluded_candidate
          (excluded_candidate_guid, client_guid, candidate_guid, last_txn_guid)
        VALUES
          (lv_new_exclusion_pk, pi_client_guid, pi_exclusion_guid, pi_txn_guid);
          
      WHEN 'requisition' THEN
        INSERT INTO transaction_log
          (txn_guid, session_guid, request_guid, 
           request_timestamp, processed_timestamp,
           bus_org_guid, 
           entity_name, entity_guid_1,
           message_text)
        VALUES
          (pi_txn_guid, pi_session_guid, pi_request_guid,
           lv_request_timestamp, sys_extract_utc(SYSTIMESTAMP),
           pi_client_guid,
           'excluded_requisition', lv_new_exclusion_pk,
           'Adding exclusion for requisition ' || rawtohex(pi_exclusion_guid) ||
           ' into EXCLUDED_CANDIDATE. New PK is ' || rawtohex(lv_new_exclusion_pk));

        INSERT INTO excluded_requisition
          (excluded_requisition_guid, client_guid, requisition_guid, last_txn_guid)
        VALUES
          (lv_new_exclusion_pk, pi_client_guid, pi_exclusion_guid, pi_txn_guid);
          
    END CASE;    
    
  END add_exclusion;  

  -----------------------------------------------------------
  PROCEDURE remove_exclusion (pi_client_guid    IN RAW,
                              pi_exclusion_type IN VARCHAR2,
                              pi_exclusion_guid IN RAW,
                              pi_txn_guid       IN RAW,
                              pi_session_guid   IN RAW,
                              pi_request_guid   IN RAW)
  IS 
    lv_request_timestamp    TIMESTAMP := sys_extract_utc(SYSTIMESTAMP);
    lv_deleted_exclusion_pk RAW(16);
    
  BEGIN
    /* Deleting rather than marking as inactive in hopes of keeping these 
       exclusions tables as small as possible */
       
    IF NOT is_valid_type(pi_exclusion_type)
      THEN raise_application_error(-20001, 'Exclusion type must be candidate or requisition');
    END IF;

    /* The combination of client guid and exclusion guid is Unique on these tables
       so we know we will be deleting either one row or no rows. 
       Do we need some sort of return condidtion to show when no rows were deleted?  */
    CASE pi_exclusion_type
      WHEN 'candidate' THEN
        DELETE from excluded_candidate
         WHERE client_guid = pi_client_guid
           AND candidate_guid = pi_exclusion_guid
        RETURN excluded_candidate_guid
          INTO lv_deleted_exclusion_pk;

        IF SQL%rowcount > 0 THEN
          INSERT INTO transaction_log
            (txn_guid, session_guid, request_guid, 
             request_timestamp, processed_timestamp,
             bus_org_guid, 
             entity_name, entity_guid_1,
             message_text)
          VALUES
            (pi_txn_guid, pi_session_guid, pi_request_guid,
             lv_request_timestamp, sys_extract_utc(SYSTIMESTAMP),
             pi_client_guid,
             'excluded_candidate', lv_deleted_exclusion_pk,
             'Removed exclusion for candidate ' || rawtohex(pi_exclusion_guid) ||
             ' from EXCLUDED_CANDIDATE. Old PK was ' || rawtohex(lv_deleted_exclusion_pk));

        END IF;

      WHEN 'requisition' THEN
        DELETE from excluded_requisition
         WHERE client_guid = pi_client_guid
           AND requisition_guid = pi_exclusion_guid
        RETURN excluded_requisition_guid
          INTO lv_deleted_exclusion_pk;

        IF SQL%rowcount > 0 THEN
          INSERT INTO transaction_log
            (txn_guid, session_guid, request_guid, 
             request_timestamp, processed_timestamp,
             bus_org_guid, 
             entity_name, entity_guid_1,
             message_text)
          VALUES
            (pi_txn_guid, pi_session_guid, pi_request_guid,
             lv_request_timestamp, sys_extract_utc(SYSTIMESTAMP),
             pi_client_guid,
             'excluded_requisition', lv_deleted_exclusion_pk,
             'Removed exclusion for requisition ' || rawtohex(pi_exclusion_guid) ||
             ' from EXCLUDED_REQUISITION. Old PK was ' || rawtohex(lv_deleted_exclusion_pk));

        END IF;

    END CASE;    

  END remove_exclusion;  

END client_exclusion_util;
/
