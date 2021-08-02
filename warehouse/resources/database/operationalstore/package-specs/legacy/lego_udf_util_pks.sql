CREATE OR REPLACE PACKAGE lego_udf_util IS

  PROCEDURE udf_noenum(i_new_table_name IN VARCHAR2,
                       i_join_view      IN VARCHAR2,
                       i_join_column    IN VARCHAR2);

  PROCEDURE udf_enum(i_new_table_name IN VARCHAR2,
                     i_join_view      IN VARCHAR2,
                     i_join_column    IN VARCHAR2);

  PROCEDURE load_locales_by_buyer_org(pi_refresh_table IN VARCHAR2);

  PROCEDURE create_all_pivot_views(pi_enterprise_bus_org_id IN NUMBER);

--  PROCEDURE drop_lego_pivot_views;

END lego_udf_util;
/
