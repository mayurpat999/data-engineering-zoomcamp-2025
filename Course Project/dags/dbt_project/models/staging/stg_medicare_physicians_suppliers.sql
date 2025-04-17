-- dbt_project/models/staging/stg_medicare_physicians_suppliers.sql

-- Configuration: Specify the target schema (optional if set in dbt_project.yml)
-- {{ config(schema='medicare_staging') }} -- Can override project default if needed

WITH source_data AS (
    -- Select from the specific year's staging table created by Airflow
    -- The table name uses the 'target_year' variable passed from Airflow/dbt_project.yml
    SELECT *
    FROM {{ source('medicare_staging_source', var('medicare_staging_table')) }}
    -- Note: We define 'medicare_staging_source' in schema.yml below
)
SELECT
    -- Identifiers & Provider Info
    CAST(npi AS STRING) AS npi,
    nppes_provider_last_org_name,
    nppes_provider_first_name,
    nppes_entity_code,
    nppes_provider_gender,
    nppes_provider_city,
    nppes_provider_state AS provider_state, -- Renamed for clarity
    nppes_provider_country,
    provider_type,
    medicare_participation_indicator,
    place_of_service,

    -- Service Info
    CAST(hcpcs_code AS STRING) AS hcpcs_code,
    hcpcs_description,
    hcpcs_drug_indicator,

    -- Metrics (using SAFE_CAST to avoid errors on bad data, returns NULL instead)
    SAFE_CAST(line_srvc_cnt AS NUMERIC) AS line_srvc_cnt,
    SAFE_CAST(bene_unique_cnt AS NUMERIC) AS bene_unique_cnt,
    SAFE_CAST(bene_day_srvc_cnt AS NUMERIC) AS bene_day_srvc_cnt,
    SAFE_CAST(average_medicare_allowed_amt AS NUMERIC) AS avg_medicare_allowed_amt, -- Renamed
    SAFE_CAST(average_submitted_chrg_amt AS NUMERIC) AS avg_submitted_chrg_amt, -- Renamed
    SAFE_CAST(average_medicare_payment_amt AS NUMERIC) AS avg_medicare_payment_amt, -- Renamed
    SAFE_CAST(average_medicare_standardized_amt AS NUMERIC) AS avg_medicare_standardized_amt, -- Renamed

    -- Add the processing year (useful for partitioning/analysis)
    CAST({{ var('target_year') }} AS INT64) AS year

FROM source_data
WHERE
    npi IS NOT NULL
    AND provider_state IS NOT NULL -- Added filter based on analytics needs
    AND hcpcs_code IS NOT NULL   -- Added filter based on analytics needs
    AND SAFE_CAST(line_srvc_cnt AS NUMERIC) > 0 -- Ensure service was actually provided
