# variables.tf

variable "gcp_project_id" {
  description = "The GCP Project ID to deploy resources into."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources into (e.g., 'us-central1')."
  type        = string
  default     = "us-central1"
}

variable "gcs_bucket_name_suffix" {
  description = "Suffix for the GCS bucket name (will be prepended with project ID)."
  type        = string
  default     = "medicare-data-pipeline"
}

variable "bq_staging_dataset_id" {
  description = "BigQuery dataset ID for staging data."
  type        = string
  default     = "medicare_staging"
}

variable "bq_analytics_dataset_id" {
  description = "BigQuery dataset ID for analytics-ready data."
  type        = string
  default     = "medicare_analytics"
}

variable "composer_env_name" {
  description = "Name for the Cloud Composer environment."
  type        = string
  default     = "medicare-pipeline-orchestrator"
}

variable "composer_image_version" {
  description = "Composer image version (e.g., composer-2.1.11-airflow-2.5.3)."
  type        = string
  # Find current versions: https://cloud.google.com/composer/docs/concepts/versioning/composer-versions
  default     = "composer-2.6.4-airflow-2.7.3" # Choose a recent, stable version
}

variable "composer_python_version" {
  description = "Python major version for Composer environment."
  type        = string
  default     = "3"
}

variable "composer_env_size" {
  description = "Size of the Composer v2 environment (small, medium, large)."
  type        = string
  default     = "small"
}