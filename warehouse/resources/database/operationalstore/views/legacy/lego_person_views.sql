CREATE OR REPLACE FORCE VIEW LEGO_PERSON_VW
AS
   SELECT bus_org_id,
          person_id,
          user_name,
          last_name,
          first_name,
          middle_name,
          display_name,
          title,
          do_not_rehire_flag,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,
          primary_phone_number AS primary_phone_num,
          daytime_phone_number AS daytime_phone_num,
          evening_phone_number AS evening_phone_num,
          primary_email,
          critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/

CREATE OR REPLACE FORCE VIEW LEGO_PERSON_HIRING_MGR_VW
AS
   SELECT bus_org_id   AS hiring_mgr_bus_org_id,
          person_id    AS hiring_mgr_person_id,
          user_name    AS hiring_mgr_user_name,
          display_name AS hiring_mgr_name,
          title        AS hiring_mgr_title,
          udf_collection_id AS person_udf_collection_id,
    candidate_udf_collection_id,
          primary_phone_number AS hiring_mgr_primary_phone_num,
          daytime_phone_number AS hiring_mgr_daytime_phone_num,
          evening_phone_number AS hiring_mgr_evening_phone_num,
          primary_email        AS hiring_mgr_primary_email,
          critical_email       AS hiring_mgr_critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/

CREATE OR REPLACE FORCE VIEW LEGO_PERSON_ACT_HIRING_MGR_VW
AS
   SELECT bus_org_id   AS act_hiring_mgr_bus_org_id,
          person_id    AS act_hiring_mgr_person_id,
          user_name    AS act_hiring_mgr_user_name,
          display_name AS act_hiring_mgr_name,
          title        AS act_hiring_mgr_title,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,          
          primary_phone_number AS act_hiring_mgr_prim_phone_num,
          daytime_phone_number AS act_hiring_mgr_day_phone_num,
          evening_phone_number AS act_hiring_mgr_even_phone_num,
          primary_email        AS act_hiring_mgr_prim_email,
          critical_email       AS act_hiring_mgr_critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/

CREATE OR REPLACE FORCE VIEW LEGO_PERSON_CAM_VW
AS
   SELECT bus_org_id   AS cam_bus_org_id,
          person_id    AS cam_person_id,
          user_name    AS cam_user_name,
          display_name AS cam_name,
          title        AS cam_title,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,          
          primary_phone_number AS cam_primary_phone_num,
          daytime_phone_number AS cam_daytime_phone_num,
          evening_phone_number AS cam_evening_phone_num,
          primary_email        AS cam_primary_email,
          critical_email       AS cam_critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/

CREATE OR REPLACE FORCE VIEW LEGO_PERSON_SAR_VW
AS
   SELECT bus_org_id   AS sar_bus_org_id,
          person_id    AS sar_person_id,
          user_name    AS sar_user_name,
          display_name AS sar_name,
          title        AS sar_title,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,          
          primary_phone_number AS sar_primary_phone_num,
          daytime_phone_number AS sar_daytime_phone_num,
          evening_phone_number AS sar_evening_phone_num,
          primary_email        AS sar_primary_email,
          critical_email       AS sar_critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/


CREATE OR REPLACE FORCE VIEW LEGO_PERSON_CREATOR_VW
AS
   SELECT bus_org_id   AS creator_bus_org_id,
          person_id    AS creator_person_id,
          user_name    AS creator_user_name,
          display_name AS creator_name,
          title        AS creator_title,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,          
          primary_phone_number AS creator_primary_phone_num,
          daytime_phone_number AS creator_daytime_phone_num,
          evening_phone_number AS creator_evening_phone_num,
          primary_email        AS creator_primary_email,
          critical_email       AS creator_critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/

CREATE OR REPLACE FORCE VIEW LEGO_PERSON_OWNER_VW
AS
   SELECT bus_org_id   AS owner_bus_org_id,
          person_id    AS owner_person_id,
          user_name    AS owner_user_name,
          display_name AS owner_name,
          title        AS owner_title,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,          
          primary_phone_number AS owner_primary_phone_num,
          daytime_phone_number AS owner_daytime_phone_num,
          evening_phone_number AS owner_evening_phone_num,
          primary_email        AS owner_primary_email,
          critical_email       AS owner_critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/

CREATE OR REPLACE FORCE VIEW LEGO_PERSON_CONTRACTOR_VW
AS
   SELECT bus_org_id   AS contractor_bus_org_id,
          person_id    AS contractor_person_id,
          user_name    AS contractor_user_name,
          display_name AS contractor_name,
          title        AS contractor_title,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,          
          primary_phone_number AS contractor_primary_phone_num,
          daytime_phone_number AS contractor_daytime_phone_num,
          evening_phone_number AS contractor_evening_phone_num,
          primary_email        AS contractor_primary_email,
          critical_email       AS contractor_critical_email,
          candidate_id         AS contractor_candidate_id,
          do_not_rehire_flag   AS contractor_do_not_rehire_flag,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/

CREATE OR REPLACE FORCE VIEW LEGO_PERSON_PROJECT_MGR_VW
AS
   SELECT bus_org_id    AS project_mgr_bus_org_id,
          person_id     AS project_mgr_person_id,
          user_name     AS project_mgr_user_name,
          display_name  AS project_mgr_name,
          title         As project_mgr_title,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,          
          primary_phone_number AS project_mgr_primary_phone_num,
          daytime_phone_number AS project_mgr_daytime_phone_num,
          evening_phone_number AS project_mgr_evening_phone_num,
          primary_email        AS project_mgr_primary_email,
          critical_email       AS project_mgr_critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/

CREATE OR REPLACE FORCE VIEW LEGO_PERSON_PA_MANAGER_VW
AS
   SELECT bus_org_id   AS pa_manager_bus_org_id,
          person_id    AS pa_manager_person_id,
          user_name    AS pa_manager_user_name,
          display_name AS pa_manager_name,
          title        AS pa_manager_title,
          udf_collection_id AS person_udf_collection_id,
          candidate_udf_collection_id,                    
          primary_phone_number AS pa_manager_primary_phone_num,
          daytime_phone_number AS pa_manager_daytime_phone_num,
          evening_phone_number AS pa_manager_evening_phone_num,
          primary_email        AS pa_manager_primary_email,
          critical_email       AS pa_manager_critical_email,
          primary_address_guid,
          home_address_guid,
          work_address_guid
     FROM lego_person
/



COMMENT ON TABLE LEGO_PERSON_VW IS
   'This view allows the user to retrieve Person information.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.BUS_ORG_ID IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.last_name IS
   'Value from PERSON table in front office.  This is the Last Name of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.first_name IS
   'Value from PERSON table in front office.  This is the First Name of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.middle_name IS
   'Value from PERSON table in front office.  This is the Middle Name of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.display_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.do_not_rehire_flag IS
   'Flag indicating if the person is not rehireable.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.person_udf_collection_id IS
   'Key to link to User Defined Fields related to the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_HIRING_MGR_VW IS
   'This view allows the user to retrieve Hiring Manager person information.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.hiring_MGR_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_HIRING_MGR_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_ACT_HIRING_MGR_VW IS
   'This view allows the user to retrieve Acting Hiring Manager person information.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_PRIM_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_DAY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_EVEN_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_prim_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.act_hiring_MGR_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_ACT_HIRING_MGR_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_CAM_VW IS
   'This view allows the user to retrieve CAM person information.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.CAM_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CAM_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_SAR_VW IS
   'This view allows the user to retrieve SAR person information.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.SAR_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_SAR_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_CREATOR_VW IS
   'This view allows the user to retrieve CREATOR person information.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.CREATOR_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CREATOR_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_OWNER_VW IS
   'This view allows the user to retrieve OWNER person information.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/
   
COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.OWNER_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_OWNER_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_CONTRACTOR_VW IS
   'This view allows the user to retrieve CONTRACTOR person information.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_CANDIDATE_ID IS
   'Value from CANDIDATE table in front office.  This is the Candidate Id of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.CONTRACTOR_DO_NOT_REHIRE_FLAG IS
   'Flag indicating if the person is not rehireable.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.person_udf_collection_id IS
   'Key to link to User Defined Fields related to the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_CONTRACTOR_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_PROJECT_MGR_VW IS
   'This view allows the user to retrieve PROJECT MANAGER person information.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.project_mgr_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PROJECT_MGR_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/

COMMENT ON TABLE LEGO_PERSON_PA_MANAGER_VW IS
   'This view allows the user to retrieve PROJECT AGREEMENT MANAGER person information.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_bus_org_id IS
   'The Buyer Organization for the person  Unknown Buyer Orgs will be -1.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_person_id IS
   'Value from PERSON table in front office.  Allows the application to retrieve person information with only person id.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_user_name IS
   'Value from IQ_USER table in front office  This is the person''s user name for logging into the application.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_name IS
   'Concatenated value of person.  Format is LAST, FIRST M.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_title IS
   'Value from PERSON table in front office.  This is the Title of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_PRIMARY_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the PRIMARY phone number, if null it is the ORIGINAL phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_DAYTIME_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the DAYTIME phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_EVENING_PHONE_NUM IS
   'Value from LEGO_CONTACT_PHONE_VW and is the EVENING phone number.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_primary_email IS
   'Value from PERSON table in front office.  This is the Primary email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.pa_manager_critical_email IS
   'Value from PERSON table in front office.  This is the Critical email of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.primary_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the PRIMARY address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.home_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the HOME address of the person.'
/

COMMENT ON COLUMN LEGO_PERSON_PA_MANAGER_VW.work_address_guid IS
   'Value from LEGO_CONTACT_ADDRESS.  This is the WORK address of the person.'
/
