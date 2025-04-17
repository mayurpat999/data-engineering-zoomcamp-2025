-- models/analytics/agg_provider_type_by_state.sql

{{ config(
    materialized='table',  -- Create this as a standard table
    partition_by={        -- Define partitioning configuration
      "field": "year",          -- Partition by the 'year' column
      "data_type": "int64",     -- Data type of the partitioning column
      "range": {                -- Specify integer range partitioning
        "start": 2015,          -- Start of the range (adjust as needed)
        "end": 2030,            -- End of the range (adjust as needed)
        "interval": 1           -- Interval (1 year)
      }
    },
    cluster_by=["provider_state", "provider_type"] -- Define clustering columns
) }}

-- The actual SELECT statement to build the table content
SELECT
    provider_state,
    provider_type,
    year, -- Ensure 'year' column is present from the staging model
    COUNT(DISTINCT npi) AS distinct_provider_count,
    SUM(line_srvc_cnt) AS total_services_rendered
FROM {{ ref('stg_medicare_physicians_suppliers') }} -- Reference the staging model
GROUP BY
    provider_state,
    provider_type,
    year
