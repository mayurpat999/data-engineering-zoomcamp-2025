Homework Solutions for Module 3:


 Q1. Understanding dbt model resolution

The dataset myproject is loaded as the DBT_BIGQUERY_PROJECT because it is 
explicitly set when dbt runs. However, the schema is determined by the 
DBT_BIGQUERY_SOURCE_DATASET environment variable. Since DBT_BIGQUERY_SOURCE_DATASET 
was not set and DBT_BIGQUERY_DATASET=my_nyc_tripdata was exported instead, 
dbt defaults to using raw_nyc_tripdata as the schema.

Answer: select * from myproject.raw_nyc_tripdata.ext_green_taxi



 Q2. dbt Variables & Dynamic Models

Set the env_var to be the default value of the command line value, and '30' to be the
default value of the env_var.
This way, if the command line value is not set, the env_value is loaded instead. If nothing
is explicitly declared, 30 days are going to be processed by default.

Answer: Update the WHERE clause to pickup_datetime >= CURRENT_DATE - 
                INTERVAL '{{ var("days_back", env_var("DAYS_BACK", "30")) }}' DAY

 Q3. dbt Data Lineage and Execution

dbt run --select models/staging/+ would only materialize themselves, since dim_taxi_trips 
also depends on dim_zone_lookup, as a result fct_taxi_monthly_zone_revenue would also 
not be build.

Answer: dbt run --select models/staging/+

 Q4. dbt Macros and Jinja

Answer: 

    - Setting a value for DBT_BIGQUERY_TARGET_DATASET env var is mandatory, or it'll fail to compile.
    - When using core, it materializes in the dataset defined in DBT_BIGQUERY_TARGET_DATASET
    - When using stg, it materializes in the dataset defined in DBT_BIGQUERY_STAGING_DATASET, or defaults to DBT_BIGQUERY_TARGET_DATASET
    - When using staging, it materializes in the dataset defined in DBT_BIGQUERY_STAGING_DATASET, or defaults to DBT_BIGQUERY_TARGET_DATASET

 Q5. Taxi Quarterly Revenue Growth

Answer: green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q1, worst: 2020/Q2}

 Q6. P97/P95/P90 Taxi Monthly Fare

Answer: green: {p97: 40.0, p95: 33.0, p90: 24.5}, yellow: {p97: 31.5, p95: 25.5, p90: 19.0}

 Q7. Top #Nth longest P90 travel time Location for FHV

Answer: LaGuardia Airport, Park Slope, Clinton East
