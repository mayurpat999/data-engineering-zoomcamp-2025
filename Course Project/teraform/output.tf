# outputs.tf

output "composer_environment_name" {
  description = "The name of the Cloud Composer environment."
  value       = google_composer_environment.medicare_dag_orchestrator.name
}

output "composer_airflow_uri" {
  description = "The URI for the Airflow UI."
  value       = google_composer_environment.medicare_dag_orchestrator.config[0].airflow_uri
}

output "composer_gcs_bucket" {
  description = "The GCS bucket created by Composer for DAGs and logs."
  value       = google_composer_environment.medicare_dag_orchestrator.config[0].dag_gcs_prefix
}

output "artifacts_gcs_bucket_name" {
  description = "Name of the GCS bucket for general artifacts."
  value       = google_storage_bucket.data_pipeline_artifacts.name
}

output "bigquery_staging_dataset_id" {
  description = "ID of the BigQuery Staging Dataset."
  value       = google_bigquery_dataset.staging.dataset_id
}

output "bigquery_analytics_dataset_id" {
  description = "ID of the BigQuery Analytics Dataset."
  value       = google_bigquery_dataset.analytics.dataset_id
}

output "dbt_runner_service_account_email" {
  description = "Email of the Service Account for dbt execution."
  value       = google_service_account.dbt_runner_sa.email
}

output "powerbi_reader_service_account_email" {
  description = "Email of the Service Account for Power BI connection."
  value       = google_service_account.powerbi_reader_sa.email
}

output "composer_worker_service_account_email" {
  description = "Email of the Service Account used by Composer workers (created by Composer)."
  value       = google_composer_environment.medicare_dag_orchestrator.config[0].workloads_config[0].scheduler[0].service_account_email # Adjust index if needed based on TF provider version
}