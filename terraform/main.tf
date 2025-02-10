provider "google" {
  credentials = file("YOUR_JSON_FILE_CREDENTIALS")
  project     = "YOUR_GCP_PROJECT"
  region      = "us-central1"
}

resource "google_container_cluster" "gke_cluster" {
  name     = "YOUR_GCP_CLUSTER_NAME"
  location = "us-central1"

  # Remove the default node pool instead of setting initial_node_count
  remove_default_node_pool = true
  initial_node_count       = 1  # This is required by GKE but will be overridden

  deletion_protection = false  # Ensure the cluster can be deleted

  workload_identity_config {
    workload_pool = "YOUR_GCP_PROJECT.svc.id.goog"
  }

  addons_config {
    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "poc-gke-nodepool"
  location   = "us-central1"
  cluster    = google_container_cluster.gke_cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    service_account = "GOOGLE_SERVICE_ACCOUNT@YOUR_GCP_PROJECT.iam.gserviceaccount.com"
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

resource "google_storage_bucket" "static" {
  name          = "YOUR_BUCKET_NAME-${random_id.bucket_suffix.hex}"
  location      = "us-central1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
