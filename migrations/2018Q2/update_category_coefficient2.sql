/* Formatted on 6/28/2018 12:47:03 PM (QP5 v5.267.14150.38599) */
DECLARE
   ln_expected_count   NUMBER;
   ln_actual_count     NUMBER;
BEGIN
   logger_pkg.instantiate_logger;
   logger_pkg.set_level ('INFO');
   logger_pkg.set_source ('msvc-3685 - update category coefficient');
   logger_pkg.set_code_location ('migrations\2018Q2');


   SELECT COUNT (*) INTO ln_expected_count FROM client_category_coefficient;


   BEGIN
      UPDATE client_category_coefficient
         SET category_coefficient = 1;

      ln_actual_count := SQL%ROWCOUNT;

      IF ln_expected_count = ln_actual_count
      THEN
         COMMIT;
      END IF;

      logger_pkg.unset_source ('msvc-3685 - update category coefficient');
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         logger_pkg.error (
            pi_message              =>    'update failed for category coefficient table. '
                                       || SQLERRM,
            pi_transaction_result   => 'ROLLBACK',
            pi_error_code           => SQLCODE);
         logger_pkg.unset_source ('msvc-3685 - update category coefficient');
         raise_application_error (
            -20001,
            'Error in script while tyring to update category coefficient, rolling back!');
   END;
END;
/


