CREATE OR REPLACE PACKAGE dm_cube_utils
/******************************************************************************
 * Name:   dm_cube_utils
 * Desc:   This package contains all the utility/common program units
 *         required for spend
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj   08/06/2010    Initial 
 *******************************************************************************/
AS
 /*****************************************************************
  * Name: get_country_dim_id
  * Desc: This function gets the Country Dimension Identifer
  *****************************************************************/
  FUNCTION get_country_dim_id(iv_country_name IN VARCHAR2)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_currency_dim_id
  * Desc: This function gets the Currency Dimension Identifer
  *****************************************************************/
  FUNCTION get_currency_dim_id(iv_currency IN VARCHAR2)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_time_dim_id
  * Desc: This function gets the Time Dimension Identifer
  *****************************************************************/
  FUNCTION get_time_dim_id(id_date IN DATE)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_engagement_type_dim_id
  * Desc: This function gets the Engagement Type Dimension Identifer
  *****************************************************************/
  FUNCTION get_engagement_type_dim_id(iv_engagement_type IN VARCHAR2)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_project_agreement_dim_id
  * Desc: This function gets the Engagement Type Dimension Identifer
  *****************************************************************/
  FUNCTION get_project_agreement_dim_id(in_pa_id            IN NUMBER,
                                        id_invoice_date     IN DATE,
                                        iv_data_source_code IN VARCHAR2,
                                        in_buyer_org_id     IN NUMBER)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_job_dim_id
  * Desc: This function gets the Job Dimension Identifer
  *****************************************************************/
  FUNCTION get_job_dim_id(in_job_id           IN NUMBER,
                          id_invoice_date     IN DATE,
                          iv_data_source_code IN VARCHAR2,
                          in_buyer_org_id     IN NUMBER)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_invoiced_cac_dim_id
  * Desc: This function gets the Job Dimension Identifer
  *****************************************************************/
  FUNCTION get_invoiced_cac_dim_id(in_buyerorg_id      IN NUMBER,
                                   iv_cac1_seg1_value  IN VARCHAR2,
                                   iv_cac1_seg2_value  IN VARCHAR2,
                                   iv_cac1_seg3_value  IN VARCHAR2,
                                   iv_cac1_seg4_value  IN VARCHAR2,
                                   iv_cac1_seg5_value  IN VARCHAR2,
                                   iv_cac2_seg1_value  IN VARCHAR2,
                                   iv_cac2_seg2_value  IN VARCHAR2,
                                   iv_cac2_seg3_value  IN VARCHAR2,
                                   iv_cac2_seg4_value  IN VARCHAR2,
                                   iv_cac2_seg5_value  IN VARCHAR2,
                                   iv_data_source_code IN VARCHAR2)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_expenditure_dim_id
  * Desc: This function gets the expenditure Dimension Identifer
  *****************************************************************/
  FUNCTION get_expenditure_dim_id(iv_spend_category   IN VARCHAR2,
                                  iv_spend_type       IN VARCHAR2,
                                  iv_fo_bo_flag       IN VARCHAR2)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_geo_dim_id
  * Desc: This function gets the Geo Dimension Identifer
  *****************************************************************/
  FUNCTION get_geo_dim_id
   (
       p_country_name dm_country_dim.iso_country_name%TYPE
     , p_state_name   dm_geo_dim.state_name%TYPE
     , p_city_name    dm_geo_dim.city_name%TYPE
     , p_postal_code  dm_geo_dim.postal_code%TYPE
   )
   RETURN dm_geo_dim.geo_dim_id%TYPE;

 /*****************************************************************
  * Name: get_ratecard_dim_id
  * Desc: This function gets the Rate Card Dimension Identifer
  *****************************************************************/
  FUNCTION get_ratecard_dim_id
       (in_assign_id              IN NUMBER,
       in_data_source_code       IN VARCHAR2,
       in_buyer_org_id           IN NUMBER)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_person_dim_id
  * Desc: This function gets the Rate Card Dimension Identifer
  *****************************************************************/
  FUNCTION get_person_dim_id
       (in_person_id        IN NUMBER
       ,in_invoice_date     IN DATE
       ,in_data_source_code IN VARCHAR2
       ,in_buyer_org_id     IN NUMBER)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_organization_dim_id
  * Desc: This function gets the Organization Dimension Identifer
  *****************************************************************/
  FUNCTION get_organization_dim_id
    (
        p_org_id           IN dm_organization_dim.org_id%TYPE
      , p_invoice_date     IN DATE
      , p_data_source_code IN VARCHAR2
    )
  RETURN dm_organization_dim.org_dim_id%TYPE;

 /**********************************************************************
  * Name: get_org_geo_dim_id
  * Desc: This function gets the Organization's Geo Dimension Identifer
  **********************************************************************/
  FUNCTION get_org_geo_dim_id
    (
        p_org_id           IN dm_organization_dim.org_id%TYPE
      , p_invoice_date     IN DATE
      , p_data_source_code IN VARCHAR2
    )
  RETURN dm_organization_dim.primary_geo_dim_id%TYPE;

 /*****************************************************************
  * Name: get_expenditure_category
  * Desc: This function gets the expenditure category
  *****************************************************************/
  FUNCTION get_expenditure_category(iv_spend_category   IN VARCHAR2,
                                  iv_spend_type       IN VARCHAR2,
                                  iv_fo_bo_flag       IN VARCHAR2)
  RETURN VARCHAR2;

 /*****************************************************************
  * Name: get_assignment_actual_end_date
  * Desc: This function gets the Actual end date of the assignment from
  *       dm_assignment table
  *****************************************************************/
  FUNCTION get_assignment_actual_end_date(in_assign_id        IN NUMBER,
                                          iv_data_source_code IN VARCHAR2)
  RETURN DATE;

 /*****************************************************************
  * Name: get_work_loc_geo_dim_id
  * Desc: This function gets the Geo Dimension Identifer for
  *       work location
  *****************************************************************/
  FUNCTION get_work_loc_geo_dim_id
   (in_assign_id        IN NUMBER,
    iv_data_source_code IN VARCHAR2)
  RETURN dm_geo_dim.geo_dim_id%TYPE;

 /*****************************************************************
  * Name: get_iqn_expenditure_category
  * Desc: This function gets the IQN expenditure category
  *****************************************************************/
  FUNCTION get_iqn_expenditure_category(iv_spend_category   IN VARCHAR2,
                                        iv_spend_type       IN VARCHAR2,
                                        iv_fo_bo_flag       IN VARCHAR2)
  RETURN VARCHAR2;
 /*****************************************************************
  * Name: get_iqn_expenditure_tyep
  * Desc: This function gets the IQN expenditure type
  *****************************************************************/
  FUNCTION get_iqn_expenditure_type(iv_spend_category   IN VARCHAR2,
                                    iv_spend_type       IN VARCHAR2,
                                    iv_fo_bo_flag       IN VARCHAR2)
  RETURN VARCHAR2;

/*****************************************************************
  * Name: get_worker_dim_id
  * Desc: This function gets the Worker Dimension ID
  *****************************************************************/
FUNCTION get_worker_dim_id(in_worker_id           IN NUMBER,
                          id_date     IN DATE,
                          iv_data_source_code IN VARCHAR2)
  RETURN NUMBER;

/*****************************************************************
  * Name: get_top_org_id
  * Desc: This function returns the top parent id for a buyer org dim id.
  *****************************************************************/
 FUNCTION get_top_org_id(in_buyer_org_dim_id IN NUMBER)
  RETURN NUMBER;

/*****************************************************************
  * Name: get_top_parent_org_id
  * Desc: This function returns the top parent id for a buyer org id.
  *****************************************************************/
 FUNCTION get_top_parent_org_id(in_buyer_org_id IN NUMBER)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_date_dim_id
  * Desc: This function gets the Date Dimension Identifer
  *****************************************************************/
  FUNCTION get_date_dim_id(in_top_parent_buyer_org IN NUMBER, in_data_source_code IN VARCHAR2,id_date IN DATE)
  RETURN NUMBER;

/*****************************************************************
  * Name: get_data_source_id
  * Desc: This function gets the data source id
  *****************************************************************/
  FUNCTION get_data_source_id(in_data_source_code IN VARCHAR2)
  RETURN NUMBER;

 /*****************************************************************
  * Name: get_buyer_country_name
  * Desc: This function gets the buyer country name
  *****************************************************************/
  FUNCTION get_buyer_country_name
    (
        p_org_id           IN dm_organization_dim.org_id%TYPE
      , p_data_source_code IN VARCHAR2
    ) RETURN dm_organization_dim.FO_COUNTRY_NAME%TYPE;

/******************************************************************************
 * Name: get_usd_rate
 * Desc: Function to get usd converted rate
 *******************************************************************************/
 FUNCTION get_usd_rate(in_currency_code IN VARCHAR2, in_date IN DATE)
 RETURN NUMBER;

/******************************************************************************
 * Name: get_usd_amount
 * Desc: Function to get usd converted amount
 *******************************************************************************/
 FUNCTION get_usd_amount(in_currency_code IN VARCHAR2, in_date IN DATE,in_amount IN NUMBER)
 RETURN NUMBER;

procedure create_null_ratecard_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2);

procedure create_null_person_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2);

procedure create_null_invoiced_cac_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2);

procedure create_null_pa_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2);

procedure create_null_date_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2);

procedure create_null_job_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2);

/*******************************************************************************
 * Name:   dm_date_dim_process
 * Desc:   This procedure does the initial load as well as incremental load for date dimension.
 *         init_load_flag = 'Y' for initial load and init_load_flag = 'N' for incremental load.
 *******************************************************************************/
 PROCEDURE dm_date_dim_process(in_top_buyer_org_id 	IN NUMBER,
                               in_data_source_code 	IN VARCHAR2,
                               init_load_flag 		IN VARCHAR2);

procedure dm_fiscal_calendar_update ;

FUNCTION GET_BUSINESS_DAYS(V_START_DATE IN DATE, V_END_DATE IN DATE) RETURN NUMBER ;

FUNCTION get_job_status(in_what IN VARCHAR2) RETURN NUMBER;

FUNCTION get_currency_code( in_currency_dim_id in number) RETURN VARCHAR2;

FUNCTION get_converted_rate ( v_curr_conv_dim_id in number) RETURN NUMBER deterministic;

FUNCTION  get_curr_conv_dim_id(in_currency_dim_id in number,to_curr in varchar2,exp_date in date) RETURN NUMBER;

  FUNCTION get_assignment_dim_id
  (
      p_assignment_id    dm_assignment_dim.assignment_id%TYPE
    , p_data_source_code dm_assignment_dim.data_source_code%TYPE
  )
  RETURN dm_assignment_dim.assignment_dim_id%TYPE;

  PROCEDURE make_indexes_visible;
  PROCEDURE make_indexes_invisible;
END dm_cube_utils;
/