# iam.tf

# 1. Service Account for DBT Execution
resource "google_service_account" "dbt_runner_sa" {
  project      = var.gcp_project_id
  account_id   = "dbt-runner-sa"
  display_name = "Service Account for dbt execution"
}

# Grant dbt SA permissions on BigQuery Datasets
resource "google_bigquery_dataset_iam_member" "dbt_runner_staging_editor" {
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.staging.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt_runner_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_runner_analytics_editor" {
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt_runner_sa.email}"
}

# Grant dbt SA permission to run BigQuery Jobs in the project
resource "google_project_iam_member" "dbt_runner_bq_job_user" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt_runner_sa.email}"
}


# 2. Service Account for Power BI Connection
resource "google_service_account" "powerbi_reader_sa" {
  project      = var.gcp_project_id
  account_id   = "powerbi-reader-sa"
  display_name = "Service Account for Power BI reading BQ Analytics"
}

# Grant Power BI SA read-only access to the Analytics dataset
resource "google_bigquery_dataset_iam_member" "powerbi_reader_analytics_viewer" {
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = "roles/bigquery.dataViewer" # Read-only access
  member     = "serviceAccount:${google_service_account.powerbi_reader_sa.email}"
}

# Grant Power BI SA permission to run BigQuery Jobs (needed for reading)
resource "google_project_iam_member" "powerbi_reader_bq_job_user" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.powerbi_reader_sa.email}"
}


# 3. Grant Composer's *default* Service Account necessary roles
# Note: Composer creates its own main service account. We grant permissions TO it.
# The format is typically service-<project_number>@cloudcomposer-accounts.iam.gserviceaccount.com
# We use a data source to find the project number.

data "google_project" "project" {
  project_id = var.gcp_project_id
}

# Permissions for the Composer Service Account Agent (manages Composer resources)
# Usually Composer adds this automatically, but being explicit can help troubleshoot.
resource "google_project_iam_member" "composer_agent_service_agent" {
  project = var.gcp_project_id
  role    = "roles/composer.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

# Grant Composer Worker SA (created by Composer resource later) permissions
# We grant these at the project level for simplicity, but dataset/bucket level is more secure.
# NOTE: These roles are granted to the SA that Composer *creates*, identified AFTER creation.
# We reference it via the composer resource output in main.tf (see composer resource 'service_account')

resource "google_project_iam_member" "composer_worker_bq_editor" {
  # Allows Composer DAGs to read/write staging and analytics tables
  project = var.gcp_project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_composer_environment.medicare_dag_orchestrator.config[0].workloads_config[0].scheduler[0].service_account_email}"
  # Ensure this runs after Composer environment is created
  depends_on = [google_composer_environment.medicare_dag_orchestrator]
}

resource "google_project_iam_member" "composer_worker_bq_job_user" {
  # Allows Composer DAGs to run BigQuery jobs
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_composer_environment.medicare_dag_orchestrator.config[0].workloads_config[0].scheduler[0].service_account_email}"
  depends_on = [google_composer_environment.medicare_dag_orchestrator]
}

resource "google_project_iam_member" "composer_worker_gcs_object_admin" {
  # Allows Composer to read DAGs from, and write logs to, its GCS bucket
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_composer_environment.medicare_dag_orchestrator.config[0].workloads_config[0].scheduler[0].service_account_email}"
  depends_on = [google_composer_environment.medicare_dag_orchestrator]
}

# Optional: If Composer needs to impersonate the dbt SA to run dbt jobs
# resource "google_service_account_iam_member" "composer_can_impersonate_dbt" {
#   service_account_id = google_service_account.dbt_runner_sa.name
#   role               = "roles/iam.serviceAccountTokenCreator"
#   member             = "serviceAccount:${google_composer_environment.medicare_dag_orchestrator.config[0].workloads_config[0].scheduler[0].service_account_email}"
#   depends_on = [google_composer_environment.medicare_dag_orchestrator]
# }