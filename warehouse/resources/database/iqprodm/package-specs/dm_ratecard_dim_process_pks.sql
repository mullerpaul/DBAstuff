CREATE OR REPLACE PACKAGE dm_ratecard_dim_process AS

   FUNCTION get_currency_dim_id(in_currency_code IN VARCHAR2) RETURN NUMBER;

   PROCEDURE delete_dups
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   );

   PROCEDURE invalidate_fo_deleted
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   );

   PROCEDURE insert_dim_records
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   );

   PROCEDURE insert_new_dim_records
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   );

   PROCEDURE pull_fo_ratecard_data
   ( 
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   );

   PROCEDURE insert_new_ratecard_versions
   (
       p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
     , p_start_date  IN DATE     DEFAULT SYSDATE
     , p_msg_id      IN NUMBER
   );

   PROCEDURE invalidate_old_ratecards
   (
       p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
     , p_close_date  IN DATE     DEFAULT SYSDATE
     , p_msg_id      IN NUMBER
   );

   PROCEDURE get_changed_ratecards
   (
       p_source_code IN VARCHAR2
     , p_msg_id      IN NUMBER
   );

   PROCEDURE extract_fo_ratecards
   (
       p_source_code IN VARCHAR2 DEFAULT 'REGULAR'
     , p_msg_id      IN NUMBER
   );

   PROCEDURE main
   (
       p_source_code  IN VARCHAR2 DEFAULT 'REGULAR'
     , p_dbg_mode          IN VARCHAR2 DEFAULT 'N'
   );

END dm_ratecard_dim_process;
/