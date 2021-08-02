CREATE OR REPLACE FORCE VIEW lego_cac1_vw
AS
SELECT cac_guid            AS cac1_guid,
       cac_oid             AS cac1_oid,
       cac_value           AS cac1_value,
       cac_desc            AS cac1_desc,
       cac_segment_1_id    AS cac1_segment_1_id,
       cac_segment_1_value AS cac1_segment_1_value,
       cac_segment_1_desc  AS cac1_segment_1_desc,
       cac_segment_2_id    AS cac1_segment_2_id,
       cac_segment_2_value AS cac1_segment_2_value,
       cac_segment_2_desc  AS cac1_segment_2_desc,
       cac_segment_3_id    AS cac1_segment_3_id,
       cac_segment_3_value AS cac1_segment_3_value,
       cac_segment_3_desc  AS cac1_segment_3_desc,
       cac_segment_4_id    AS cac1_segment_4_id,
       cac_segment_4_value AS cac1_segment_4_value,
       cac_segment_4_desc  AS cac1_segment_4_desc,
       cac_segment_5_id    AS cac1_segment_5_id,
       cac_segment_5_value AS cac1_segment_5_value,
       cac_segment_5_desc  AS cac1_segment_5_desc
  FROM lego_cac
/

CREATE OR REPLACE FORCE VIEW lego_cac2_vw
AS
SELECT cac_guid            AS cac2_guid,
       cac_oid             AS cac2_oid,
       cac_value           AS cac2_value,
       cac_desc            AS cac2_desc,
       cac_segment_1_id    AS cac2_segment_1_id,
       cac_segment_1_value AS cac2_segment_1_value,
       cac_segment_1_desc  AS cac2_segment_1_desc,
       cac_segment_2_id    AS cac2_segment_2_id,
       cac_segment_2_value AS cac2_segment_2_value,
       cac_segment_2_desc  AS cac2_segment_2_desc,
       cac_segment_3_id    AS cac2_segment_3_id,
       cac_segment_3_value AS cac2_segment_3_value,
       cac_segment_3_desc  AS cac2_segment_3_desc,
       cac_segment_4_id    AS cac2_segment_4_id,
       cac_segment_4_value AS cac2_segment_4_value,
       cac_segment_4_desc  AS cac2_segment_4_desc,
       cac_segment_5_id    AS cac2_segment_5_id,
       cac_segment_5_value AS cac2_segment_5_value,
       cac_segment_5_desc  AS cac2_segment_5_desc
  FROM lego_cac
/
