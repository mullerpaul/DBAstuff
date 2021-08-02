CREATE OR REPLACE PACKAGE dm_util_log
AS
/*******************************************************************
 * Author: Manoj
 * Date:  11/20/08
 * Desc: This package contains function to log errors and messages
 *       for datamart.
 *******************************************************************/

/*****************************************************
 * Function Name: f_log_error
 * Desc: This function is  used to log errors to the
 *       error tables
 *****************************************************/
 FUNCTION f_log_error(in_error_id             IN NUMBER,
                      iv_app_msg              IN VARCHAR2,
                      iv_db_msg               IN VARCHAR2,
                      iv_executing_object     IN VARCHAR2)
 RETURN NUMBER;

/*****************************************************
 * Proc Name: p_log_msg
 * Desc: This procedure is  used to log messages
 *****************************************************/
 PROCEDURE p_log_msg(in_msg_seq               IN NUMBER,
                     in_sub_seq               IN NUMBER,
                     iv_msg                   IN VARCHAR2,
                     iv_executing_object      IN VARCHAR2,
                     iv_action                IN VARCHAR2);
/********************************************************************
 * Proc Name: p_log_load_status
 * Desc: This procedure is  used to log the load status of DM objects
 ********************************************************************/
 PROCEDURE p_log_load_status(in_batch_id               IN NUMBER,
                             iv_object_name            IN VARCHAR2,
                             iv_object_source          IN VARCHAR2,
                             iv_load_status            IN VARCHAR2,
                             in_rows_processed         IN NUMBER,
                             iv_action                 IN VARCHAR2);
/********************************************************************
 * Proc Name: p_log_cube_load_status
 * Desc: This procedure is  used to log the load status of DM objects
 ********************************************************************/
 PROCEDURE p_log_cube_load_status(iv_cube_object_name  IN VARCHAR2,
                                  iv_data_source_code  IN VARCHAR2,
                                  iv_cube_object_type  IN VARCHAR2,                             
                                  iv_load_status       IN VARCHAR2,
                                  in_date_id           IN NUMBER);                             

END dm_util_log;
/