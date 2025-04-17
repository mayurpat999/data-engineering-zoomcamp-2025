import os
from datetime import datetime, timedelta
from airflow.models import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryExecuteQueryOperator
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator # Use EmptyOperator (new name for DummyOperator)

# --- Configuration Variables ---
# Should match terraform outputs/variables
GCP_PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "your-gcp-project-id") # Replace fallback with your project ID
GCP_REGION = os.environ.get("GCP_REGION", "us-central1")
BQ_STAGING_DATASET = os.environ.get("BQ_STAGING_DATASET", "medicare_staging")
BQ_ANALYTICS_DATASET = os.environ.get("BQ_ANALYTICS_DATASET", "medicare_analytics")

# dbt specific paths - Adjust if your dbt project/profiles are elsewhere
DBT_PROJECT_DIR = "/home/airflow/gcs/dags/dbt_project" # Default GCS sync path
DBT_PROFILES_DIR = "/home/airflow/gcs/dags/profiles" # Location of profiles.yml

# Medicare Data Parameters
MEDICARE_SOURCE_PROJECT = "bigquery-public-data"
MEDICARE_SOURCE_DATASET = "medicare"
# Make the year dynamic, e.g., process previous year's data
# Using Airflow's logical date (execution_date) - for a run on 2024-01-01, this would be 2023
TARGET_YEAR = "{{ (execution_date - macros.timedelta(days=1)).strftime('%Y') }}"
MEDICARE_SOURCE_TABLE = f"physicians_and_other_suppliers_{TARGET_YEAR}"
STAGING_TABLE_NAME = f"stg_physicians_suppliers_{TARGET_YEAR}"

# --- DAG Definition ---
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False, 
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "start_date": datetime(2023, 1, 1), # Adjust start date as needed
}
# Instantiate the DAG:
with DAG(
    dag_id="medicare_analytics_pipeline",
    default_args=default_args,
    description="Pipeline to process Medicare data using BigQuery and dbt",
    schedule_interval="@yearly", # Run once a year, e.g., early Jan for previous year
    catchup=False, # Don't run for past missed schedules
    tags=['gcp', 'bigquery', 'dbt', 'medicare'],
    # Pass project/dataset info to tasks via Jinja templating if needed elsewhere
    user_defined_macros={
        'gcp_project_id': GCP_PROJECT_ID,
        'bq_staging_dataset': BQ_STAGING_DATASET,
        'bq_analytics_dataset': BQ_ANALYTICS_DATASET,
    },
    # Set environment variables for the dbt run command to pick up
    template_searchpath=['/home/airflow/gcs/dags'], # Allows including SQL from files if needed
    render_template_as_native_obj=True, # Allows using Jinja directly in params like BQ Operator's 'variables'

) as dag:
    start_pipeline = EmptyOperator(
    task_id="start_pipeline"
)
    sql_create_staging = f"""
CREATE OR REPLACE TABLE `{GCP_PROJECT_ID}.{BQ_STAGING_DATASET}.{STAGING_TABLE_NAME}`
OPTIONS(
    description="Staging table for Medicare Physicians and Other Suppliers data year {TARGET_YEAR}"
    -- You could add partitioning/clustering here if the staging table is very large
    -- and downstream dbt models benefit, but often staging is transient.
)
AS SELECT
    npi, -- National Provider Identifier
    nppes_provider_last_org_name,
    nppes_provider_first_name,
    nppes_entity_code, -- I or O (Individual or Organization)
    nppes_provider_gender,
    nppes_provider_city,
    nppes_provider_state,
    nppes_provider_country,
    provider_type,
    medicare_participation_indicator, -- Y/N
    place_of_service, -- F (Facility) or O (Office)
    hcpcs_code, -- Healthcare Common Procedure Coding System
    hcpcs_description,
    hcpcs_drug_indicator, -- Y/N
    line_srvc_cnt, -- Number of services rendered
    bene_unique_cnt, -- Number of unique beneficiaries
    bene_day_srvc_cnt, -- Number of distinct Medicare beneficiary/per day services
    average_medicare_allowed_amt,
    average_submitted_chrg_amt,
    average_medicare_payment_amt,
    average_medicare_standardized_amt
FROM
    `{MEDICARE_SOURCE_PROJECT}.{MEDICARE_SOURCE_DATASET}.{MEDICARE_SOURCE_TABLE}`
WHERE
    npi IS NOT NULL AND hcpcs_code IS NOT NULL
    AND line_srvc_cnt > 0; -- Basic filter example
"""

create_staging_table = BigQueryExecuteQueryOperator(
    task_id="create_staging_table",
    sql=sql_create_staging,
    use_legacy_sql=False,
    location=GCP_REGION,
    gcp_conn_id="google_cloud_default", # Standard connection ID in Composer
    # These dispositions ensure the table is created if missing and overwritten if exists
    write_disposition="WRITE_TRUNCATE",
    create_disposition="CREATE_IF_NEEDED",
)

# Define environment variables needed by profiles.yml
dbt_env_vars = {
    'GCP_PROJECT_ID': GCP_PROJECT_ID,
    'BQ_ANALYTICS_DATASET': BQ_ANALYTICS_DATASET,
    'BQ_STAGING_DATASET': BQ_STAGING_DATASET, # Pass staging dataset too if dbt needs it
    'GCP_REGION': GCP_REGION,
    'DBT_TARGET_YEAR': TARGET_YEAR # Pass year to dbt if models need it
}

# Note: The dbt command assumes:
# 1. dbt-bigquery is installed in the Composer environment (added via Terraform).
# 2. The dbt project exists at DBT_PROJECT_DIR.
# 3. The profiles.yml file exists at DBT_PROFILES_DIR.
# 4. The Composer worker service account has necessary BQ permissions.
run_dbt_transformations = BashOperator(
    task_id="run_dbt_transformations",
    bash_command=(
        f"cd {DBT_PROJECT_DIR} && "
        f"dbt run --profiles-dir {DBT_PROFILES_DIR} --target prod --vars '{{target_year: {TARGET_YEAR}}}'" # Pass year as dbt variable
        # Add other dbt commands if needed: e.g., dbt test
        # f" && dbt test --profiles-dir {DBT_PROFILES_DIR} --target prod"
    ),
    env=dbt_env_vars, # Make variables available to the bash environment & dbt profile
    append_env=True, # Append to existing Composer env vars
)

end_pipeline = EmptyOperator(
    task_id="end_pipeline"
)
start_pipeline >> create_staging_table >> run_dbt_transformations >> end_pipeline
