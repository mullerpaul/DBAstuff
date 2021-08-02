CREATE OR REPLACE PACKAGE SUPPLIER_SCORECARD.client_metric_settings_util
AS
/******************************************************************************
   NAME:       client_metric_settings_util
   PURPOSE:    public functions and procedures which maintain client specific
               formula settings.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   MSVC-595   04/21/2017  Paul Muller      Created this package.
   MSVC-604   04/24/2017  Paul Muller      Added remove settings proc 
   MSVC-690   05/08/2017  Paul Muller      Added writes to transaction_log table.
                                           Also removed remove_client_settings since
                                           its tough to log correctly. Revisit the need
                                           for that functionality later.
   MSVC-2694  03/15/18 HMajid         Add the get and set procedures for client
                                      category coefficient.

   MSVC-2695  03/15/18 HMajid         Add the get and set procedures for client
                                      Metric coefficient.
                                      
   MSVC-2696  03/19/18 HMajid         Add the get and set procedure for client 
                                      Metric Conversion.

   MSVC-2889  03/20/18 HMajid         Remove effective_date input from score settings 
                                      SET procedures.

   MSVC-2896  03/21/18 HMajid         Added Get and Set routines for metric range grade scores.
   MSVC-2892  03/21/18 HMajid         Modify the Get procedures and add a new as of date 
                                      parameter.
   MSVC-3159  04/24/2018  HMajid   Add supplire scorecard comments if it exists update it for
                                                            given client.
  MSVC-3160  05/01/2018  Hassina Majid    Add a new procedure which include the set convresion and set score routines.
  MSVC-3257  05/14/2018  Hassina Majid    Remove commits and timestamp from all set procedures.
                                                                       Also, changed logic to use just date and timestamp when updating existing data
                                                                       due to how application will be working.  
                                                                       Combined set client metric coversion and score into new procedure 
                                                                       set_all_metric_conversion.
 MSVC-3258  05/21/2018   Hassina Majid   Add the procedure which shows the historical activity on all client
                                                                      related tables which has changed from the intial addition. 
                                                                      This indicate any changes to Client_category_coefficient, client_metric_coefficient,
                                                                      client_metric_conversion tables.
 MSVC-3933  08/06/2017   Boris Pogrebitskiy Change to update of a metric to override username at the same time as range and points.

******************************************************************************/

  PROCEDURE copy_defaults_to_client (pi_client_guid  IN RAW,
                                     pi_session_guid IN RAW,
                                     pi_request_guid IN RAW);
                                     
  PROCEDURE get_client_catgry_coefficient(pi_login_guid IN RAW,
                                          pi_category_name IN CLIENT_CATEGORY_COEFFICIENT.METRIC_CATEGORY%TYPE,
                                          pi_as_of_date_utc IN DATE  DEFAULT TRUNC(sys_extract_utc(systimestamp)),
                                          po_category_coefficient OUT CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE);

  PROCEDURE set_client_catgry_coefficient(pi_login_guid IN RAW,
                                          pi_category_name IN CLIENT_CATEGORY_COEFFICIENT.METRIC_CATEGORY%TYPE,
                                          pi_category_coefficient IN CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE,                                          
                                          pi_username IN VARCHAR,
                                          pi_session_guid IN RAW);

  PROCEDURE get_client_metric_coefficient(pi_login_guid IN RAW,
                                          pi_metric_id IN CLIENT_METRIC_COEFFICIENT.METRIC_ID%TYPE,
                                          pi_as_of_date_utc IN DATE DEFAULT TRUNC(sys_extract_utc(systimestamp)),
                                          po_metric_coefficient OUT CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE);

  PROCEDURE set_client_metric_coefficient(pi_login_guid IN RAW,
                                         pi_metric_id IN CLIENT_METRIC_COEFFICIENT.METRIC_ID%TYPE,
                                         pi_metric_coefficient IN CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE,                   
                                         pi_username IN VARCHAR,
                                         pi_session_guid IN RAW);

  procedure GET_CLIENT_METRIC_CONVERSION (pi_login_guid IN RAW,
                                          pi_metric_id IN number,
                                          pi_as_of_date_utc IN DATE DEFAULT TRUNC(sys_extract_utc(systimestamp)),
                                          po_max_value OUT NUMBER,
                                          po_AB_breakpoint OUT NUMBER,
                                          po_BC_breakpoint OUT NUMBER,
                                          po_CD_breakpoint OUT NUMBER,
                                          po_DF_breakpoint OUT NUMBER,
                                          po_min_value OUT NUMBER);

  procedure GET_CLIENT_METRIC_SCORE (pi_login_guid IN RAW,
                                     pi_metric_id IN number,
                                     pi_as_of_date_utc IN DATE DEFAULT TRUNC(sys_extract_utc(systimestamp)),
                                     po_A_score OUT NUMBER,
                                     po_B_score OUT NUMBER,
                                     po_C_score OUT NUMBER,
                                     po_D_score OUT NUMBER,
                                     po_F_score OUT NUMBER
                                    );

 procedure SET_ALL_METRIC_CONVERSION (pi_login_guid IN RAW,
                                   pi_metric_id IN NUMBER,                                     
                                   pi_username IN VARCHAR,
                                   pi_session_guid IN RAW,
                                   pi_A_score IN NUMBER,
                                   pi_B_score IN NUMBER,
                                   pi_C_score IN NUMBER,
                                   pi_D_score IN NUMBER,
                                   pi_F_score IN NUMBER,
                                   pi_AB_breakpoint IN NUMBER,
                                   pi_BC_breakpoint IN NUMBER,
                                   pi_CD_breakpoint IN NUMBER,
                                   pi_DF_breakpoint IN NUMBER
                                   );



  PROCEDURE get_supplier_scorecard_comment (pi_login_guid IN RAW,
                                            pi_as_of_date_utc IN DATE  DEFAULT trunc(sys_extract_utc(systimestamp)),
                                            po_comments OUT VARCHAR);
                                            
  PROCEDURE set_supplier_scorecard_comment (pi_login_guid IN RAW,
                                          pi_username IN VARCHAR,
                                          pi_session_guid IN RAW,
                                          pi_comments  IN VARCHAR);

-- Please make sure the follwoing two procs are removed once msvc-3166 is deployed which suppose to use
--   SET_ALL_METRIC_CONVERSION  which is a combination of metric conversion and metric score.

  procedure SET_CLIENT_METRIC_SCORE (pi_login_guid IN RAW,
                                     pi_metric_id IN NUMBER,                                     
                                     pi_username IN VARCHAR,
                                     pi_session_guid IN RAW,
                                     pi_A_score IN NUMBER,
                                     pi_B_score IN NUMBER,
                                     pi_C_score IN NUMBER,
                                     pi_D_score IN NUMBER,
                                     pi_F_score IN NUMBER
                                   );


  procedure SET_CLIENT_METRIC_CONVERSION(pi_login_guid IN RAW,
                                         pi_metric_id IN NUMBER,                                     
                                         pi_username IN VARCHAR,
                                         pi_session_guid IN RAW,
                                         pi_AB_breakpoint IN NUMBER,
                                         pi_BC_breakpoint IN NUMBER,
                                         pi_CD_breakpoint IN NUMBER,
                                         pi_DF_breakpoint IN NUMBER,
                                         pi_comments IN VARCHAR2
);
PROCEDURE get_client_historical_data(pi_login_guid IN RAW,po_result_set OUT SYS_REFCURSOR);

END client_metric_settings_util;
/
