CREATE OR REPLACE PACKAGE resource_iq
/******************************************************************************
     NAME:      RESOURCE_IQ
     PURPOSE:   This package contains all the procedures related to ResourceIQ
  
     REVISIONS: 
     Ver     Date        Author        Description
     ------  ----------  ------------  ------------------------------------
     1.0     06/09/2014  pkattula      Initial Version
     2.0     07/29/2014  pkattula      Enhancements to perform search/scoring
                                       based on OracleText Multi-ColumnIndex
     3.0     08/04/2014  mdunlap       Revamp base query with all-inclusive 
                                       lego_cand_search (get_candidate_list2)
									   Keep original for benchmarking.                                     
******************************************************************************/
AS
   c_jt_weight NUMBER;
   c_jd_weight NUMBER;
   c_jl_weight NUMBER;
   c_js_weight NUMBER;

   PROCEDURE get_candidate_list
   (
       p_buyerorg_id             IN  lego_buyer_org_vw.buyer_org_id%TYPE
     , p_days_till_end           IN  lego_assignment_vw.days_until_assignment_end%TYPE
     , p_months_since_completed  IN  lego_assignment_vw.days_until_assignment_end%TYPE
     , p_manager_id              IN  lego_assignment_vw.hiring_mgr_person_id%TYPE
                                     -- NULL if Hiring Manager is permitted to view other HM's resources
                                     -- Otherwise Hirming Manager's person ID is expected here
     , p_job_title               IN  lego_cand_search.job_position_title%TYPE
                                     -- Job Title selected from list of prior Job Titles used
     , p_title_words             IN  lego_cand_search.job_position_title%TYPE
                                     -- Free form text of Job related words including Skills and/or Roles
                                     -- and/or Job Description etc.
                                     -- Oracle Text based match will be performed only if
                                     -- at least one of the (p_job_title, p_title_words) is NOT NULL
                                     -- and match score is returned for each candidate
                                     -- Otherwise no matching will be done and scores will be defaulted to 0
     , p_candidate_list          OUT SYS_REFCURSOR
   );

   PROCEDURE get_candidate_list2
   (
       p_buyerorg_id             IN  lego_buyer_org_vw.buyer_org_id%TYPE
     , p_days_till_end           IN  lego_assignment_vw.days_until_assignment_end%TYPE
     , p_months_since_completed  IN  lego_assignment_vw.days_until_assignment_end%TYPE
     , p_manager_id              IN  lego_assignment_vw.hiring_mgr_person_id%TYPE
                                     -- NULL if Hiring Manager is permitted to view other HM's resources
                                     -- Otherwise Hirming Manager's person ID is expected here
     , p_job_title               IN  lego_cand_search.job_position_title%TYPE
                                     -- Job Title selected from list of prior Job Titles used
     , p_title_words             IN  lego_cand_search.job_position_title%TYPE
                                     -- Free form text of Job related words including Skills and/or Roles
                                     -- and/or Job Description etc.
                                     -- Oracle Text based match will be performed only if
                                     -- at least one of the (p_job_title, p_title_words) is NOT NULL
                                     -- and match score is returned for each candidate
                                     -- Otherwise no matching will be done and scores will be defaulted to 0
     , p_candidate_list          OUT SYS_REFCURSOR
   );
   
   PROCEDURE load_usage_data ( p_buyerorg_id             IN  lego_buyer_org_vw.buyer_org_id%TYPE DEFAULT NULL
                             , p_manager_id              IN  lego_assignment_vw.hiring_mgr_person_id%TYPE DEFAULT NULL
                             , p_job_title               IN  lego_cand_search.job_position_title%TYPE DEFAULT NULL
                             , p_title_words             IN  lego_cand_search.job_position_title%TYPE DEFAULT NULL
                             , p_personid                IN  lego_assignment_vw.hiring_mgr_person_id%TYPE DEFAULT NULL
                             , v_param_filter            IN VARCHAR2 DEFAULT NULL 
        )  ;     
   
   PROCEDURE load_scoring_weights;
END resource_iq;
/

