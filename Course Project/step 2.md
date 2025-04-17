Okay, let's break down Step 2 (Cloud Development and IaC using Terraform on GCP) step-by-step, providing illustrative Terraform code.

**Goal:** To define and provision the necessary GCP infrastructure using Terraform.

**Prerequisites:**

1.  **Terraform Installed:** Download and install Terraform.
2.  **GCP Account:** You need a Google Cloud Platform account with billing enabled.
3.  **GCP Project:** Create a GCP project. Note its **Project ID**.
4.  **`gcloud` CLI:** Install the Google Cloud SDK (`gcloud`).
5.  **Authentication:** Authenticate your local environment to GCP. The easiest way for local development is:
    ```bash
    gcloud auth application-default login
    ```
    The identity you log in with needs sufficient permissions in your GCP project to create the resources below (e.g., roles like Project Editor, or more granular roles like Compute Admin, Storage Admin, Composer Admin, BigQuery Admin, Service Account Admin, IAM Admin).
6.  **Enable APIs:** Although Terraform can enable APIs, sometimes it's easier to pre-emptively enable them via the console or `gcloud`, especially if Terraform's service account has restricted permissions:
    *   Compute Engine API
    *   Cloud Storage API
    *   Cloud Composer API
    *   BigQuery API
    *   IAM API
    *   Service Usage API (usually enabled by default)
    *   Cloud Resource Manager API (usually enabled by default)

---

**Step-by-Step Infrastructure Setup with Terraform**

We'll organize the Terraform code into logical files:

1.  `main.tf`: Defines the main resources (GCS, BigQuery, Composer).
2.  `variables.tf`: Declares input variables.
3.  `outputs.tf`: Declares outputs (useful information after provisioning).
4.  `iam.tf`: Defines Service Accounts and IAM permissions.
5.  `providers.tf`: Configures the GCP provider.
6.  `apis.tf`: Explicitly enables required APIs.
7.  `terraform.tfvars` (You create this file): Assigns values to the variables.

---

**File: `variables.tf`**

```terraform
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
```

---

**File: `providers.tf`**

```terraform
# providers.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Use a recent version
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
```

---

**File: `apis.tf`**

```terraform
# apis.tf

# Although Composer setup often enables many dependent APIs,
# explicitly enabling them ensures they are active.

resource "google_project_service" "compute" {
  project = var.gcp_project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project = var.gcp_project_id
  service = "storage-component.googleapis.com" # Often enabled by default
  disable_on_destroy = false
}

resource "google_project_service" "composer" {
  project = var.gcp_project_id
  service = "composer.googleapis.com"
  disable_on_destroy = false # Keep API enabled even if TF destroys resources
}

resource "google_project_service" "bigquery" {
  project = var.gcp_project_id
  service = "bigquery.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  project = var.gcp_project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "serviceusage" {
  project = var.gcp_project_id
  service = "serviceusage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.gcp_project_id
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  # Composer uses Cloud Build during environment creation/updates
  project = var.gcp_project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "containerregistry" {
  # Composer may use Container Registry or Artifact Registry
  project = var.gcp_project_id
  service = "containerregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project = var.gcp_project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

```

---

**File: `iam.tf`**

```terraform
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

```

---

**File: `main.tf`**

```terraform
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

```

---

**File: `outputs.tf`**

```terraform
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
```

---

**File: `terraform.tfvars` (You create this file)**

```terraform
# terraform.tfvars

gcp_project_id = "your-gcp-project-id"  # <-- REPLACE THIS

# Optional: Override defaults from variables.tf if needed
# gcp_region               = "us-west1"
# bq_staging_dataset_id    = "medicare_staging_data"
# bq_analytics_dataset_id  = "medicare_prod_analytics"
# composer_env_name        = "medicare-airflow-prod"
# composer_env_size        = "medium"
```

**Important:** Replace `"your-gcp-project-id"` with your actual GCP Project ID.

---

**Execution Steps:**

1.  **Save Files:** Place all the `.tf` files (`main.tf`, `variables.tf`, `outputs.tf`, `iam.tf`, `providers.tf`, `apis.tf`) in the same directory.
2.  **Create `terraform.tfvars`:** Create the `terraform.tfvars` file in the same directory and paste the content above, making sure to set your `gcp_project_id`.
3.  **Initialize Terraform:** Open your terminal in that directory and run:
    ```bash
    terraform init
    ```
    This downloads the necessary provider plugins.
4.  **Plan:** See what Terraform intends to create:
    ```bash
    terraform plan -out=tfplan
    ```
    Review the output carefully to ensure it matches your expectations.
5.  **Apply:** Provision the resources in GCP:
    ```bash
    terraform apply tfplan
    ```
    Terraform will ask for confirmation; type `yes` to proceed. This step can take several minutes, especially for the Cloud Composer environment.
6.  **Review Outputs:** Once applied, Terraform will display the outputs defined in `outputs.tf` (like the Airflow UI link, bucket names, service account emails).

---

**Manual Steps After Terraform:**

1.  **dbt Service Account Key:**
    *   Go to the GCP Console -> IAM & Admin -> Service Accounts.
    *   Find the `dbt-runner-sa@...` service account.
    *   Go to the "Keys" tab -> "Add Key" -> "Create new key" -> Select "JSON" -> "Create".
    *   **Securely download and store this JSON key file.** This file will be used to configure `dbt`'s `profiles.yml` to authenticate to BigQuery. **Do not commit this key to version control.**
2.  **Power BI Service Account Key:**
    *   Repeat the key generation process for the `powerbi-reader-sa@...` service account.
    *   This JSON key (or its contents) will be needed when setting up the BigQuery connection in Power BI using the "Service Account" authentication method. Store it securely.

---

You have now provisioned the core GCP infrastructure required for the data pipeline using Infrastructure as Code. The next steps involve developing the Airflow DAGs (Step 3), creating the dbt models (Step 5), and building the Power BI dashboard (Step 6).