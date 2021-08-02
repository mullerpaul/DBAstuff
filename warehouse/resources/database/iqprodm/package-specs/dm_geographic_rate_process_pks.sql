CREATE OR REPLACE PACKAGE dm_geographic_rate_process
/********************************************************************
 * Name: dm_regional_rate_process
 * Desc: This package contains all the procedures required to
 *       get the regional avaerage rates and percentiles
 *
 * Author   Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   01/20/10     Initial
 ********************************************************************/
AS
   c_crlf          VARCHAR2(2) := chr(13) || chr(10);
  PROCEDURE p_rate_process(id_run_date         IN DATE,
                           iv_period_type      IN VARCHAR2,
                           iv_geographic_level IN VARCHAR2,
                           in_region_type      IN NUMBER,
                           iv_new_assign_flag  IN VARCHAR2,
                           in_msg_id           IN NUMBER,
                           id_ytd_date         IN DATE,
                           on_err_num         OUT NUMBER,
                           ov_err_msg         OUT VARCHAR2);

  PROCEDURE p_main(id_run_date      IN DATE DEFAULT (SYSDATE-1),id_start_date IN DATE DEFAULT '01-JAN-2008' );

END dm_geographic_rate_process;
/