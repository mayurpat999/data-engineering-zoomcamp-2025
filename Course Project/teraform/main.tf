# main.tf

# 1. Google Cloud Storage (GCS) Bucket
# Used for Composer DAGs/logs (auto-created by Composer) and potentially other artifacts/staging.
resource "google_storage_bucket" "data_pipeline_artifacts" {
  # Creating a separate bucket for potential future use (e.g., dbt logs, other files)
  # Composer will create its own dedicated bucket.
  name          = "${var.gcp_project_id}-${var.gcs_bucket_name_suffix}-artifacts"
  project       = var.gcp_project_id
  location      = var.gcp_region # Use same region as other resources
  force_destroy = false          # Set to true only for non-production test environments

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30 # Example: Delete objects older than 30 days
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }

  depends_on = [ google_project_service.storage ]
}


# 2. BigQuery Datasets
resource "google_bigquery_dataset" "staging" {
  project                     = var.gcp_project_id
  dataset_id                  = var.bq_staging_dataset_id
  location                    = var.gcp_region # Keep data location consistent
  description                 = "Dataset for raw/staging Medicare data"
  delete_contents_on_destroy = false # Set to true only for non-production test environments

  depends_on = [ google_project_service.bigquery ]
}

resource "google_bigquery_dataset" "analytics" {
  project                     = var.gcp_project_id
  dataset_id                  = var.bq_analytics_dataset_id
  location                    = var.gcp_region
  description                 = "Dataset for transformed analytics-ready Medicare data"
  delete_contents_on_destroy = false

  depends_on = [ google_project_service.bigquery ]
}


# 3. Cloud Composer Environment (v2)
resource "google_composer_environment" "medicare_dag_orchestrator" {
  project = var.gcp_project_id
  name    = var.composer_env_name
  region  = var.gcp_region

  config {
    software_config {
      image_version = var.composer_image_version
      python_version = var.composer_python_version

      // Install necessary PyPI packages for DAGs
      pypi_packages = {
        # Provider needed for BigQueryOperator, etc.
        "apache-airflow-providers-google" = ""
        # Required for the dbt transformation step (if using BashOperator/KubePodOperator)
        "dbt-bigquery" = ""
        # Add other packages your DAGs might need
        #"pandas" = ""
      }
    }

    // Composer v2 specific configuration (adjust size as needed)
    environment_size = var.composer_env_size

    // Default networking for simplicity (uses default VPC)
    // For Private IP / VPC Native config, more complex node_config is needed.
  }

  // Ensure required APIs are enabled and dependent resources exist
  depends_on = [
    google_project_service.composer,
    google_project_service.compute,
    google_project_service.cloudbuild,
    google_project_service.containerregistry,
    google_project_service.artifactregistry,
    # Add dependencies on SAs if Composer needs to impersonate them immediately
    # google_service_account.dbt_runner_sa
  ]
}