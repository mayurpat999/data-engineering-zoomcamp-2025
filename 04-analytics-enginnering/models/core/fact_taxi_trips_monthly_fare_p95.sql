{{
    config(
        materialized='table'
    )
}}

with filtered_trips as (
    select year, month, fare_amount, service_type
    from {{ ref('fact_trips') }}
    WHERE fare_amount > 0
    AND trip_distance > 0
    AND payment_type_description IN ('Cash', 'Credit Card')
    AND year = 2020 AND month=4 AND service_type = 'Green'
) SELECT year, month, fare_amount,
    PERCENTILE_CONT(fare_amount, 0.97) OVER (PARTITION BY service_type, year, month) AS p97,
    PERCENTILE_CONT(fare_amount, 0.95) OVER (PARTITION BY service_type, year, month) AS p95,
    PERCENTILE_CONT(fare_amount, 0.90) OVER (PARTITION BY service_type, year, month) AS p90
    FROM filtered_trips
    