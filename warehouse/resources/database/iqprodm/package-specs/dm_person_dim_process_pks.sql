CREATE OR REPLACE PACKAGE dm_person_dim_process AS
/*********************************************************************
 * Name   : FO_DM_PERSON_DIM_PROCESS
 * Desc   : This package contains all the procedures required to
 *          migrate/process persons data.
 *
 * Source : Front office and Data mart ( person_snapshot )
 *
 * Name          Date         Version     Details
 * ----------------------------------------------------------------------
 * smeriweather  08/02/2010   Initial
 ************************************************************************/

   PROCEDURE main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                  ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
                 ,in_remove_dups      IN VARCHAR2 DEFAULT 'Y'
                 ,in_verify_eff_date  IN VARCHAR2 DEFAULT 'Y'
                 ,in_dbg_mode         IN VARCHAR2 DEFAULT 'N');

   PROCEDURE redo_last_load(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                            ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));

   FUNCTION get_person_dim_id
     (in_person_id        IN NUMBER
     ,in_invoice_date     IN DATE
     ,in_data_source_code IN VARCHAR2)
   RETURN NUMBER;


END dm_person_dim_process;
/