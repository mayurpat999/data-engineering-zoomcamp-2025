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