CREATE OR REPLACE PACKAGE dm_geo
AS
   c_def_from_date DATE   := TO_DATE('19991231', 'YYYYMMDD');

   PROCEDURE populate_geo_dim;

   PROCEDURE update_us_geo_dim
   (
     p_release_date IN  VARCHAR2
   );

   PROCEDURE start_canada_geo_dim;

   PROCEDURE update_canada_geo_dim
   (
     p_release_date IN  VARCHAR2
   );

   PROCEDURE cleanup_geo_master;
   PROCEDURE add_extra_indexes;
   PROCEDURE drop_extra_indexes;
END dm_geo;
/