-- models/analytics/agg_service_summary.sql

{{ config(
    materialized='table',
    partition_by={
      "field": "year",
      "data_type": "int64",
      "range": {
        "start": 2015,
        "end": 2030,
        "interval": 1
      }
    },
    cluster_by=["hcpcs_code"] -- Cluster only by the HCPCS code
) }}

-- The actual SELECT statement to build the table content
SELECT
    hcpcs_code,
    -- Use any_value (or MAX/MIN if deterministic is needed) for description
    -- as it should be the same for a given code within a year
    ANY_VALUE(hcpcs_description) AS hcpcs_description,
    year, -- Ensure 'year' column is present from the staging model
    SUM(line_srvc_cnt) AS total_times_rendered,
    -- Using AVG here, could also calculate weighted average if needed
    AVG(avg_medicare_allowed_amt) AS avg_allowed_amount
FROM {{ ref('stg_medicare_physicians_suppliers') }} -- Reference the staging model
WHERE hcpcs_code IS NOT NULL -- Ensure we only aggregate valid codes
GROUP BY
    hcpcs_code,
    year