{{
    config(
        materialized='table'
    )
}}

with quarterly_revenue as (
    SELECT 
    service_type, 
    year, 
    quarter,
    SUM(total_amount) AS revenue
    FROM {{ ref('fact_trips') }}
    WHERE total_amount >0 AND year=2020
    GROUP BY service_type, year, quarter)
SELECT * FROM quarterly_revenue
order by revenue desc

    