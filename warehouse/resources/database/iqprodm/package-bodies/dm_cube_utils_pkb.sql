CREATE OR REPLACE PACKAGE BODY dm_cube_utils
/******************************************************************************
 * Name:   dm_cube_utils
 * Desc:   This package contains all the utility/common program units
 *         required for spend
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj   08/06/2010    Initial
 * SajeevS 02/22/2011    Added functions for get_worker_dim_id
 * SajeevS 03/07/2011    Added functions get_date_dim_id,get_top_parent_org_id,
 *                       dm_date_dim_process,get_data_source_id
 * Manoj   03/12/2011    Added get_usd_rate and get_usd_amount functions.
 * sajeev  03/24/2011    Modified dm_date_dim_process to take care of new week_id,month_id,qtr_id,year_id
 * Sajeev  03/31/2011    Modified the procedure dm_date_dim_process
 * Sajeev  04/15/2011    Added dm_fiscal_calendar_update
 * Sajeev  07/06/2011    Modified dm_fiscal_calendar_update
 * Sajeev  09/07/2011    Added function get_business_days
 * Sajeev  11/21/2011    Added function get_job_status
 * Sajeev  12/06/2011    Added functions get_currency_code,get_curr_conv_dim_id,get_converted_rate
 * Sajeev  01/03/2012    Added function get_curr_conv_dim_id
 * prasad  02/24/2012    Added procedures to make most of DM indexes invisible
 * prasad  02/27/2012    Changed functions to start using dm_assignment_dim instead of dm_assignments
 *                       Added new function get_assignment_dim_id
 * Sajeev  03/13/2012    Modified get_expenditure_dim_id and get_expenditure_category
 * Sajeev  08/08/2012    Added NVL for top_parent_org_id
 *******************************************************************************/
AS
 /*****************************************************************
  * Name: get_country_dim_id
  * Desc: This function gets the Country Dimension Identifer
  *****************************************************************/
  FUNCTION get_country_dim_id(iv_country_name IN VARCHAR2)
  RETURN NUMBER
  IS
    ln_country_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT country_dim_id
        INTO ln_country_dim_id
        FROM dm_country_dim
       WHERE iso_country_name = iv_country_name;
    EXCEPTION
      WHEN OTHERS THEN
        ln_country_dim_id := 0;
    END;

    RETURN ln_country_dim_id;

  END get_country_dim_id;

 /*****************************************************************
  * Name: get_currency_dim_id
  * Desc: This function gets the Currency Dimension Identifer
  *****************************************************************/
  FUNCTION get_currency_dim_id(iv_currency IN VARCHAR2)
  RETURN NUMBER
  IS
    ln_currency_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT currency_dim_id
        INTO ln_currency_dim_id
        FROM dm_currency_dim
       WHERE currency_code = iv_currency;
    EXCEPTION
      WHEN OTHERS THEN
        ln_currency_dim_id := 0;
    END;

    RETURN ln_currency_dim_id;

  END get_currency_dim_id;

 /*****************************************************************
  * Name: get_time_dim_id
  * Desc: This function gets the Time Dimension Identifer
  *****************************************************************/
  FUNCTION get_time_dim_id(id_date IN DATE)
  RETURN NUMBER
  IS
    ln_time_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT time_dim_id
        INTO ln_time_dim_id
        FROM dm_time_dim
       WHERE hour24  = to_number(to_char(id_date,'HH24'))
         AND minutes = to_number(to_char(id_date,'MI'))
         AND seconds = to_number(to_char(id_date,'SS'));
    EXCEPTION
      WHEN OTHERS THEN
        ln_time_dim_id := 0;
    END;

    RETURN ln_time_dim_id;

  END get_time_dim_id;

 /*****************************************************************
  * Name: get_engagement_type_dim_id
  * Desc: This function gets the Engagement Type Dimension Identifer
  *****************************************************************/
  FUNCTION get_engagement_type_dim_id(iv_engagement_type IN VARCHAR2)
  RETURN NUMBER
  IS
    ln_engagement_type_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT engagement_type_dim_id
        INTO ln_engagement_type_dim_id
        FROM dm_engagement_type_dim
       WHERE engagement_type  = iv_engagement_type;
    EXCEPTION
      WHEN OTHERS THEN
        ln_engagement_type_dim_id := 0;
    END;

    RETURN ln_engagement_type_dim_id;

  END get_engagement_type_dim_id;

 /*****************************************************************
  * Name: get_project_agreement_dim_id
  * Desc: This function gets the Engagement Type Dimension Identifer
  *****************************************************************/
  FUNCTION get_project_agreement_dim_id(in_pa_id            IN NUMBER,
                                        id_invoice_date     IN DATE,
                                        iv_data_source_code IN VARCHAR2,
                                        in_buyer_org_id     IN NUMBER)
  RETURN NUMBER
  IS
    ln_project_agreement_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT pa_dim_id
        INTO ln_project_agreement_dim_id
        FROM dm_project_agreement_dim
       WHERE pa_id  = in_pa_id
         AND id_invoice_date BETWEEN valid_from_date AND nvl(valid_to_date,id_invoice_date)
         AND data_source_code =iv_data_source_code;
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
      SELECT pa_dim_id
        INTO ln_project_agreement_dim_id
        FROM dm_project_agreement_dim
       WHERE pa_id  = in_pa_id
         AND id_invoice_date BETWEEN valid_from_date AND nvl(valid_to_date,id_invoice_date)
         AND data_source_code =iv_data_source_code
         and IS_EFFECTIVE = 'Y' AND ROWNUM =1;
      WHEN OTHERS THEN

        ln_project_agreement_dim_id := -1*in_buyer_org_id;
    END;

    RETURN ln_project_agreement_dim_id;

  END get_project_agreement_dim_id;

 /*****************************************************************
  * Name: get_job_dim_id
  * Desc: This function gets the Job Dimension Identifer
  *****************************************************************/
  FUNCTION get_job_dim_id(in_job_id           IN NUMBER,
                          id_invoice_date     IN DATE,
                          iv_data_source_code IN VARCHAR2,
                          in_buyer_org_id     IN NUMBER)
  RETURN NUMBER
  IS
    ln_job_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT job_dim_id
        INTO ln_job_dim_id
        FROM dm_job_dim
       WHERE job_id  = in_job_id
         AND id_invoice_date BETWEEN valid_from_date AND nvl(valid_to_date,id_invoice_date)
         AND data_source_code =iv_data_source_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SELECT nvl(MAX(job_dim_id),(-1*in_buyer_org_id))
          INTO ln_job_dim_id
          FROM dm_job_dim
         WHERE job_id  = in_job_id
           AND data_source_code =iv_data_source_code;
      WHEN OTHERS THEN
        ln_job_dim_id := -1*in_buyer_org_id;
    END;

    RETURN ln_job_dim_id;

  END get_job_dim_id;

/*****************************************************************
  * Name: get_invoiced_cac_dim_id
  * Desc: This function gets the Job Dimension Identifer
  *****************************************************************/
  FUNCTION get_invoiced_cac_dim_id(in_buyerorg_id      IN NUMBER,
                                   iv_cac1_seg1_value  IN VARCHAR2,
                                   iv_cac1_seg2_value  IN VARCHAR2,
                                   iv_cac1_seg3_value  IN VARCHAR2,
                                   iv_cac1_seg4_value  IN VARCHAR2,
                                   iv_cac1_seg5_value  IN VARCHAR2,
                                   iv_cac2_seg1_value  IN VARCHAR2,
                                   iv_cac2_seg2_value  IN VARCHAR2,
                                   iv_cac2_seg3_value  IN VARCHAR2,
                                   iv_cac2_seg4_value  IN VARCHAR2,
                                   iv_cac2_seg5_value  IN VARCHAR2,
                                   iv_data_source_code IN VARCHAR2)
  RETURN NUMBER
  IS
    ln_invoiced_cac_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT inv_cac_dim_id
        INTO ln_invoiced_cac_dim_id
        FROM dm_invoiced_cac_dim
       WHERE buyerorg_id              = in_buyerorg_id
         AND nvl(cac1_seg1_value,'x') = nvl(iv_cac1_seg1_value,'x')
         AND nvl(cac1_seg2_value,'x') = nvl(iv_cac1_seg2_value,'x')
         AND nvl(cac1_seg3_value,'x') = nvl(iv_cac1_seg3_value,'x')
         AND nvl(cac1_seg4_value,'x') = nvl(iv_cac1_seg4_value,'x')
         AND nvl(cac1_seg5_value,'x') = nvl(iv_cac1_seg5_value,'x')
         AND nvl(cac2_seg1_value,'x') = nvl(iv_cac2_seg1_value,'x')
         AND nvl(cac2_seg2_value,'x') = nvl(iv_cac2_seg2_value,'x')
         AND nvl(cac2_seg3_value,'x') = nvl(iv_cac2_seg3_value,'x')
         AND nvl(cac2_seg4_value,'x') = nvl(iv_cac2_seg4_value,'x')
         AND nvl(cac2_seg5_value,'x') = nvl(iv_cac2_seg5_value,'x')
         AND is_effective = 'Y'
         AND data_source_code         = iv_data_source_code;
    EXCEPTION
      WHEN OTHERS THEN
        ln_invoiced_cac_dim_id := -1*in_buyerorg_id;
    END;

    RETURN ln_invoiced_cac_dim_id;

  END get_invoiced_cac_dim_id;

 /*****************************************************************
  * Name: get_expenditure_dim_id
  * Desc: This function gets the expenditure Dimension Identifer
  *****************************************************************/
  FUNCTION get_expenditure_dim_id(iv_spend_category   IN VARCHAR2,
                                  iv_spend_type       IN VARCHAR2,
                                  iv_fo_bo_flag       IN VARCHAR2)
  RETURN NUMBER
  IS
    ln_expenditure_dim_id NUMBER;
    lv_spend_category  varchar2(200);
  BEGIN

  IF iv_fo_bo_flag = 'FOI' THEN
      IF iv_spend_category = 'Tax and Discounts' THEN
        IF iv_spend_type = 'TAX' THEN
           lv_spend_category := 'Tax';
        ELSIF iv_spend_type = 'Flex - MFR' THEN
           lv_spend_category := 'Rebates';
        ELSIF iv_spend_type = 'TD' THEN
           lv_spend_category := 'Discounts';
        ELSE
          lv_spend_category := iv_spend_category;
        END IF;
      ELSE
        lv_spend_category := iv_spend_category;
      END IF;
  ELSE
      lv_spend_category := iv_spend_category;
  END IF;

    BEGIN
        SELECT expenditure_dim_id
          INTO ln_expenditure_dim_id
          FROM dm_expenditure_dim
         WHERE spend_category = lv_spend_category
           AND spend_type     = iv_spend_type
           AND inv_object_source = iv_fo_bo_flag
           AND data_source_code = 'REGULAR';
      EXCEPTION
        WHEN OTHERS THEN
          ln_expenditure_dim_id := 0;
      END;


   /********************************
    IF iv_fo_bo_flag = 'Milestones' THEN  -- iv_fo_bo_flag is overloaded to accomodate a milestone parameter instead of fo bo flag
      --
      -- for milestones IQN expenditure category is used
      --
      BEGIN
        SELECT expenditure_dim_id
          INTO ln_expenditure_dim_id
          FROM dm_expenditure_dim
         WHERE iqn_expenditure_category = iv_spend_category
           AND iqn_expenditure_type     = iv_spend_type;
      EXCEPTION
        WHEN OTHERS THEN
          ln_expenditure_dim_id := 0;
      END;
   ELSE
    IF iv_fo_bo_flag = 'FOI' THEN
      IF iv_spend_category = 'Tax and Discounts' THEN
        IF iv_spend_type = 'TAX' THEN
           lv_spend_category := 'Tax';
        ELSIF iv_spend_type = 'Flex - MFR' THEN
           lv_spend_category := 'Rebates';
        ELSIF iv_spend_type = 'TD' THEN
           lv_spend_category := 'Discounts';
        ELSE
          lv_spend_category := iv_spend_category;
        END IF;
      ELSE
        lv_spend_category := iv_spend_category;
      END IF;

      BEGIN
        SELECT expenditure_dim_id
          INTO ln_expenditure_dim_id
          FROM dm_expenditure_dim
         WHERE expenditure_category = lv_spend_category
           AND expenditure_type     = iv_spend_type;
      EXCEPTION
        WHEN OTHERS THEN
          ln_expenditure_dim_id := 0;
      END;
    ELSE
      BEGIN
        SELECT expenditure_dim_id
          INTO ln_expenditure_dim_id
          FROM dm_expenditure_dim dim,
               dm_bo_expenditure_x box
         WHERE box.dim_expenditure_category = dim.expenditure_category
           AND box.dim_expenditure_type     = dim.expenditure_type
           AND box.spend_category           = iv_spend_category
           AND box.spend_type               = iv_spend_type;
      EXCEPTION
        WHEN OTHERS THEN
          ln_expenditure_dim_id := 0;
      END;

    END IF;
   END IF; 
********************************/

   RETURN ln_expenditure_dim_id;

  END get_expenditure_dim_id;

  FUNCTION get_assignment_dim_id
  (
      p_assignment_id    dm_assignment_dim.assignment_id%TYPE
    , p_data_source_code dm_assignment_dim.data_source_code%TYPE
  )
  RETURN dm_assignment_dim.assignment_dim_id%TYPE
  IS
        v_assignment_dim_id dm_assignment_dim.assignment_dim_id%TYPE := 0;
  BEGIN
        SELECT assignment_dim_id
          INTO v_assignment_dim_id
          FROM dm_assignment_dim
         WHERE assignment_id    = p_assignment_id
           AND data_source_code = p_data_source_code;

        RETURN(v_assignment_dim_id);
  EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN(v_assignment_dim_id);
  END get_assignment_dim_id;

 /*****************************************************************
  * Name: get_geo_dim_id
  * Desc: This function gets the Geo Dimension Identifer
  *****************************************************************/
  FUNCTION get_geo_dim_id
   (
       p_country_name dm_country_dim.iso_country_name%TYPE
     , p_state_name   dm_geo_dim.state_name%TYPE
     , p_city_name    dm_geo_dim.city_name%TYPE
     , p_postal_code  dm_geo_dim.postal_code%TYPE
   )
   RETURN dm_geo_dim.geo_dim_id%TYPE
   IS
       v_country_dim_id   dm_country_dim.country_dim_id%TYPE;
       v_iso_country_code dm_country_dim.iso_country_code%TYPE;
       v_geo_dim_id       dm_geo_dim.geo_dim_id%TYPE := 0;
       v_country_geo_id   dm_geo_dim.geo_dim_id%TYPE := 0;
       v_state_geo_id     dm_geo_dim.geo_dim_id%TYPE := 0;
       v_state_name       dm_geo_dim.state_name%TYPE;
       v_eff_state_name   dm_geo_dim.state_name%TYPE := UPPER(p_state_name);
       v_state_len        PLS_INTEGER;
       v_city_name        dm_geo_dim.city_name%TYPE;
       v_match_score      PLS_INTEGER;
       v_postal_code      dm_geo_dim.postal_code%TYPE := SUBSTR(p_postal_code, 1, 16);
   BEGIN
         IF (p_country_name IS NULL)
            THEN
                 RETURN(v_geo_dim_id);
            ELSE
                 BEGIN
                       SELECT country_dim_id,   iso_country_code
                         INTO v_country_dim_id, v_iso_country_code
                         FROM dm_country_dim
                        WHERE iso_country_name = UPPER(p_country_name);

                       BEGIN
                             SELECT geo_dim_id
                               INTO v_country_geo_id
                               FROM dm_geo_dim
                              WHERE country_dim_id = v_country_dim_id
                                AND is_effective = 'Y'
                                AND postal_code IS NULL
                                AND state_name  IS NULL
                                AND city_name   IS NULL;
                       EXCEPTION
                            WHEN NO_DATA_FOUND THEN RETURN(v_country_geo_id);
                       END;

                       IF (v_iso_country_code != 'US')
                          THEN
                               /*
                               ** Only Country level available for Non-US
                               */
                               RETURN(v_country_geo_id);
                          ELSE
                               /*
                               ** Country is US but no other info is available
                               */
                               IF (v_eff_state_name IS NULL AND p_city_name IS NULL AND v_postal_code IS NULL)
                                  THEN
                                       RETURN(v_country_geo_id);
                               END IF;
                       END IF;
                 EXCEPTION
                      WHEN NO_DATA_FOUND THEN RETURN(v_geo_dim_id);
                 END;
         END IF;

         IF (v_eff_state_name IS NOT NULL)
            THEN
                 BEGIN
                       IF (v_iso_country_code = 'US' AND LENGTH(v_eff_state_name) = 2)
                          THEN
                               SELECT geo_dim_id, state_name
                                 INTO v_state_geo_id, v_eff_state_name
                                 FROM dm_geo_dim
                                WHERE country_dim_id = v_country_dim_id
                                  AND is_effective = 'Y'
                                  AND state_name  IS NOT NULL
                                  AND state_code = UPPER(v_eff_state_name)
                                  AND postal_code IS NULL
                                  AND city_name   IS NULL;
                          ELSE
                               SELECT geo_dim_id
                                 INTO v_state_geo_id
                                 FROM dm_geo_dim
                                WHERE country_dim_id = v_country_dim_id
                                  AND is_effective = 'Y'
                                  AND state_name  IS NOT NULL
                                  AND state_name = UPPER(v_eff_state_name)
                                  AND postal_code IS NULL
                                  AND city_name   IS NULL;
                       END IF;
                 EXCEPTION
                       WHEN NO_DATA_FOUND THEN NULL;
                 END;
         END IF;

         IF (v_postal_code IS NOT NULL)
            THEN
                 BEGIN
                       IF (v_iso_country_code = 'US')
                          THEN
                               /*
                               ** If country is US limit zipcode search to first 5 characters
                               ** This should strip off any special characters
                               ** and also zip plus+4  codes at the end improving match rates
                               */
                               v_postal_code := SUBSTR(v_postal_code, 1, 5);
                       END IF;

                       SELECT geo_dim_id  , state_name  , city_name
                         INTO v_geo_dim_id, v_state_name, v_city_name
                         FROM dm_geo_dim
                        WHERE country_dim_id = v_country_dim_id
                          AND is_effective = 'Y'
                          AND postal_code IS NOT NULL
                          AND postal_code    = v_postal_code;

                       /*
                       ** if both State Name and City Name not available, Trust Postal code
                       ** and use the geo id found
                       */
                       IF (v_eff_state_name IS NULL AND p_city_name IS NULL)
                          THEN
                               RETURN(v_geo_dim_id);
                       END IF;

                       v_match_score := 1;
                       IF (v_eff_state_name IS NOT NULL AND v_eff_state_name = v_state_name)
                          THEN
                               v_match_score := v_match_score + 1;
                       END IF;

                       IF (p_city_name IS NOT NULL AND UPPER(p_city_name) = v_city_name)
                          THEN
                               v_match_score := v_match_score + 1;
                       END IF;

                       /*
                       ** if at least two of the "State Name, City Name and Postal code"
                       ** matches use the geo id found
                       */
                       IF (v_match_score >= 2)
                          THEN
                               RETURN(v_geo_dim_id);
                       END IF;
                 EXCEPTION
                      WHEN NO_DATA_FOUND THEN NULL;
                 END;
         END IF;

         IF (p_city_name IS NOT NULL)
            THEN
                 IF (v_eff_state_name IS NOT NULL AND v_state_geo_id > 0)
                    THEN
                         BEGIN
                               SELECT geo_dim_id
                                 INTO v_geo_dim_id
                                 FROM (
                                        SELECT geo_dim_id, RANK() OVER (ORDER BY NVL2(postal_code, 2, 1), postal_code) AS rnk
                                          FROM dm_geo_dim
                                         WHERE country_dim_id = v_country_dim_id
                                           AND is_effective = 'Y'
                                           AND state_name  IS NOT NULL
                                           AND state_name = v_eff_state_name
                                           AND city_name   IS NOT NULL
                                           AND city_name  = UPPER(p_city_name)
                                      ) t
                                WHERE t.rnk = 1;

                               RETURN(v_geo_dim_id);
                         EXCEPTION
                              WHEN NO_DATA_FOUND THEN NULL; --RETURN(v_state_geo_id);
                         END;
                 END IF;

                 -- See if City is unique to a State or Postal code
                 BEGIN
                       SELECT geo_dim_id
                         INTO v_geo_dim_id
                         FROM (
                                SELECT   geo_dim_id
                                       , COUNT(DISTINCT g.state_name) OVER (PARTITION BY g.city_name) AS state_count
                                       --, count(DISTINCT g.postal_code) OVER (partition by g.state_name, g.city_name) postal_count
                                       , RANK() OVER (PARTITION BY g.state_name, g.city_name ORDER BY NVL2(postal_code, 2, 1), postal_code) AS rnk
                                  FROM dm_geo_dim g
                                 WHERE country_dim_id = v_country_dim_id
                                   AND is_effective = 'Y'
                                   AND city_name   IS NOT NULL
                                   AND city_name  = UPPER(p_city_name)
                              ) t
                        WHERE t.state_count = 1
                          AND t.rnk = 1;

                       RETURN(v_geo_dim_id);
                 EXCEPTION
                      WHEN NO_DATA_FOUND THEN NULL;
                 END;
         END IF;

         IF (v_state_geo_id > 0)
            THEN
                 RETURN(v_state_geo_id);
            ELSE
                 RETURN(v_country_geo_id);
         END IF;
   END get_geo_dim_id;

 /*****************************************************************
  * Name: get_ratecard_dim_id
  * Desc: This function gets the Rate Card Dimension Identifer
  *****************************************************************/
  FUNCTION get_ratecard_dim_id
       (in_assign_id              IN NUMBER,
        in_data_source_code       IN VARCHAR2,
        in_buyer_org_id           IN NUMBER)
  RETURN NUMBER
  IS
       ln_ratecard_dim_id        NUMBER;
       ln_buyer_firm_fk          NUMBER;
       ln_supplier_firm_fk       NUMBER;
       ln_ratecard_identifier_id NUMBER;
       ln_job_template_id        NUMBER;
  BEGIN
    BEGIN
         SELECT source_template_id,
                buyer_bro_firm_id,
                supplier_bro_firm_id,
                rate_card_identifier_fk
           INTO ln_job_template_id,
                ln_buyer_firm_fk,
                ln_supplier_firm_fk,
                ln_ratecard_identifier_id
           FROM dm_assignment_dim
          WHERE assignment_id    = in_assign_id
            AND data_source_code = in_data_source_code;

       BEGIN
         SELECT ratecard_dim_id
           INTO ln_ratecard_dim_id
           FROM dm_ratecard_dim
          WHERE buyer_firm_fk          = ln_buyer_firm_fk
            AND supplier_firm_fk       = ln_supplier_firm_fk
            AND job_template_id        = ln_job_template_id
            AND ratecard_identifier_id = ln_ratecard_identifier_id
            AND data_source_code       = in_data_source_code
            AND is_effective           = 'Y';
       EXCEPTION
         WHEN OTHERS THEN
           ln_ratecard_dim_id := -1*in_buyer_org_id;
       END;

    EXCEPTION
      WHEN OTHERS THEN
         ln_ratecard_dim_id := -1*in_buyer_org_id;
    END;

    RETURN ln_ratecard_dim_id;

  END get_ratecard_dim_id;

 /*****************************************************************
  * Name: get_person_dim_id
  * Desc: This function gets the Rate Card Dimension Identifer
  *****************************************************************/
  FUNCTION get_person_dim_id
       (in_person_id        IN NUMBER
       ,in_invoice_date     IN DATE
       ,in_data_source_code IN VARCHAR2
       ,in_buyer_org_id     IN NUMBER)
  RETURN NUMBER
  IS
       ln_person_dim_id     NUMBER;
  BEGIN
       BEGIN
         SELECT person_dim_id
           INTO ln_person_dim_id
           FROM dm_person_dim
          WHERE person_id = in_person_id
            AND data_source_code = in_data_source_code
            AND in_invoice_date BETWEEN valid_from_date AND NVL(valid_to_date,in_invoice_date)
            AND rownum =1;
       EXCEPTION
         WHEN OTHERS THEN
           ln_person_dim_id := -1*in_buyer_org_id;
       END;

       RETURN ln_person_dim_id;

  END get_person_dim_id;

 /*****************************************************************
  * Name: get_organization_dim_id
  * Desc: This function gets the Organization Dimension Identifer
  *****************************************************************/
  FUNCTION get_organization_dim_id
    (
        p_org_id           IN dm_organization_dim.org_id%TYPE
      , p_invoice_date     IN DATE
      , p_data_source_code IN VARCHAR2
    )
  RETURN dm_organization_dim.org_dim_id%TYPE
  IS
          v_org_dim_id dm_organization_dim.org_dim_id%TYPE := 0;
  BEGIN
          SELECT o.org_dim_id
            INTO v_org_dim_id
            FROM dm_organization_dim o
           WHERE o.org_id = p_org_id
             AND o.data_source_code = p_data_source_code
             AND p_invoice_date BETWEEN o.valid_from_date AND NVL(o.valid_to_date, p_invoice_date);

          RETURN(v_org_dim_id);
  EXCEPTION
         WHEN NO_DATA_FOUND then
          SELECT NVL(MAX(o.org_dim_id),0)
            INTO v_org_dim_id
            FROM dm_organization_dim o
           WHERE o.org_id = p_org_id
             AND o.data_source_code = p_data_source_code;
           RETURN(v_org_dim_id);
         WHEN OTHERS THEN RETURN(v_org_dim_id);
  END get_organization_dim_id;

 /**********************************************************************
  * Name: get_org_geo_dim_id
  * Desc: This function gets the Organization's Geo Dimension Identifer
  **********************************************************************/
  FUNCTION get_org_geo_dim_id
    (
        p_org_id           IN dm_organization_dim.org_id%TYPE
      , p_invoice_date     IN DATE
      , p_data_source_code IN VARCHAR2
    )
  RETURN dm_organization_dim.primary_geo_dim_id%TYPE
  IS
          v_org_geo_dim_id dm_organization_dim.primary_geo_dim_id%TYPE := 0;
  BEGIN
          SELECT o.primary_geo_dim_id
            INTO v_org_geo_dim_id
            FROM dm_organization_dim o
           WHERE o.org_id = p_org_id
             AND o.data_source_code = p_data_source_code
             AND p_invoice_date BETWEEN o.valid_from_date AND NVL(o.valid_to_date, p_invoice_date);

          RETURN(v_org_geo_dim_id);
  EXCEPTION
         WHEN NO_DATA_FOUND THEN
          SELECT NVL(MAX(o.primary_geo_dim_id),0)
            INTO v_org_geo_dim_id
            FROM dm_organization_dim o
           WHERE o.org_id = p_org_id
             AND o.data_source_code = p_data_source_code; 
             
             RETURN(v_org_geo_dim_id);
             
         WHEN OTHERS THEN 
             RETURN(v_org_geo_dim_id);
  END get_org_geo_dim_id;

 /*****************************************************************
  * Name: get_expenditure_category
  * Desc: This function gets the expenditure category
  *****************************************************************/
  FUNCTION get_expenditure_category(iv_spend_category   IN VARCHAR2,
                                  iv_spend_type       IN VARCHAR2,
                                  iv_fo_bo_flag       IN VARCHAR2)
  RETURN VARCHAR2
  IS
    lv_expenditure_category VARCHAR2(100);
    lv_spend_category       varchar2(200);
  BEGIN

  IF iv_fo_bo_flag = 'FOI' THEN
      IF iv_spend_category = 'Tax and Discounts' THEN
        IF iv_spend_type = 'TAX' THEN
           lv_spend_category := 'Tax';
        ELSIF iv_spend_type = 'Flex - MFR' THEN
           lv_spend_category := 'Rebates';
        ELSIF iv_spend_type = 'TD' THEN
           lv_spend_category := 'Discounts';
        ELSE
          lv_spend_category := iv_spend_category;
        END IF;
      ELSE
        lv_spend_category := iv_spend_category;
      END IF;
  ELSE
      lv_spend_category := iv_spend_category;
  END IF;

   BEGIN
        SELECT expenditure_category
          INTO lv_expenditure_category
          FROM dm_expenditure_dim
         WHERE spend_category = lv_spend_category
           AND spend_type     = iv_spend_type
           AND inv_object_source = iv_fo_bo_flag
           AND data_source_code = 'REGULAR' ;

      EXCEPTION
        WHEN OTHERS THEN
          lv_expenditure_category := NULL;
      END;

/*********************************************
   IF iv_spend_category = 'Milestones' THEN
      lv_expenditure_category := 'Milestones';
   ELSE
    IF iv_fo_bo_flag = 'FOI' THEN

      IF iv_spend_category = 'Tax and Discounts' THEN
        IF iv_spend_type = 'TAX' THEN
           lv_spend_category := 'Tax';
        ELSIF iv_spend_type = 'Flex - MFR' THEN
           lv_spend_category := 'Rebates';
        ELSIF iv_spend_type = 'TD' THEN
           lv_spend_category := 'Discounts';
        ELSE
          lv_spend_category := iv_spend_category;
        END IF;
      ELSE
        lv_spend_category := iv_spend_category;
      END IF;

      BEGIN
        SELECT expenditure_category
          INTO lv_expenditure_category
          FROM dm_expenditure_dim
         WHERE expenditure_category = lv_spend_category
           AND expenditure_type     = iv_spend_type;
      EXCEPTION
        WHEN OTHERS THEN
          lv_expenditure_category := 'X';
      END;
    ELSE
      BEGIN
        SELECT expenditure_category
          INTO lv_expenditure_category
          FROM dm_expenditure_dim dim,
               dm_bo_expenditure_x box
         WHERE box.dim_expenditure_category = dim.expenditure_category
           AND box.dim_expenditure_type     = dim.expenditure_type
           AND box.spend_category           = iv_spend_category
           AND box.spend_type               = iv_spend_type;
      EXCEPTION
        WHEN OTHERS THEN
          lv_expenditure_category :='X';
      END;

    END IF;
   END IF;
***********************************************/

   RETURN lv_expenditure_category;

  END get_expenditure_category;

 /*****************************************************************
  * Name: get_assignment_actual_end_date
  * Desc: This function gets the Actual end date of the assignment from
  *       dm_assignment_dim table
  *****************************************************************/
  FUNCTION get_assignment_actual_end_date(in_assign_id        IN NUMBER,
                                          iv_data_source_code IN VARCHAR2)
  RETURN DATE
  IS
    ld_actual_end_date DATE;
  BEGIN
    BEGIN
      SELECT actual_end_date
        INTO ld_actual_end_date
        FROM dm_assignment_dim
       WHERE assignment_id     = in_assign_id
         AND data_source_code  = iv_data_source_code;
    EXCEPTION
      WHEN OTHERS THEN
        ld_actual_end_date :=NULL;
    END;

    RETURN ld_actual_end_date;

  END get_assignment_actual_end_date;

 /*****************************************************************
  * Name: get_work_loc_geo_dim_id
  * Desc: This function gets the Geo Dimension Identifer for
  *       work location
  *****************************************************************/
  FUNCTION get_work_loc_geo_dim_id
   (in_assign_id        IN NUMBER,
    iv_data_source_code IN VARCHAR2)
  RETURN dm_geo_dim.geo_dim_id%TYPE
  IS
    ln_work_loc_geo_dim_id            dm_geo_dim.geo_dim_id%TYPE :=0;
    lv_custom_country_name            dm_assignment_dim.custom_country_name%TYPE;
    lv_custom_address_state           dm_assignment_dim.custom_address_state%TYPE;
    lv_custom_address_city            dm_assignment_dim.custom_address_city%TYPE;
    lv_custom_address_postal_code     dm_assignment_dim.custom_address_postal_code%TYPE;
    lv_address_country_name           dm_assignment_dim.address_country_name%TYPE;
    lv_address_state                  dm_assignment_dim.address_state%TYPE;
    lv_address_city                   dm_assignment_dim.address_city%TYPE;
    lv_address_postal_code            dm_assignment_dim.address_postal_code%TYPE;
  BEGIN
    BEGIN
      SELECT custom_country_name,
             custom_address_state,
             custom_address_city,
             custom_address_postal_code,
             address_country_name,
             address_state,
             address_city,
             address_postal_code
        INTO lv_custom_country_name,
             lv_custom_address_state,
             lv_custom_address_city,
             lv_custom_address_postal_code,
             lv_address_country_name,
             lv_address_state,
             lv_address_city,
             lv_address_postal_code
        FROM dm_assignment_dim
       WHERE assignment_id     = in_assign_id
         AND data_source_code  = iv_data_source_code;


        ln_work_loc_geo_dim_id := DM_CUBE_UTILS.get_geo_dim_id(lv_custom_country_name,
                                                                     lv_custom_address_state,
                                                                     lv_custom_address_city,
                                                                     lv_custom_address_postal_code);

        IF nvl(ln_work_loc_geo_dim_id,0) = 0 THEN
           ln_work_loc_geo_dim_id := DM_CUBE_UTILS.get_geo_dim_id(lv_address_country_name,
                                                                        lv_address_state,
                                                                        lv_address_city,
                                                                        lv_address_postal_code);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          ln_work_loc_geo_dim_id :=0;
      END;

    RETURN ln_work_loc_geo_dim_id;

  END get_work_loc_geo_dim_id;
 /*****************************************************************
  * Name: get_iqn_expenditure_category
  * Desc: This function gets the IQN expenditure category
  *****************************************************************/
  FUNCTION get_iqn_expenditure_category(iv_spend_category   IN VARCHAR2,
                                        iv_spend_type       IN VARCHAR2,
                                        iv_fo_bo_flag       IN VARCHAR2)
  RETURN VARCHAR2
  IS
    lv_expenditure_category VARCHAR2(100);
    ln_expenditure_dim_id   NUMBER;
  BEGIN
    BEGIN
    /* IF iv_fo_bo_flag = 'Milestones' THEN
      ln_expenditure_dim_id := get_expenditure_dim_id(iv_spend_category,iv_spend_type,'Milestones');
     ELSE
      ln_expenditure_dim_id := get_expenditure_dim_id(iv_spend_category,iv_spend_type,iv_fo_bo_flag);
     END IF;
    */

      ln_expenditure_dim_id := get_expenditure_dim_id(iv_spend_category,iv_spend_type,iv_fo_bo_flag);

  
      BEGIN
     --   SELECT distinct iqn_expenditure_category
       SELECT distinct expenditure_category
          INTO lv_expenditure_category
          FROM dm_expenditure_dim
         WHERE expenditure_dim_id = ln_expenditure_dim_id;
      EXCEPTION
        WHEN OTHERS THEN
          lv_expenditure_category := NULL;
      END;
    EXCEPTION
     WHEN OTHERS THEN
       lv_expenditure_category := NULL;
    END;
    RETURN lv_expenditure_category;

  END get_iqn_expenditure_category; 
 /*****************************************************************
  * Name: get_iqn_expenditure_tyep
  * Desc: This function gets the IQN expenditure type
  *****************************************************************/
  FUNCTION get_iqn_expenditure_type(iv_spend_category   IN VARCHAR2,
                                    iv_spend_type       IN VARCHAR2,
                                    iv_fo_bo_flag       IN VARCHAR2)
  RETURN VARCHAR2
  IS
    lv_expenditure_type VARCHAR2(100);
    ln_expenditure_dim_id   NUMBER;
  BEGIN
    BEGIN
  --   IF iv_fo_bo_flag = 'Milestones' THEN
  --    ln_expenditure_dim_id := get_expenditure_dim_id(iv_spend_category,iv_spend_type,'Milestones');
  --   ELSE
      ln_expenditure_dim_id := get_expenditure_dim_id(iv_spend_category,iv_spend_type,iv_fo_bo_flag);
  --   END IF;

      BEGIN
      --  SELECT distinct iqn_expenditure_type
       SELECT distinct exp_sub_type
          INTO lv_expenditure_type
          FROM dm_expenditure_dim
         WHERE expenditure_dim_id = ln_expenditure_dim_id;
      EXCEPTION
        WHEN OTHERS THEN
          lv_expenditure_type := NULL;
      END;
    EXCEPTION
     WHEN OTHERS THEN
       lv_expenditure_type := NULL;
    END;
    RETURN lv_expenditure_type;

  END get_iqn_expenditure_type;

/*****************************************************************
  * Name: get_worker_dim_id
  * Desc: This function gets the Worker Dimension Identifer
  *****************************************************************/
  FUNCTION get_worker_dim_id(in_worker_id           IN NUMBER,
                          id_date     IN DATE,
                          iv_data_source_code IN VARCHAR2)
  RETURN NUMBER
  IS
    ln_worker_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT worker_dim_id
        INTO ln_worker_dim_id
        FROM dm_worker_dim
       WHERE worker_id  = in_worker_id
         AND id_date BETWEEN valid_from_date AND nvl(valid_to_date,id_date)
         AND data_source_code =iv_data_source_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
 	SELECT nvl(MAX(worker_dim_id),0)
        INTO ln_worker_dim_id
        FROM dm_worker_dim
       WHERE worker_id  = in_worker_id
         AND data_source_code =iv_data_source_code;
      WHEN OTHERS THEN
        ln_worker_dim_id := 0;
    END;

    RETURN ln_worker_dim_id;
  END get_worker_dim_id;

/*****************************************************************
  * Name: get_top_org_id
  * Desc: This function returns the top parent id for a buyer org dim id.
  *****************************************************************/
 FUNCTION get_top_org_id(in_buyer_org_dim_id IN NUMBER)
  RETURN NUMBER
  IS
    ln_top_parent_org_id NUMBER := 0 ;
  BEGIN
    BEGIN
       select CASE WHEN TOP_PARENT_ORG_ID = 0 THEN
                             org_id
                        ELSE TOP_PARENT_ORG_ID
                        END AS top_parent_org_id
             INTO ln_top_parent_org_id
             FROM dm_buyer_dim
	      WHERE org_dim_id = in_buyer_org_dim_id;
    EXCEPTION
      WHEN OTHERS THEN
        ln_top_parent_org_id := 0;
    END;

    RETURN ln_top_parent_org_id;
  END get_top_org_id;

/*****************************************************************
  * Name: get_top_parent_org_id
  * Desc: This function returns the top parent dim id for a buyer org id.
  *****************************************************************/
 FUNCTION get_top_parent_org_id(in_buyer_org_id IN NUMBER)
  RETURN NUMBER
  IS
    ln_top_parent_org_id NUMBER := in_buyer_org_id ;
  BEGIN
    BEGIN
       select CASE WHEN TOP_PARENT_ORG_ID = 0 THEN
                             org_id
                        ELSE TOP_PARENT_ORG_ID
                        END AS top_parent_org_id
             INTO ln_top_parent_org_id
             FROM dm_buyer_dim
	      WHERE is_effective = 'Y'
          	AND org_type = 'Buyer'
		AND org_id = in_buyer_org_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
            select MAX(CASE WHEN TOP_PARENT_ORG_ID = 0 THEN
                             org_id
                        ELSE TOP_PARENT_ORG_ID
                        END)
             INTO ln_top_parent_org_id
             FROM dm_buyer_dim
	      WHERE org_type = 'Buyer'
		AND org_id = in_buyer_org_id;
      WHEN OTHERS THEN
        ln_top_parent_org_id := in_buyer_org_id;
    END;

    RETURN NVL(ln_top_parent_org_id,0);
  END get_top_parent_org_id;


 /*****************************************************************
  * Name: get_date_dim_id
  * Desc: This function gets the Date Dimension Identifer
  *****************************************************************/
  FUNCTION get_date_dim_id(in_top_parent_buyer_org IN NUMBER, in_data_source_code IN VARCHAR2,id_date IN DATE)
  RETURN NUMBER
  IS
    ln_date_dim_id NUMBER;
  BEGIN
    BEGIN
      SELECT date_dim_id
        INTO ln_date_dim_id
        FROM dm_date_dim
       WHERE TOP_PARENT_BUYER_ORG_ID = in_top_parent_buyer_org
       AND DATA_SOURCE_CODE = NVL(in_data_source_code,'REGULAR')
       AND day_dt = trunc(id_date);
    EXCEPTION
      WHEN OTHERS THEN
        ln_date_dim_id := -1*in_top_parent_buyer_org;
    END;

    RETURN ln_date_dim_id;
  END get_date_dim_id;


 /*****************************************************************
  * Name: get_data_source_id
  * Desc: This function gets the data source id
  *****************************************************************/
  FUNCTION get_data_source_id(in_data_source_code IN VARCHAR2)
  RETURN NUMBER
  IS
    ln_data_source_id NUMBER := 100;
  BEGIN
    BEGIN
     select data_source_id
     into ln_data_source_id
     from DM_DATA_SOURCE
     where data_source_code = in_data_source_code;

    EXCEPTION
      WHEN OTHERS THEN
        ln_data_source_id := 100;
    END;

    RETURN ln_data_source_id;
  END get_data_source_id;

 /*****************************************************************
  * Name: get_buyer_country_name
  * Desc: This function gets the buyer country name
  *****************************************************************/
  FUNCTION get_buyer_country_name
    (
        p_org_id           IN dm_organization_dim.org_id%TYPE
      , p_data_source_code IN VARCHAR2
    )
  RETURN dm_organization_dim.FO_COUNTRY_NAME%TYPE
  IS
          v_org_country_name dm_organization_dim.FO_COUNTRY_NAME%TYPE;
  BEGIN
          SELECT  o.FO_COUNTRY_NAME
            INTO v_org_country_name
            FROM dm_organization_dim o
           WHERE o.org_id = p_org_id
             AND o.data_source_code = p_data_source_code
             and ROWNUM =1;

          RETURN(v_org_country_name);

  EXCEPTION
          WHEN OTHERS THEN
		RETURN NULL;
  END get_buyer_country_name;



/******************************************************************************
 * Name: get_usd_rate
 * Desc: Function to get usd converted rate
 *******************************************************************************/
   FUNCTION get_usd_rate(in_currency_code IN VARCHAR2, in_date IN DATE)
   RETURN NUMBER
   IS
    ln_conversion_rate NUMBER :=1;
   BEGIN
     IF in_currency_code = 'USD' THEN
        ln_conversion_rate := 1;
     ELSE
        BEGIN
         SELECT conversion_rate
           INTO ln_conversion_rate
           FROM dm_currency_conversion_rates
          WHERE from_currency_code = in_currency_code
            AND to_currency_code = 'USD'
            AND conversion_date = in_date;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_conversion_rate := 1;
        END;
     END IF;

     RETURN ln_conversion_rate;
   END get_usd_rate;

/******************************************************************************
 * Name: get_usd_amount
 * Desc: Function to get usd converted amount
 *******************************************************************************/
   FUNCTION get_usd_amount(in_currency_code IN VARCHAR2, in_date IN DATE,in_amount IN NUMBER)
   RETURN NUMBER
   IS
     ln_amount   NUMBER;
     ln_conversion_rate NUMBER :=1;
   BEGIN
     IF in_currency_code = 'USD' THEN
        ln_conversion_rate := 1;
     ELSE
        BEGIN
          SELECT conversion_rate
            INTO ln_conversion_rate
            FROM dm_currency_conversion_rates
           WHERE from_currency_code = in_currency_code
             AND to_currency_code = 'USD'
             AND conversion_date = in_date;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
             ln_conversion_rate := 1;
        END;
     END IF;

     ln_amount := nvl(in_amount,0) *  ln_conversion_rate;

     RETURN ln_amount;

   END get_usd_amount;

/******************************************************************************
 * Name: create_null_ratecard_dims
 * Desc: Procedure to insert dummay record 
 *******************************************************************************/
procedure create_null_ratecard_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2)
as
ln_err number;
begin
  begin
   INSERT INTO DM_RATECARD_DIM
     ( RATECARD_DIM_ID,
  	DATA_SOURCE_CODE,
  	VERSION_ID,
  	BUYERORG_ID,
  	RATECARD_ID,
  	RATECARD_IDENTIFIER_ID,
  	JOB_TEMPLATE_ID,
  	SUPPLIERORG_ID,
    	CURRENCY_DIM_ID,
  	IS_EFFECTIVE,
  	BATCH_ID,
  	LAST_UPDATE_DATE,
  	VALID_FROM_DATE )
    VALUES
    	(-1*in_buyer_org_id,
    	in_data_source_code,
    	in_buyer_org_id,
   	in_buyer_org_id,
   	0,
 	0,
  	0,
  	0,
    	0,
   	'Y',
  	in_msg_id,
  	sysdate,
  	to_date('1/1/1999','MM/DD/YYYY'));
  EXCEPTION
   WHEN OTHERS THEN 
           ln_err := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                        'Insert into create_null_ratecard_dims failed for null record creation',
                                                        SQLERRM,
                                                        'create_null_ratecard_dims');
   RAISE;                                                        
  END;             
end create_null_ratecard_dims;

/******************************************************************************
 * Name: create_null_person_dims
 * Desc: Procedure to insert dummay record 
 *******************************************************************************/

procedure create_null_person_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2)
as
ln_err number;
begin
  begin
   INSERT INTO dm_person_dim
     	       (PERSON_DIM_ID,
        	DATA_SOURCE_CODE,
        	PERSON_ID,
        	PERSON_SNAPSHOT_ID,
        	PERSON_TYPE,
        	FIRST_NAME,
        	LAST_NAME,
        	MIDDLE_NAME,
        	EMAIL_ADDRESS,
        	ORG_ID,
        	IS_EFFECTIVE,
        	BATCH_ID,
        	LAST_UPDATE_DATE,
        	VALID_FROM_DATE,
        	VALID_TO_DATE,
        	VERSION_ID)
    VALUES
    	(-1*in_buyer_org_id,
    	in_data_source_code,
    	-1*in_buyer_org_id,
    	0,
    	NULL,
    	'No Information Available',
      	'No Information Available',
    	'No Information Available',
    	'No Information Available',
    	in_buyer_org_id,
    	'Y',
    	in_msg_id,
    	sysdate,
    	to_date('1/1/1999','MM/DD/YYYY'),
    	null,
    	in_buyer_org_id
    	);
  
  EXCEPTION
   WHEN OTHERS THEN 
           ln_err  := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                        'Insert into create_null_person_dims failed for null record creation',
                                                        SQLERRM,
                                                        'create_null_person_dims');
   RAISE;                                                        
  END;             
end create_null_person_dims;

/******************************************************************************
 * Name: create_null_invoiced_cac_dims
 * Desc: Procedure to insert dummay record 
 *******************************************************************************/
procedure create_null_invoiced_cac_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2)
AS
	ln_err number;
begin
  begin
   INSERT INTO dm_invoiced_cac_dim
     ( INV_CAC_DIM_ID,
      VERSION_ID,
      DATA_SOURCE_CODE,
      BUYERORG_ID,
      IS_EFFECTIVE,
      VALID_FROM_DATE,
      BATCH_ID,
      LAST_UPDATE_DATE  )
   VALUES
    	(-1*in_buyer_org_id,
    	in_buyer_org_id,
        in_data_source_code,
       	in_buyer_org_id,
    	'Y',
    	to_date('1/1/1999','MM/DD/YYYY'),
    	in_msg_id,
        sysdate);
  
  EXCEPTION
   WHEN OTHERS THEN 
           ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                        'Insert into create_null_invoiced_cac_dims failed for null record creation',
                                                        SQLERRM,
                                                        'create_null_invoiced_cac_dims');
   RAISE;                                                        
  END;             
end create_null_invoiced_cac_dims;

/******************************************************************************
 * Name: create_null_pa_dims
 * Desc: Procedure to insert dummay record 
 *******************************************************************************/
procedure create_null_pa_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2)
AS
	ln_err number;
begin
  begin
   INSERT  INTO DM_PROJECT_AGREEMENT_DIM
     ( PA_DIM_ID ,
    	PA_ID,
    	PA_CONTRACT_VERSION,
    	DATA_SOURCE_CODE ,
    	VERSION_ID,
    	PA_NAME,
    	PA_DESC,
    	PA_EVENT_EFFECTIVE_DATE,
    	PA_APPROVED_DATE,
    	PA_START_DATE,
    	PA_END_DATE,
    	HAS_MILESTONES ,
    	HAS_PR,
    	HAS_RATE_TABLE_PR,
    	HAS_CTW,
    	HAS_TIME_EXP,
    	BUYERORG_ID,
      	IS_EFFECTIVE ,
    	VALID_FROM_DATE,
    	BATCH_ID,
    	LAST_UPDATE_DATE )
    VALUES
    	(
        -1*in_buyer_org_id,
    	in_buyer_org_id,
    	0,
        in_data_source_code,
        in_buyer_org_id,
        'No Information Available',
        'No Information Available',
        null,
        null,
        to_date('1/1/1999','MM/DD/YYYY'),
        null,
        'N',
        'N',
        'N',
        'N',
        'N',
        in_buyer_org_id,
        'Y',
        to_date('1/1/1999','MM/DD/YYYY'),
        in_msg_id,
        sysdate
        );
       
  EXCEPTION
   WHEN OTHERS THEN 
           ln_err  := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                        'Insert into create_null_pa_dims failed for null record creation',
                                                        SQLERRM,
                                                        'create_null_pa_dims');
   RAISE;                                                        
  END;             
end create_null_pa_dims;

/******************************************************************************
 * Name: create_null_date_dims
 * Desc: Procedure to insert dummay record 
 *******************************************************************************/

procedure create_null_date_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2)
as
ln_err number;
begin
  begin
   INSERT 
     INTO
     dm_date_dim
     (date_dim_id,
      top_parent_buyer_org_id,
      data_source_code,
      month_id,
      fiscal_month_id,
      last_update_date
     )
     values
     (-1*NVL(dm_cube_utils.get_top_parent_org_id(in_buyer_org_id),in_buyer_org_id),
      NVL(dm_cube_utils.get_top_parent_org_id(in_buyer_org_id),in_buyer_org_id),
       in_data_source_code,
       0,
       0,
       SYSDATE);  
  EXCEPTION
   WHEN OTHERS THEN 
           ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                        'Insert into dm_date_dim failed for null record creation',
                                                        SQLERRM,
                                                        'create_null_date_dims');
   RAISE;                                                        
  END;             
end create_null_date_dims;

/******************************************************************************
 * Name: create_null_job_dims
 * Desc: Procedure to insert dummay record 
 *******************************************************************************/
procedure create_null_job_dims(in_msg_id in number,in_buyer_org_id IN NUMBER,IN_DATA_SOURCE_CODE IN VARCHAR2)
as
ln_err number;
begin
  begin
   INSERT INTO dm_job_dim
     (job_dim_id,
      job_id,
      version_id,
      buyerorg_id,
      data_source_code,
      top_buyerorg_id,
      job_title,
      std_job_category_id,
      std_job_title_id,
      is_effective,
      valid_from_date,
      batch_id,
      last_update_date
      )
     values
     (-1*in_buyer_org_id,
      -1*in_buyer_org_id,
       in_buyer_org_id,
       in_buyer_org_id,
       in_data_source_code,
       NVL(dm_cube_utils.get_top_parent_org_id(in_buyer_org_id),in_buyer_org_id),
       'No Information Available',
       0,
       0,
       'Y',
       to_date('1/1/1999','MM/DD/YYYY'),
       0,
       SYSDATE);  
  EXCEPTION
   WHEN OTHERS THEN 
           ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                        'Insert into dm_job_dim failed for null record creation',
                                                        SQLERRM,
                                                        'create_null_job_dims');
   RAISE;                                                        
  END;             
end create_null_job_dims;

/******************************************************************************
 * Name:   dm_date_dim_process
 * Desc:   This procedure does the initial load as well as incremental load for date dimension.
 *         init_load_flag = 'Y' for initial load and init_load_flag = 'N' for incremental load.
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Sajeev  03/04/2011    Initial
 *******************************************************************************/
procedure dm_date_dim_process(in_top_buyer_org_id 	IN NUMBER,
						in_data_source_code 	IN VARCHAR2,
						init_load_flag 		IN VARCHAR2)
AS
ln_msg_id          NUMBER;
ln_count           NUMBER;
ln_err             NUMBER;
ln_data_source_id  NUMBER;

le_exception       EXCEPTION;

Cursor cur_buyer IS
     SELECT distinct org_id top_parent_buyer_org_id,data_source_code
		FROM dm_buyer_dim
	      WHERE is_effective = 'Y'
          	AND org_type = 'Buyer'
		AND top_parent_org_id = 0 ;

cursor cur_month IS
 select range_month_end from ( select x.range_month_end,x.row_level,ROW_NUMBER() OVER  ( ORDER BY COUNT(*)) month_order
             			from ( select level row_level,TRUNC(ADD_MONTHS('01-JAN-1999', +(level-1)), 'MONTH')+1 range_month_end
                     		       from dual
                  		       connect by level < (months_between(TRUNC(to_date('01-DEC-2016'),'MM'),'01-JAN-1999') + 2)
                    		       order by level asc) x
            			group by x.range_month_end,x.row_level
                 		order by x.row_level asc);
BEGIN
     --
     -- Get the sequence required for logging messages
     --

     BEGIN
       SELECT DM_MSG_LOG_SEQ.nextval
         INTO ln_msg_id
         FROM dual;
     END;

    IF ( init_load_flag = 'Y' ) THEN --Only for initial load

         select count(*)
	 into ln_count
         from dm_date_dim
         where top_parent_buyer_org_id =0
         and data_source_code = 'REGULAR'
         and date_dim_id != 0 ;

         IF ( ln_count > 0 ) THEN  --Initial Load is already done. Trying to run again.
           RAISE le_exception;
         END IF;

          --Seed data for top_buyer_org_id = 0

	  For c2 in cur_month
   	  Loop
   		INSERT INTO dm_date_dim
   		SELECT to_number(to_char(date_list,'YYYYMMDD')||'100'||'0') 							date_dim_id,
          		date_list  												day_dt,
                	0 													top_parent_buyer_org_id,
                	'REGULAR' 												data_source_code,
          		to_number(to_char(date_list,'D')) 									day_of_week,
          		to_number(to_char(date_list,'DD')) 									day_of_month,
          		to_number(to_char(date_list,'DDD')) 									day_of_year,
         		to_number(to_char(date_list,'J')) 									julian_day,
          		to_char(date_list,'DAY')          									day_name,
          		to_char(date_list,'DY')          									day_abbr,
          		to_number(to_char(date_list,'YYYYWW')||'1000')          							week_id,
                to_number(to_char(date_list,'YYYYWW'))          							week_id_disp,
          		to_number(to_char(date_list,'WW'))          								week_of_year,
           		to_number(to_char(date_list,'W'))          								week_of_month,
            		to_number(to_char(date_list,'YYYYMM')||'1000')   								month_id ,
                    to_number(to_char(date_list,'YYYYMM'))   								month_id_disp ,
            		to_number(to_char(date_list,'MM'))  									month_of_year  ,
            		to_char(date_list,'MONTH')           									month_name,
            		to_char(date_list,'MON')           									month_abbr,
            		(last_day(date_list)-trunc(date_list,'MM'))+1 								month_duration,
           		to_number(to_char(date_list,'YYYYQ')||'1000')          								quarter_id,
                to_number(to_char(date_list,'YYYYQ'))          								quarter_id_disp,
           		to_number(to_char(date_list,'Q'))          								quarter_nbr,
           		decode(to_number(to_char(date_list,'Q')),1,'First Quarter',2,'Second Quarter',3,'Third Quarter',4,'Fourth Quarter') quarter_name,
           		((add_months(trunc(sysdate,'Q'),3) - 1) - trunc(sysdate,'Q')) +1 					quarter_duration,
           		to_number(to_char(date_list,'YYYY')||'1000')          								year_id,
                to_number(to_char(date_list,'YYYY'))          								year_id_disp,
           		((add_months(trunc(sysdate,'YYYY'),12) - 1) - trunc(sysdate,'YYYY')) +1 				year_duration,
			to_number(to_char(date_list,'D')) 									fiscal_day_of_week,
          		to_number(to_char(date_list,'DD')) 									fiscal_day_of_month,
          		to_number(to_char(date_list,'DDD')) 									fiscal_day_of_year,
         		to_number(to_char(date_list,'YYYYWW')||'1000')          							fiscal_week_id,
                to_number(to_char(date_list,'YYYYWW'))          							fiscal_week_id_disp,
          		to_number(to_char(date_list,'WW'))          								fiscal_week_of_year,
           		to_number(to_char(date_list,'W'))          								fiscal_week_of_month,
            		to_number(to_char(date_list,'YYYYMM')||'1000')   								fiscal_month_id ,
                    to_number(to_char(date_list,'YYYYMM'))   								fiscal_month_id_disp ,
            		to_number(to_char(date_list,'MM'))  									fiscal_month_of_year  ,
            		to_char(date_list,'MONTH')           									fiscal_month_name,
            		to_char(date_list,'MON')           									fiscal_month_abbr,
            		(last_day(date_list)-trunc(date_list,'MM'))+1 								fiscal_month_duration,
           		to_number(to_char(date_list,'Q'))          								fiscal_quarter_nbr,
           		decode(to_number(to_char(date_list,'Q')),1,'First Quarter',2,'Second Quarter',3,'Third Quarter',4,'Fourth Quarter') fiscal_quarter_name,
           		((add_months(trunc(sysdate,'Q'),3) - 1) - trunc(sysdate,'Q')) +1 					fiscal_quarter_duration,
           		to_number(to_char(date_list,'YYYY')||'1000')          								fiscal_year_id,
                to_number(to_char(date_list,'YYYY'))          								fiscal_year_id_disp,
           		((add_months(trunc(sysdate,'YYYY'),12) - 1) - trunc(sysdate,'YYYY')) +1 				fiscal_year_duration,
           		to_number(to_char(date_list,'YYYYQ')||'1000')          								fiscal_quarter_id,
                to_number(to_char(date_list,'YYYYQ'))          								fiscal_quarter_id_disp,
                        sysdate												        last_update_date
   		FROM   ( select (trunc(c2.range_month_end,'MM'))-1 + rownum as 	date_list
  		 	from dual
  		 	where   (trunc(c2.range_month_end,'MM')-1+rownum) <= last_day(c2.range_month_end)
 		 	connect by level<=31 );
   	    End Loop;

            COMMIT;

            --Load for all buyers

     	    For c1 in cur_buyer
     	    Loop

                select NVL(data_source_id ,100)
		into ln_data_source_id
		from DM_DATA_SOURCE
		where data_source_code = c1.data_source_code;

 		INSERT INTO dm_date_dim
     			(date_dim_id,
      			top_parent_buyer_org_id,
      			data_source_code,
      			month_id,
      			fiscal_month_id,
      			last_update_date
    			)
     		values(-1*c1.top_parent_buyer_org_id,
      			c1.top_parent_buyer_org_id,
       			c1.data_source_code,
       			0,
       			0,
       			SYSDATE); 

                INSERT INTO dm_date_dim
   		SELECT to_number(to_char(a.day_dt,'YYYYMMDD')||ln_data_source_id||c1.top_parent_buyer_org_id)	date_dim_id,
          		a.day_dt,
                	c1.top_parent_buyer_org_id,
                	c1.data_source_code,
          		a.day_of_week,
          		a.day_of_month,
          		a.day_of_year,
         		a.julian_day,
          		a.day_name,
          		a.day_abbr,
          		to_number(substr(a.week_id_disp,3,2)||substr(a.week_id_disp,5)||c1.top_parent_buyer_org_id) week_id,
                a.week_id_disp,
          		a.week_of_year,
           		a.week_of_month,
            		to_number(substr(a.month_id_disp,3,2)||substr(a.month_id_disp,5)||c1.top_parent_buyer_org_id) month_id,
                    a.month_id_disp ,
            		a.month_of_year  ,
            		a.month_name,
            		a.month_abbr,
            		a.month_duration,
           		to_number(substr(a.quarter_id_disp,3,2)||substr(a.quarter_id_disp,5)||c1.top_parent_buyer_org_id) quarter_id,
                a.quarter_id_disp,
           		a.quarter_nbr,
           		a.quarter_name,
           		a.quarter_duration,
           		to_number(substr(a.year_id_disp,3,2)||substr(a.year_id_disp,5)||c1.top_parent_buyer_org_id) year_id,
                a.year_id_disp,
           		a.year_duration,
			a.fiscal_day_of_week,
          		a.fiscal_day_of_month,
          		a.fiscal_day_of_year,
         		to_number(substr(a.fiscal_week_id_disp,3,2)||substr(a.fiscal_week_id_disp,5) ||c1.top_parent_buyer_org_id) fiscal_week_id,
                a.fiscal_week_id_disp,
          		a.fiscal_week_of_year,
           		a.fiscal_week_of_month,
                to_number(substr(a.fiscal_month_id_disp,3,2)||substr(a.fiscal_month_id_disp,5) ||c1.top_parent_buyer_org_id) fiscal_month_id,
            		a.fiscal_month_id_disp ,
            		a.fiscal_month_of_year  ,
            		a.fiscal_month_name,
            		a.fiscal_month_abbr,
            		a.fiscal_month_duration,
           		a.fiscal_quarter_nbr,
           		a.fiscal_quarter_name,
           		a.fiscal_quarter_duration,
                to_number(substr(a.fiscal_year_id_disp,3,2)||substr(a.fiscal_year_id_disp,5) ||c1.top_parent_buyer_org_id) fiscal_year_id,
           		a.fiscal_year_id_disp,
           		a.fiscal_year_duration,
                to_number(substr(a.fiscal_quarter_id_disp,3,2)||substr(a.fiscal_quarter_id_disp,5) ||c1.top_parent_buyer_org_id) fiscal_quarter_id,
           		a.fiscal_quarter_id_disp,
                        sysdate	last_update_date
                FROM dm_date_dim a
		WHERE a.TOP_PARENT_BUYER_ORG_ID = 0
                AND a.DATA_SOURCE_CODE = 'REGULAR'
		and a.date_dim_id != 0;

             ---   AND NOT EXISTS ( select 'x' from dm_date_dim c where c.TOP_PARENT_BUYER_ORG_ID = c1.top_parent_buyer_org_id and c.DATA_SOURCE_CODE = c1.DATA_SOURCE_CODE);

                COMMIT;

  	    End Loop;

     ELSE --Incremental Loading. Being called from Buyer Dim process.

        	select NVL(data_source_id ,100)
		into ln_data_source_id
		from DM_DATA_SOURCE
		where data_source_code = in_data_source_code;

                --Dummy Record for new buyer org.

		/************************
           INSERT INTO dm_date_dim
     			(date_dim_id,
      			top_parent_buyer_org_id,
      			data_source_code,
      			month_id,
      			fiscal_month_id,
      			last_update_date
    			)
     		values(-1*in_top_buyer_org_id,
      			in_top_buyer_org_id,
       			in_data_source_code,
       			0,
       			0,
       			SYSDATE); 
           ****************************/

     		INSERT INTO dm_date_dim
   		SELECT to_number(to_char(a.day_dt,'YYYYMMDD')||ln_data_source_id||in_top_buyer_org_id)	date_dim_id,
          		a.day_dt,
                	in_top_buyer_org_id,
                	in_data_source_code,
          		a.day_of_week,
          		a.day_of_month,
          		a.day_of_year,
         		a.julian_day,
          		a.day_name,
          		a.day_abbr,
                to_number(substr(a.week_id_disp,3,2)||substr(a.week_id_disp,5)||in_top_buyer_org_id) week_id,
          		a.week_id_disp,
          		a.week_of_year,
           		a.week_of_month,
                to_number(substr(a.month_id_disp,3,2)||substr(a.month_id_disp,5)||in_top_buyer_org_id) month_id,
            		a.month_id_disp ,
            		a.month_of_year  ,
            		a.month_name,
            		a.month_abbr,
            		a.month_duration,
                    to_number(substr(a.quarter_id_disp,3,2)||substr(a.quarter_id_disp,5) ||in_top_buyer_org_id) quarter_id,
           		a.quarter_id_disp,
           		a.quarter_nbr,
           		a.quarter_name,
           		a.quarter_duration,
                to_number(substr(a.year_id_disp,3,2)||substr(a.year_id_disp,5) ||in_top_buyer_org_id) year_id,
           		a.year_id_disp,
           		a.year_duration,
			a.fiscal_day_of_week,
          		a.fiscal_day_of_month,
          		a.fiscal_day_of_year,
                to_number(substr(a.fiscal_week_id_disp,3,2)||substr(a.fiscal_week_id_disp,5) ||in_top_buyer_org_id) fiscal_week_id,
         		a.fiscal_week_id_disp,
          		a.fiscal_week_of_year,
           		a.fiscal_week_of_month,
                to_number(substr(a.fiscal_month_id_disp,3,2)||substr(a.fiscal_month_id_disp,5) ||in_top_buyer_org_id) fiscal_month_id,
            		a.fiscal_month_id_disp ,
            		a.fiscal_month_of_year  ,
            		a.fiscal_month_name,
            		a.fiscal_month_abbr,
            		a.fiscal_month_duration,
           		a.fiscal_quarter_nbr,
           		a.fiscal_quarter_name,
           		a.fiscal_quarter_duration,
                to_number(substr(a.fiscal_year_id_disp,3,2)||substr(a.fiscal_year_id_disp,5) ||in_top_buyer_org_id) fiscal_year_id,
           		a.fiscal_year_id_disp,
           		a.fiscal_year_duration,
                to_number(substr(a.fiscal_quarter_id_disp,3,2)||substr(a.fiscal_quarter_id_disp,5) ||in_top_buyer_org_id) fiscal_quarter_id,
           		a.fiscal_quarter_id_disp,
                        sysdate	last_update_date
                 FROM dm_date_dim a
		WHERE a.TOP_PARENT_BUYER_ORG_ID = 0
                AND a.DATA_SOURCE_CODE = 'REGULAR'
		and a.date_dim_id != 0 ;

             --   AND NOT EXISTS ( select 'x' from dm_date_dim c where c.TOP_PARENT_BUYER_ORG_ID = in_top_buyer_org_id and c.DATA_SOURCE_CODE = in_data_source_code);
     END IF;

     COMMIT;

     Exception
	   WHEN le_exception THEN
		ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                      'Trying to do initial load dm_date_dim while there are already some data exist!',
                                      'Err:'||SQLERRM,
                                      'dm_date_dim_process');
   	   WHEN Others THEN
    		ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                      'Errors occured in the procedure while populating the dm_date_dim!',
                                      'Err:'||SQLERRM,
                                      'dm_date_dim_process');
    END dm_date_dim_process;

--Procedure to update fiscal calender.

procedure dm_fiscal_calendar_update 
AS
v_low_date 	DATE;
v_high_date 	DATE;
ld_date date;
Cursor Cur IS select distinct TOP_PARENT_BUYER_ORG_ID from DM_DATE_DIM_STAG;

BEGIN
ld_date := sysdate;
FOR c1 in Cur
Loop
        v_low_date  := NULL;
        v_high_date := NULL;

	select min(DAY_DT),max(DAY_DT) 
	into v_low_date,v_high_date
	from DM_DATE_DIM_STAG 
        where TOP_PARENT_BUYER_ORG_ID = c1.TOP_PARENT_BUYER_ORG_ID ;

  UPDATE DM_DATE_DIM a
  SET (	FISCAL_DAY_OF_WEEK,
    	FISCAL_DAY_OF_MONTH,
       	FISCAL_DAY_OF_YEAR,
        FISCAL_WEEK_ID,
        FISCAL_WEEK_ID_DISP,
       	FISCAL_WEEK_OF_YEAR,
       	FISCAL_WEEK_OF_MONTH,
       	FISCAL_MONTH_ID,
       	FISCAL_MONTH_ID_DISP,
       	FISCAL_MONTH_OF_YEAR,
       	FISCAL_MONTH_NAME,
       	FISCAL_MONTH_ABBR,
       	FISCAL_MONTH_DURATION,
       	FISCAL_QUARTER_ID,
       	FISCAL_QUARTER_ID_DISP, 
       	FISCAL_QUARTER_NBR,
       	FISCAL_QUARTER_NAME,
       	FISCAL_QUARTER_DURATION,
       	FISCAL_YEAR_ID,
       	FISCAL_YEAR_ID_DISP,
       	FISCAL_YEAR_DURATION,
        last_update_date) = ( select distinct b.DAY_OF_WEEK FISCAL_DAY_OF_WEEK,
                                       DAY_OF_MONTH FISCAL_DAY_OF_MONTH,
                                       DAY_OF_YEAR FISCAL_DAY_OF_YEAR,
                                       to_number(substr(to_char(week_id),3))||c1.TOP_PARENT_BUYER_ORG_ID FISCAL_WEEK_ID,
                                       WEEK_ID FISCAL_WEEK_ID_DISP,
                                       WEEK_OF_YEAR FISCAL_WEEK_OF_YEAR,
                                       WEEK_OF_MONTH FISCAL_WEEK_OF_MONTH,
                                       to_number(substr(to_char(MONTH_ID),3))||c1.TOP_PARENT_BUYER_ORG_ID FISCAL_MONTH_ID,
                                       MONTH_ID FISCAL_MONTH_ID_DISP,
                                       MONTH_OF_YEAR FISCAL_MONTH_OF_YEAR,
                                       MONTH_NAME FISCAL_MONTH_NAME,
                                       MONTH_ABBR FISCAL_MONTH_ABBR,
                                       MONTH_DURATION FISCAL_MONTH_DURATION,
                                       to_number(substr(to_char(QUARTER_ID),3,2))||to_number(substr(to_char(QUARTER_ID),5,2))||c1.TOP_PARENT_BUYER_ORG_ID FISCAL_QUARTER_ID,
                                       to_number(substr(to_char(QUARTER_ID),1,4))||to_number(substr(to_char(QUARTER_ID),5,2)) FISCAL_QUARTER_ID_DISP,
                                       QUARTER_NBR FISCAL_QUARTER_NBR,
                                       QUARTER_NAME FISCAL_QUARTER_NAME,
                                       QUARTER_DURATION FISCAL_QUARTER_DURATION,
                                       to_number(substr(to_char(YEAR_ID),3))||c1.TOP_PARENT_BUYER_ORG_ID FISCAL_YEAR_ID,
                                       YEAR_ID FISCAL_YEAR_ID_DISP,
                                       YEAR_DURATION FISCAL_YEAR_DURATION,
                                       ld_date
        FROM DM_DATE_DIM_STAG b where a.DAY_DT  = b.DAY_DT 
	AND a.TOP_PARENT_BUYER_ORG_ID = b.TOP_PARENT_BUYER_ORG_ID
        AND b.TOP_PARENT_BUYER_ORG_ID = c1.TOP_PARENT_BUYER_ORG_ID )     
   WHERE a.TOP_PARENT_BUYER_ORG_ID = c1.TOP_PARENT_BUYER_ORG_ID
   AND  a.DAY_DT >= v_low_date
   AND  a.DAY_DT <= v_high_date;

--dbms_output.put_line(to_char(sql%rowcount));

End Loop;

insert into dm_date_load_log select distinct TOP_PARENT_BUYER_ORG_ID,sysdate from DM_DATE_DIM  where FISCAL_DAY_OF_WEEK is not null and trunc(last_update_date) = TRUNC(LD_DATE);

COMMIT;

EXECUTE IMMEDIATE 'TRUNCATE TABLE DM_DATE_DIM_STAG' ;

end dm_fiscal_calendar_update;

FUNCTION GET_BUSINESS_DAYS(V_START_DATE IN DATE, V_END_DATE IN DATE)
RETURN NUMBER IS
 DAY_COUNT NUMBER:= 0;
 CURR_DATE DATE;
 OUT_DAYS  NUMBER := 0;
BEGIN  
 CURR_DATE := V_START_DATE;
 
 IF ( V_START_DATE <= V_END_DATE ) THEN
        WHILE CURR_DATE <= V_END_DATE
        LOOP
            IF TO_CHAR(CURR_DATE,'DY') NOT IN ('SAT','SUN')
                THEN DAY_COUNT := DAY_COUNT + 1;
            END IF;
            CURR_DATE := CURR_DATE + (1/24);
         END LOOP;
         
         IF ( DAY_COUNT = 0 ) THEN
              OUT_DAYS := 0;
         ELSE
              OUT_DAYS := (DAY_COUNT-1)/24;
         END IF;
 ELSIF ( V_START_DATE > V_END_DATE ) THEN
         WHILE CURR_DATE > V_END_DATE
            LOOP
                 IF TO_CHAR(CURR_DATE,'DY') NOT IN ('SAT','SUN')
                        THEN DAY_COUNT := DAY_COUNT - 1;
                 END IF;
                CURR_DATE := CURR_DATE - (1/24);
            END LOOP;
 
            OUT_DAYS := (DAY_COUNT)/24;
 ELSE
           OUT_DAYS := NULL;
 END IF;

          RETURN OUT_DAYS;
END GET_BUSINESS_DAYS;

FUNCTION get_job_status(in_what IN VARCHAR2) RETURN NUMBER 
IS
v_count NUMBER := 0;
BEGIN
 SELECT MAX(CASE WHEN THIS_DATE IS NOT NULL THEN 1 ELSE 0 END) 
           INTO v_count
           FROM user_jobs dj 
          WHERE dj.log_user = USER
            AND upper(dj.what)   = UPPER(in_what);

 RETURN v_count;

EXCEPTION
  WHEN OTHERS THEN
     RETURN 0;
END get_job_status;

FUNCTION get_currency_code( in_currency_dim_id in number) RETURN VARCHAR2
IS
  v_currency_code varchar2(10);
Begin
    select currency_code 
    into v_currency_code
    from dm_currency_dim 
    where currency_dim_id = in_currency_dim_id;
     
    RETURN v_currency_code;
    
    EXCEPTION 
      WHEN No_Data_Found THEN
          RETURN 'USD';
End get_currency_code; 

FUNCTION get_converted_rate ( v_curr_conv_dim_id in number) RETURN NUMBER deterministic
IS
	v_converted_rate NUMBER(38,7) := 1;
Begin
  select CONVERSION_RATE
  into v_converted_rate
  from dm_currency_conversion_rates
  where curr_conv_dim_id = v_curr_conv_dim_id ;
  
  RETURN v_converted_rate;
  
  Exception
    When No_Data_Found THEN
       RETURN 1;
End get_converted_rate;

FUNCTION  get_curr_conv_dim_id(in_currency_dim_id in number,to_curr in varchar2,exp_date in date) RETURN NUMBER
IS
    v_curr_conv_dim_id NUMBER := 1;
Begin
 Begin
  select curr_conv_dim_id
  into v_curr_conv_dim_id
  from dm_currency_conversion_rates r,dm_currency_dim c
  where r.FROM_CURRENCY_CODE = c.currency_code
  and r.TO_CURRENCY_CODE = to_curr
  and r.CONVERSION_DATE = TRUNC(exp_date)
  and c.currency_dim_id = in_currency_dim_id ;
  
  EXCEPTION
   When No_Data_Found THEN
      Begin    
      	IF ( in_currency_dim_id = DM_CUBE_UTILS.get_currency_dim_id(to_curr)) THEN  -- 2,3 or 4 for USD,EUR and GBP
        		select MIN(curr_conv_dim_id) 
        		into v_curr_conv_dim_id
        		from dm_currency_conversion_rates r,dm_currency_dim c
        		where r.FROM_CURRENCY_CODE = c.currency_code
        		and r.TO_CURRENCY_CODE = to_curr
        		and c.currency_dim_id = in_currency_dim_id;
      	ELSE --If there is no record exists for a given day, it returns the last conv rate prior to this date.
        		/* select MAX(curr_conv_dim_id)
  			into v_curr_conv_dim_id
  			from dm_currency_conversion_rates r,dm_currency_dim c
  			where r.FROM_CURRENCY_CODE = c.currency_code
  			and r.TO_CURRENCY_CODE = to_curr
  			and r.CONVERSION_DATE <= TRUNC(exp_date)
  			and c.currency_dim_id = in_currency_dim_id ; */

			v_curr_conv_dim_id := 1;

      	END IF;
             
        Exception
         When Others THEN
           v_curr_conv_dim_id := 1;
      End;
   When Others THEN
         v_curr_conv_dim_id := 1;
 END;
   
 RETURN NVL(v_curr_conv_dim_id,1); 
End get_curr_conv_dim_id;

 PROCEDURE make_indexes_visible
 IS
 BEGIN
       EXECUTE IMMEDIATE 'ALTER SESSION SET optimizer_use_invisible_indexes = true';
 END make_indexes_visible;

 PROCEDURE make_indexes_invisible
 IS
     CURSOR idx_cur IS
            SELECT 'ALTER INDEX ' || index_name || ' INVISIBLE' AS sql_to_run
              FROM user_indexes
             WHERE visibility = 'VISIBLE'
               AND (   table_name LIKE 'DM_%_DIM'
                    OR table_name LIKE '%_FACT%'
                    OR table_name IN ('DM_CURRENCY_CONVERSION_RATES', 'DM_BUYER_SUPPLIER_AGMT', 'DM_BUS_ORG_LINEAGE')
                   );
 BEGIN
     FOR idx_rec IN idx_cur
     LOOP
          EXECUTE IMMEDIATE idx_rec.sql_to_run;
     END LOOP;
 END make_indexes_invisible;
END dm_cube_utils;
/