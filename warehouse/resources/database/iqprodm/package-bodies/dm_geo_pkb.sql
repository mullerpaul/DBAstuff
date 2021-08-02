CREATE OR REPLACE PACKAGE BODY dm_geo
AS
   PROCEDURE populate_geo_dim
   IS
         v_country_dim_id   dm_country_dim.country_dim_id%TYPE;
         v_country_name     dm_country_dim.iso_country_name%TYPE;
         v_crnt_proc_name   user_jobs.what%TYPE := 'DM_GEO.POPULATE_GEO_DIM';
         v_rec_count        NUMBER;
         v_msg_id           NUMBER;
   BEGIN
         --dm_cube_utils.make_indexes_visible;
         EXECUTE IMMEDIATE 'ALTER SESSION SET optimizer_use_invisible_indexes = true';

         --
         -- Get the sequence required for logging messages
         --
         SELECT dm_msg_log_seq.NEXTVAL INTO v_msg_id FROM dual;

         EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_geo_dim';
         EXECUTE IMMEDIATE 'DROP SEQUENCE dm_geo_dim_seq';
         EXECUTE IMMEDIATE 'CREATE SEQUENCE dm_geo_dim_seq START WITH 1 CACHE 20';

         dm_util_log.p_log_msg(v_msg_id, 1, 'Populate Geo DIM', v_crnt_proc_name,'I');
         INSERT INTO dm_geo_dim
         (
            geo_dim_id
          , state_code
          , state_name
          , city_name
          , country_dim_id
          , iso_country_name
          , postal_code
          , cmsa_code
          , last_update_date
          , version_id
          , is_effective
          , valid_from_date
          , valid_to_date 
         )
         VALUES
         (
            0
          , NULL
          , NULL
          , NULL
          , 0
          , NULL 
          , NULL -- postal_code
          , NULL -- cmsa_code
          , SYSDATE -- last_update_date
          , 1  --version_id
          , 'Y' -- is_effective
          , c_def_from_date -- valid_from_date
          , NULL --valid_to_date 
         );
         v_rec_count := SQL%ROWCOUNT;
         dm_util_log.p_log_msg(v_msg_id, 2, 'Added ' || v_rec_count || ' dummy locations', v_crnt_proc_name,'I');
         dm_util_log.p_log_msg(v_msg_id, 2, NULL,NULL,'U');

         /*
         ** Add All country level geo locations
         ** Just Country with no other information
         */
         INSERT INTO dm_geo_dim
         (
            geo_dim_id
          , state_code
          , state_name
          , city_name
          , country_dim_id
          , iso_country_name
          , postal_code
          , cmsa_code
          , last_update_date
          , version_id
          , is_effective
          , valid_from_date
          , valid_to_date 
         )
         SELECT   dm_geo_dim_seq.NEXTVAL AS geo_dim_id
                , NULL AS state_code
                , NULL AS state_name
                , NULL AS city_name
                , m.country_dim_id
                , m.iso_country_name
                , NULL AS postal_code
                , NULL AS cmsa_code
                , SYSDATE AS last_update_date
                , 1 AS version_id
                , 'Y' AS is_effective
                , c_def_from_date AS valid_from_date
                , NULL AS valid_to_date 
           FROM dm_country_dim m
          WHERE m.country_dim_id <> 0;

         v_rec_count := SQL%ROWCOUNT;
         dm_util_log.p_log_msg(v_msg_id, 3, 'Added ' || v_rec_count || ' Country level locations', v_crnt_proc_name,'I');
         dm_util_log.p_log_msg(v_msg_id, 3, NULL,NULL,'U');

         v_country_name := 'UNITED STATES';
         SELECT country_dim_id
           INTO v_country_dim_id
           FROM dm_country_dim
          WHERE iso_country_name = v_country_name;
        
         /*
         ** Add All US State level geo locations
         ** Just State name, no other information
         ** We can't get CMSA for these geo locations
         */
         INSERT INTO dm_geo_dim
         (
            geo_dim_id
          , state_code
          , state_name
          , city_name
          , country_dim_id
          , iso_country_name
          , postal_code
          , cmsa_code
          , last_update_date
          , version_id
          , is_effective
          , valid_from_date
          , valid_to_date 
         )
         SELECT   dm_geo_dim_seq.nextval AS geo_dim_id
                , state
                , state_name
                , NULL AS city
                , v_country_dim_id AS country_dim_id
                , v_country_name AS iso_country_name
                , NULL AS postal_code
                , NULL AS cmsa_code
                , SYSDATE AS last_update_date
                , 1 AS version_id
                , 'Y' AS is_effective
                , c_def_from_date AS valid_from_date
                , NULL AS valid_to_date 
           FROM (
                  SELECT DISTINCT m.state, UPPER(m.statename) AS state_name
                    FROM us_geo_master m
                   WHERE m.state IS NOT NULL
                     AND m.statename IS NOT NULL
                );

         v_rec_count := SQL%ROWCOUNT;
         dm_util_log.p_log_msg(v_msg_id, 4, 'Added ' || v_rec_count || ' ' || v_country_name || ' State level locations', v_crnt_proc_name,'I');
         dm_util_log.p_log_msg(v_msg_id, 4, NULL,NULL,'U');

         /*
         ** Add All US State and City level geo locations
         ** Just US State name and City Name, no zip code
         ** Only Cities with Multiple zip codes included
         ** Also get CMSA for these geo locations from 
         */
         INSERT INTO dm_geo_dim
         (
            geo_dim_id
          , state_code
          , state_name
          , city_name
          , country_dim_id
          , iso_country_name
          , postal_code
          , cmsa_code
          , last_update_date
          , version_id
          , is_effective
          , valid_from_date
          , valid_to_date 
         )
         SELECT dm_geo_dim_seq.NEXTVAL AS geo_dim_id
                , state
                , UPPER(statename) AS state_name
                , UPPER(city) AS city_name
                , v_country_dim_id country_dim_id
                , v_country_name AS iso_country_name
                , NULL AS postal_code
                , p.cmsa_code AS cmsa_code
                , SYSDATE AS last_update_date
                , 1 AS version_id
                , 'Y' AS is_effective
                , c_def_from_date AS valid_from_date
                , NULL AS valid_to_date 
           FROM (
                  SELECT m.state, m.statename, m.city, COUNT(*)
                    FROM us_geo_master m
                   WHERE m.state IS NOT NULL
                     AND m.statename IS NOT NULL
                   GROUP BY m.state, m.statename, m.city
                  HAVING count(*) > 1
                ) d,
                (
                  SELECT *
                    FROM (
                           SELECT dp.std_city,dp.std_state, cmsa_code,
                                  ROW_NUMBER() OVER (PARTITION BY dp.std_state, dp.std_city ORDER BY dp.std_city) AS rnk
                             FROM dm_places dp
                            WHERE dp.std_country_id = 1
                              AND dp.std_postal_code IS NULL
                              AND dp.std_city IS NOT NULL
                              AND dp.std_state IS NOT NULL
                         )
                   WHERE rnk = 1
                ) p
          WHERE p.std_state (+) = d.state
            AND p.std_city  (+) = d.city;

         v_rec_count := SQL%ROWCOUNT;
         dm_util_log.p_log_msg(v_msg_id, 5, 'Added ' || v_rec_count || ' ' || v_country_name || ' State and City level locations', v_crnt_proc_name,'I');
         dm_util_log.p_log_msg(v_msg_id, 5, NULL,NULL,'U');

         /*
         ** Add All US Zip code level geo locations
         */
         INSERT INTO dm_geo_dim
         (
            geo_dim_id
          , state_code
          , state_name
          , city_name
          , country_dim_id
          , iso_country_name
          , postal_code
          , cmsa_code
          , last_update_date
          , abbr_city_name
          , county_name
          , city_type
          , postal_type
          , csa
          , cbsa
          , cbsa_division
          , cbsa_status
          , necma
          , combined_necta
          , necta
          , necta_division
          , msa
          , pmsa
          , fips
          , area_code
          , overlay
          , time_zone
          , dst
          , utc
          , latitude
          , longitude
          , customer_service_area
          , customer_service_area_name
          , customer_service_district
          , customer_service_district_name
          , version_id
          , is_effective
          , valid_from_date
          , valid_to_date 
         )
         SELECT   dm_geo_dim_seq.NEXTVAL AS geo_dim_id
                , state AS state_code
                , UPPER(m.statename) AS state_name
                , UPPER(m.city) AS city_name
                , v_country_dim_id AS country_dim_id
                , v_country_name AS iso_country_name
                , m.zip AS postal_code
                , p.cmsa_code AS cmsa_code
                , SYSDATE AS last_update_date
                , m.abbreviation AS abbr_city_name
                , m.countyname AS county_name
                , m.citytype AS city_type
                , m.ziptype AS postal_type
                , m.csa
                , m.cbsa
                , m.cbsa_division
                , m.cbsa_status
                , m.necma
                , m.combinednecta AS combined_necta
                , m.necta
                , m.necta_division
                , m.msa
                , m.pmsa
                , m.fips
                , m.areacode AS area_code
                , m.overlay
                , m.timezone AS time_zone
                , m.dst
                , m.utc
                , m.latitude
                , m.longitude
                , m.customerservicearea AS customer_service_area
                , m.customerserviceareaname AS customer_service_area_name
                , m.customerservicedistricT AS customer_service_district
                , m.customerservicedistrictname AS customer_service_district_name
                , 1 AS version_id
                , 'Y' AS is_effective
                , c_def_from_date AS valid_from_date
                , NULL AS valid_to_date 
           FROM us_geo_master m,
                (
                  SELECT *
                    FROM ( 
                           SELECT   dp.std_postal_code, dp.cmsa_code
                                  , ROW_NUMBER() OVER (PARTITION BY dp.std_postal_code ORDER BY dp.cmsa_code) AS rnk
                             FROM dm_places dp
                            WHERE  dp.std_country_id = 1
                              AND  dp.std_postal_code IS NOT NULL
                         ) 
                   WHERE rnk = 1
                ) p
          WHERE m.state IS NOT NULL
            AND m.statename IS NOT NULL
            AND p.std_postal_code (+) = m.zip;
         v_rec_count := SQL%ROWCOUNT;
         dm_util_log.p_log_msg(v_msg_id, 6, 'Added ' || v_rec_count || ' ' || v_country_name || ' unique Postal code level locations', v_crnt_proc_name,'I');
         dm_util_log.p_log_msg(v_msg_id, 6, NULL,NULL,'U');

         COMMIT;
         dm_util_log.p_log_msg(v_msg_id, 1, NULL,NULL,'U');
   END populate_geo_dim;

   PROCEDURE update_us_geo_dim
   (
     p_release_date IN  VARCHAR2
   )
   IS
         v_country_dim_id   dm_country_dim.country_dim_id%TYPE;
         v_country_name     dm_country_dim.iso_country_name%TYPE;

         CURSOR c1 IS
         SELECT z.*, p.cmsa_code
           FROM (
                  SELECT   g.geo_dim_id
                         , g.version_id
                         , g.postal_code AS old_postal_code
                         , g.city_name   AS old_city_name
                         , g.cmsa_code AS old_cmsa_code
                         , m.state AS state_code
                         , UPPER(m.statename) AS state_name
                         , UPPER(m.city) AS city_name
                         , m.zip AS postal_code
                         , m.abbreviation AS abbr_city_name
                         , m.countyname AS county_name
                         , m.citytype AS city_type
                         , m.ziptype AS postal_type
                         , m.csa
                         , m.cbsa
                         , m.cbsa_division
                         , m.cbsa_status
                         , m.necma
                         , m.combinednecta AS combined_necta
                         , m.necta
                         , m.necta_division
                         , m.msa
                         , m.pmsa
                         , m.fips
                         , m.areacode AS area_code
                         , m.overlay
                         , m.timezone AS time_zone
                         , m.dst
                         , m.utc
                         , m.latitude
                         , m.longitude
                         , m.customerservicearea AS customer_service_area
                         , m.customerserviceareaname AS customer_service_area_name
                         , m.customerservicedistricT AS customer_service_district
                         , m.customerservicedistrictname AS customer_service_district_name
                    FROM (
                           SELECT x.*
                             FROM us_geo_master x
                            WHERE x.zip  IS NOT NULL
                              AND x.city IS NOT NULL
                              AND x.state IS NOT NULL
                              AND x.statename IS NOT NULL
                              AND REGEXP_LIKE(x.zip, '[[:digit:]]{5}')
                         ) m
                            FULL OUTER JOIN
                         (
                           SELECT y.*
                             FROM dm_geo_dim y
                            WHERE y.is_effective = 'Y'
                              AND y.country_dim_id = v_country_dim_id
                              AND y.postal_code IS NOT NULL
                              AND y.city_name IS NOT NULL
                         ) g
                      ON g.postal_code = m.zip
                     AND g.city_name = UPPER(m.city)
                   WHERE (
                             NVL(g.postal_code, '?')          <> NVL(m.zip, '?')
                          OR NVL(g.city_name, '?')            <> NVL(UPPER(m.city), '?')
                          OR g.state_code                     <> m.state
                          OR g.state_name                     <> UPPER(m.statename)
                          OR g.abbr_city_name                 <> m.abbreviation
                          OR g.county_name                    <> m.countyname
                          OR g.city_type                      <> m.citytype
                          OR g.postal_type                    <> m.ziptype
                          OR g.csa                            <> m.csa
                          OR g.cbsa                           <> m.cbsa
                          OR g.cbsa_division                  <> m.cbsa_division
                          OR g.cbsa_status                    <> m.cbsa_status
                          OR g.necma                          <> m.necma
                          OR g.combined_necta                 <> m.combinednecta
                          OR g.necta                          <> m.necta
                          OR g.necta_division                 <> m.necta_division
                          OR g.msa                            <> m.msa
                          OR g.pmsa                           <> m.pmsa
                          OR g.fips                           <> m.fips
                          OR g.area_code                      <> m.areacode
                          OR g.overlay                        <> m.overlay
                          OR g.time_zone                      <> m.timezone
                          OR g.dst                            <> m.dst
                          OR g.utc                            <> m.utc
                          OR g.latitude                       <> m.latitude
                          OR g.longitude                      <> m.longitude
                          OR g.customer_service_area          <> m.customerservicearea
                          OR g.customer_service_area_name     <> m.customerserviceareaname
                          OR g.customer_service_district      <> m.customerservicedistrict
                          OR g.customer_service_district_name <> m.customerservicedistrictname
                         )
                ) z,
                (
                  SELECT *
                    FROM (
                           SELECT dp.std_city,dp.std_state, cmsa_code,
                                  ROW_NUMBER() OVER (PARTITION BY dp.std_state, dp.std_city ORDER BY dp.std_city) AS rnk
                             FROM dm_places dp
                            WHERE dp.std_country_id = 1
                              AND dp.std_postal_code IS NULL
                              AND dp.std_city IS NOT NULL
                              AND dp.std_state IS NOT NULL
                         )
                   WHERE rnk = 1
                ) p
          WHERE  p.std_state (+) = z.state_name
            AND p.std_city  (+) = z.city_name;
   BEGIN
         v_country_name := 'UNITED STATES';
         SELECT country_dim_id
           INTO v_country_dim_id
           FROM dm_country_dim
          WHERE iso_country_name = v_country_name;

         --
         -- Retire or logically delete
         -- Any City records with multiple postal codes
         -- that are nolonger active or became single postal code cities
         -- in this data update from Vendor 
         --
         MERGE INTO dm_geo_dim t
         USING (
                 WITH st_city_list AS
                 (
                   SELECT /*+ MATERIALIZE */ state, UPPER(statename) statename, UPPER(city) city, COUNT(DISTINCT m.zip)
                     FROM us_geo_master m
                    GROUP BY state, UPPER(statename), UPPER(city)
                   HAVING COUNT(DISTINCT m.zip) > 1
                 )
                 SELECT /*+ MATERIALIZE */ g.geo_dim_id
                   FROM dm_geo_dim g
                  WHERE g.country_dim_id = v_country_dim_id
                    AND g.postal_code IS NULL
                    AND g.cmsa_code IS NULL
                    AND g.city_name IS NOT NULL
                    AND g.is_effective = 'Y'
                    AND NOT EXISTS (
                                     SELECT NULL
                                       FROM st_city_list l
                                      WHERE l.state = g.state_code
                                        AND l.statename = g.state_name
                                        AND l.city = g.city_name
                           )
               ) s
            ON (
                 t.geo_dim_id = s.geo_dim_id
               )
          WHEN MATCHED THEN UPDATE SET
                  t.is_effective = 'N'
                , t.valid_to_date = TO_DATE(p_release_date, 'YYYYMMDD') -(1/86400)
                , last_update_date = SYSDATE;

         /*
         ** Add any brand new
         ** US State and City level geo locations
         ** Just US State name and City Name, no zip code
         ** Only Cities with Multiple zip codes included
         ** Also get CMSA for these geo locations from dm_places
         */
         INSERT INTO dm_geo_dim
         (
            geo_dim_id
          , state_code
          , state_name
          , city_name
          , country_dim_id
          , iso_country_name
          , postal_code
          , cmsa_code
          , last_update_date
          , version_id
          , is_effective
          , valid_from_date
          , valid_to_date 
         )
         WITh st_city_list AS
         (
           SELECT UPPER(state) state_code, UPPER(statename) state_name, UPPER(city) city_name, COUNT(DISTINCT m.zip)
             FROM us_geo_master m
            GROUP BY UPPER(state), UPPER(statename), UPPER(city)
           HAVING COUNT(DISTINCT m.zip) > 1
         )
         SELECT   dm_geo_dim_seq.NEXTVAL AS geo_dim_id
                , d.state_code
                , d.state_name
                , d.city_name
                , v_country_dim_id country_dim_id
                , v_country_name AS iso_country_name
                , NULL AS postal_code
                , p.cmsa_code AS cmsa_code
                , SYSDATE AS last_update_date
                , 1 -- version_id
                , 'Y' -- is_effective
                , c_def_from_date -- valid_from_date
                , NULL -- valid_to_date 
           FROM st_city_list d,
                (
                  SELECT *
                    FROM (
                           SELECT dp.std_city city_name, dp.std_state state_code, cmsa_code,
                                  ROW_NUMBER() OVER (PARTITION BY dp.std_state, dp.std_city ORDER BY dp.std_city) AS rnk
                             FROM dm_places dp
                            WHERE  dp.std_country_id = 1
                              AND dp.std_postal_code IS NULL
                              AND dp.std_city IS NOT NULL
                              AND dp.std_state IS NOT NULL
                         )
                   WHERE rnk = 1
                ) p
          WHERE NOT EXISTS (
                             SELECT NULL
                               FROM dm_geo_dim g
                              WHERE g.country_dim_id = v_country_dim_id
                                AND g.postal_code IS NULL
                                AND g.cmsa_code IS NULL
                                AND g.city_name IS NOT NULL
                                AND g.is_effective = 'Y'
                                AND g.city_name = d.city_name
                                AND g.state_name = d.state_name
                           )
            AND p.state_code (+) = d.state_code
            AND p.city_name  (+) = d.city_name;

         FOR r1 IN c1
         LOOP
              IF (r1.geo_dim_id IS NULL)
                 THEN
                      --
                      -- Add any brand new US City/Postal codes Combinations that 
                      -- have been added in this data update from Vendor 
                      --
                      INSERT INTO dm_geo_dim
                      (
                         geo_dim_id
                       , state_code
                       , state_name
                       , city_name
                       , country_dim_id
                       , iso_country_name
                       , postal_code
                       , cmsa_code
                       , last_update_date
                       , abbr_city_name
                       , county_name
                       , city_type
                       , postal_type
                       , csa
                       , cbsa
                       , cbsa_division
                       , cbsa_status
                       , necma
                       , combined_necta
                       , necta
                       , necta_division
                       , msa
                       , pmsa
                       , fips
                       , area_code
                       , overlay
                       , time_zone
                       , dst
                       , utc
                       , latitude
                       , longitude
                       , customer_service_area
                       , customer_service_area_name
                       , customer_service_district
                       , customer_service_district_name
                       , version_id
                       , is_effective
                       , valid_from_date
                       , valid_to_date 
                      )
                      VALUES
                      (
                         dm_geo_dim_seq.NEXTVAL --geo_dim_id
                       , r1.state_code
                       , r1.state_name
                       , r1.city_name
                       , v_country_dim_id --country_dim_id
                       , v_country_name -- iso_country_name
                       , r1.postal_code
                       , r1.cmsa_code
                       , SYSDATE -- last_update_date
                       , r1.abbr_city_name
                       , r1.county_name
                       , r1.city_type
                       , r1.postal_type
                       , r1.csa
                       , r1.cbsa
                       , r1.cbsa_division
                       , r1.cbsa_status
                       , r1.necma
                       , r1.combined_necta
                       , r1.necta
                       , r1.necta_division
                       , r1.msa
                       , r1.pmsa
                       , r1.fips
                       , r1.area_code
                       , r1.overlay
                       , r1.time_zone
                       , r1.dst
                       , r1.utc
                       , r1.latitude
                       , r1.longitude
                       , r1.customer_service_area
                       , r1.customer_service_area_name
                       , r1.customer_service_district
                       , r1.customer_service_district_name
                       , 1 -- version_id
                       , 'Y' -- is_effective
                       , c_def_from_date -- valid_from_date
                       , NULL -- valid_to_date 
                      );
                 ELSE
                      /*
                      ** Disable old version of geo_dim_id for the changed postal code/City Combination
                      */
                      UPDATE dm_geo_dim g
                         SET   g.is_effective = 'N'
                             , g.valid_to_date = TO_DATE(p_release_date, 'YYYYMMDD') -(1/86400)
                             , g.last_update_date = SYSDATE
                       WHERE g.geo_dim_id = r1.geo_dim_id;

                      IF (r1.postal_code IS NOT NULL AND r1.city_name IS NOT NULL)
                         THEN
                              /* Existing Postal Code/City combination but something changed */

                              /*
                              ** Get and Insert new geo_dim_id for the changed postal code
                              */
                              INSERT INTO dm_geo_dim
                              (
                                 geo_dim_id
                               , state_code
                               , state_name
                               , city_name
                               , country_dim_id
                               , iso_country_name
                               , postal_code
                               , cmsa_code
                               , last_update_date
                               , abbr_city_name
                               , county_name
                               , city_type
                               , postal_type
                               , csa
                               , cbsa
                               , cbsa_division
                               , cbsa_status
                               , necma
                               , combined_necta
                               , necta
                               , necta_division
                               , msa
                               , pmsa
                               , fips
                               , area_code
                               , overlay
                               , time_zone
                               , dst
                               , utc
                               , latitude
                               , longitude
                               , customer_service_area
                               , customer_service_area_name
                               , customer_service_district
                               , customer_service_district_name
                               , version_id
                               , is_effective
                               , valid_from_date
                               , valid_to_date 
                              ) VALUES
                              (
                                 dm_geo_dim_seq.NEXTVAL
                               , r1.state_code
                               , r1.state_name
                               , r1.city_name
                               , v_country_dim_id
                               , v_country_name
                               , r1.postal_code
                               , r1.cmsa_code
                               , SYSDATE
                               , r1.abbr_city_name
                               , r1.county_name
                               , r1.city_type
                               , r1.postal_type
                               , r1.csa
                               , r1.cbsa
                               , r1.cbsa_division
                               , r1.cbsa_status
                               , r1.necma
                               , r1.combined_necta
                               , r1.necta
                               , r1.necta_division
                               , r1.msa
                               , r1.pmsa
                               , r1.fips
                               , r1.area_code
                               , r1.overlay
                               , r1.time_zone
                               , r1.dst
                               , r1.utc
                               , r1.latitude
                               , r1.longitude
                               , r1.customer_service_area
                               , r1.customer_service_area_name
                               , r1.customer_service_district
                               , r1.customer_service_district_name
                               , r1.version_id + 1
                               , 'Y' --is_effective
                               , TO_DATE(p_release_date, 'YYYYMMDD') -- valid_from_date
                               , NULL -- valid_to_date 
                              );
                      END IF;
              END IF; -- Check  if r1.geo_dim_id IS NULL
         END LOOP;
         COMMIT;
   END update_us_geo_dim;

   PROCEDURE start_canada_geo_dim
   IS
         v_country_dim_id   dm_country_dim.country_dim_id%TYPE;
         v_country_name     dm_country_dim.iso_country_name%TYPE;
   BEGIN
         v_country_name := 'CANADA';
         SELECT country_dim_id
           INTO v_country_dim_id
           FROM dm_country_dim
          WHERE iso_country_name = v_country_name;

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'NL', 'NEWFOUNDLAND AND LABRADOR', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'YT', 'YUKON', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'ON', 'ONTARIO', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'NT', 'NORTHWEST TERRRITORIES', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'MB', 'MANITOBA', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'QC', 'QUEBEC', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'AB', 'ALBERTA', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'NU', 'NUNAVUT', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'BC', 'BRITISH COLUMBIA', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'NS', 'NOVA SCOTIA', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'PE', 'PRINCE EDWARD ISLAND', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'NB', 'NEW BRUNSWICK', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);

          INSERT INTO dm_geo_dim (geo_dim_id, state_code, state_name, city_name, country_dim_id, 
                                  iso_country_name, last_update_date, version_id, is_effective, valid_from_date)
                      VALUES     (dm_geo_dim_seq.NEXTVAL, 'SK', 'SASKATCHEWAN', NULL, v_country_dim_id, 
                                  v_country_name, SYSDATE, 1, 'Y', c_def_from_date);
          COMMIT;

          INSERT /*+ APPEND(t) */ INTO dm_geo_dim t
          (
              country_dim_id
            , geo_dim_id
            , postal_code
            , state_name
            , city_name
            , iso_country_name
            , state_code
            , city_type
            , postal_type
            , latitude
            , longitude
            , version_id
            , is_effective
            , valid_from_date
            , valid_to_date
            , last_update_date
          )
          SELECT   v_country_dim_id AS country_dim_id
                 , dm_geo_dim_seq.NEXTVAL
                 , m.zip AS postal_code
                 , g.state_name
                 , UPPER(m.city) AS city_name
                 , v_country_name AS iso_country_name
                 , m.state AS state_code
                 , m.citytype AS city_type
                 , m.ziptype AS postal_type
                 , m.latitude
                 , m.longitude
                 , 1 AS version_id
                 ,'Y' AS is_effective
                 , c_def_from_date
                 , NULL AS valid_to_date
                 , SYSDATE AS last_update_date
            FROM us_geo_master m, dm_geo_dim g
           WHERE REGEXP_LIKE(m.zip, '[[:alpha:]][[:digit:]][[:alpha:]] [[:digit:]][[:alpha:]][[:digit:]]')
             AND g.country_dim_id = v_country_dim_id
             AND g.state_code IS NOT NULL
             AND g.state_name IS NOT NULL
             AND g.city_name IS NULL
             AND g.is_effective = 'Y'
             AND g.state_code = m.state;

          COMMIT;
   END start_canada_geo_dim;

   PROCEDURE update_canada_geo_dim
   (
     p_release_date IN  VARCHAR2
   )
   IS
         v_country_dim_id   dm_country_dim.country_dim_id%TYPE;
         v_country_name     dm_country_dim.iso_country_name%TYPE;

         /*
         ** Get existing postal codes that are not shared by multiple cities
         ** in the update from vendor
         ** and there is some change in data provided
         */
         CURSOR c1 IS
         SELECT k.*, l.state_name
           FROM (
                  SELECT   g.geo_dim_id
                         , g.version_id
                         , g.postal_code AS old_postal_code
                         , g.city_name   AS old_city_name
                         , UPPER(m.city) AS city_name
                         , v_country_name AS iso_country_name
                         , m.zip AS postal_code
                         , m.state AS state_code
                         , m.citytype AS city_type
                         , m.ziptype AS postal_type
                         , m.latitude
                         , m.longitude
                    FROM (
                           SELECT x.*
                             FROM us_geo_master x
                            WHERE x.zip  IS NOT NULL
                              AND x.city IS NOT NULL
                              AND x.state IS NOT NULL
                              AND REGEXP_LIKE(x.zip, '[[:alpha:]][[:digit:]][[:alpha:]] [[:digit:]][[:alpha:]][[:digit:]]')
                         ) m
                           FULL OUTER JOIN
                         (
                           SELECT y.*
                             FROM dm_geo_dim y
                            WHERE y.is_effective = 'Y'
                              AND y.country_dim_id = v_country_dim_id
                              AND y.postal_code IS NOT NULL
                              AND y.city_name IS NOT NULL
                         ) g
                      ON g.postal_code = m.zip
                     AND g.city_name = UPPER(m.city)
                   WHERE (
                              NVL(g.postal_code, '?') <> NVL(m.zip, '?')
                           OR NVL(g.city_name, '?')   <> NVL(UPPER(m.city), '?')
                           OR g.state_code            <> m.state
                           OR g.city_name             <> UPPER(m.city)
                           OR g.city_type             <> m.citytype
                           OR g.postal_type           <> m.ziptype
                           OR g.latitude              <> m.latitude
                           OR g.longitude             <> m.longitude
                         )
                ) k, 
                (
                  SELECT g2.state_code, g2.state_name
                    FROM dm_geo_dim g2
                   WHERE g2.country_dim_id = v_country_dim_id
                     AND g2.state_code IS NOT NULL
                     AND g2.state_name IS NOT NULL
                     AND g2.city_name IS NULL
                     AND g2.is_effective = 'Y'
                ) l
          WHERE l.state_code (+) = k.state_code;
   BEGIN
         v_country_name := 'CANADA';
         SELECT country_dim_id
           INTO v_country_dim_id
           FROM dm_country_dim
          WHERE iso_country_name = v_country_name;

         FOR r1 IN c1
         LOOP
              IF (r1.geo_dim_id IS NULL)
                 THEN
                      --
                      -- Add any brand new US City/Postal codes Combinations that 
                      -- have been added in this data update from Vendor 
                      --
                      INSERT INTO dm_geo_dim
                      (
                           country_dim_id
                         , geo_dim_id
                         , postal_code
                         , state_name
                         , city_name
                         , iso_country_name
                         , state_code
                         , city_type
                         , postal_type
                         , latitude
                         , longitude
                         , version_id
                         , is_effective
                         , valid_from_date
                         , valid_to_date
                         , last_update_date
                      )
                      VALUES
                      (
                         v_country_dim_id --country_dim_id
                       , dm_geo_dim_seq.NEXTVAL --geo_dim_id
                       , r1.postal_code
                       , r1.state_name
                       , r1.city_name
                       , v_country_name -- iso_country_name
                       , r1.state_code
                       , r1.city_type
                       , r1.postal_type
                       , r1.latitude
                       , r1.longitude
                       , 1 -- version_id
                       , 'Y' -- is_effective
                       , c_def_from_date -- valid_from_date
                       , NULL -- valid_to_date 
                       , SYSDATE -- last_update_date
                      );
                 ELSE
                      /*
                      ** Disable old version of geo_dim_id for the changed postal code/City Combination
                      */
                      UPDATE dm_geo_dim g
                         SET   g.is_effective = 'N'
                             , g.valid_to_date = TO_DATE(p_release_date, 'YYYYMMDD') -(1/86400)
                             , g.last_update_date = SYSDATE
                       WHERE g.geo_dim_id = r1.geo_dim_id;

                      IF (r1.postal_code IS NOT NULL AND r1.city_name IS NOT NULL)
                         THEN
                              /* Existing Postal Code/City combination but something changed */

                              /*
                              ** Get and Insert new geo_dim_id for the changed postal code
                              */
                              INSERT INTO dm_geo_dim
                              (
                                 country_dim_id
                               , geo_dim_id
                               , postal_code
                               , state_name
                               , city_name
                               , iso_country_name
                               , state_code
                               , city_type
                               , postal_type
                               , latitude
                               , longitude
                               , version_id
                               , is_effective
                               , valid_from_date
                               , valid_to_date
                               , last_update_date
                              ) VALUES
                              (
                                 v_country_dim_id
                               , dm_geo_dim_seq.NEXTVAL
                               , r1.postal_code
                               , r1.state_name
                               , r1.city_name
                               , v_country_name
                               , r1.state_code
                               , r1.city_type
                               , r1.postal_type
                               , r1.latitude
                               , r1.longitude
                               , r1.version_id + 1
                               , 'Y' --is_effective
                               , TO_DATE(p_release_date, 'YYYYMMDD') -- valid_from_date
                               , NULL -- valid_to_date 
                               , SYSDATE
                              );
                      END IF;
              END IF; -- Check  if r1.geo_dim_id IS NULL
         END LOOP;
         COMMIT;
   END update_canada_geo_dim;

   PROCEDURE cleanup_geo_master
   IS
   BEGIN
         EXECUTE IMMEDIATE 'TRUNCATE TABLE us_geo_master';
   END cleanup_geo_master;
   PROCEDURE add_extra_indexes
   IS
   BEGIN
         EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX AK_DM_GEO_DIM ON DM_GEO_DIM (COUNTRY_DIM_ID, STATE_NAME, CITY_NAME, POSTAL_CODE) TABLESPACE MART_INDX INVISIBLE';
         EXECUTE IMMEDIATE 'CREATE INDEX DM_GEO_DIM_N3 ON DM_GEO_DIM (COUNTRY_DIM_ID, STATE_CODE) TABLESPACE MART_INDX INVISIBLE';
   END add_extra_indexes;
   PROCEDURE drop_extra_indexes
   IS
   BEGIN
         EXECUTE IMMEDIATE 'DROP INDEX AK_DM_GEO_DIM';
         EXECUTE IMMEDIATE 'DROP INDEX DM_GEO_DIM_N3';
   END drop_extra_indexes;
END dm_geo;
/