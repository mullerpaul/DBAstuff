CREATE OR REPLACE PACKAGE foid_guid_map_maint AS

  PROCEDURE load_job_foid_guid_map(pi_object_name IN lego_refresh.object_name%TYPE,
                                   pi_source      IN lego_refresh.source_name%TYPE);

  PROCEDURE load_job_opp_foid_guid_map(pi_object_name IN lego_refresh.object_name%TYPE,
                                       pi_source      IN lego_refresh.source_name%TYPE);

  PROCEDURE load_match_foid_guid_map(pi_object_name IN lego_refresh.object_name%TYPE,
                                     pi_source      IN lego_refresh.source_name%TYPE);


END foid_guid_map_maint;
/