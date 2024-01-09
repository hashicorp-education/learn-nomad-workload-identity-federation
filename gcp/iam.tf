# Workload Identity Pool
resource "google_iam_workload_identity_pool" "nomad" {
  # GCP disallows reusing pool names within 30 days, so use a random name.
  workload_identity_pool_id = "nomad-pool-${random_pet.main.id}"
}

# Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "nomad_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.nomad.workload_identity_pool_id
  workload_identity_pool_provider_id = "nomad-provider"
  display_name                       = "Nomad Provider"
  description                        = "OIDC identity pool provider"

  # Map the Nomad Workload Identity's subject to Google's subject. This ties
  # the Google Workload Identity Pool Provider to the specific tutorial job.
  #
  # If changed then the principal used for the Google Service Account IAM
  # Binding must be changed below as well.
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  oidc {
    # Allowed audiences must match the aud parameter of the Nomad Workload
    # Identity being used.
    allowed_audiences = ["gcp"]
    issuer_uri        = local.issuer_uri
  }
}

# Service Account which Nomad Workload Identities will map to.
resource "google_service_account" "nomad" {
  account_id   = "nomad-wid"
  display_name = "Nomad Workload Identity Service Account"
}

# IAM Binding links the Workload Identity Pool -> Service Account.
resource "google_service_account_iam_binding" "nomad" {
  service_account_id = google_service_account.nomad.name

  role = "roles/iam.workloadIdentityUser"

  members = [
    # google_workload_identity_pool lacks an attribute for the principal, so
    # string format it manually to look like:
    #principal://iam.googleapis.com/projects/PROJECT_NUM/locations/global/workloadIdentityPools/POOL_NAME/subject/SUBJECT_MAPPING
    "principal://iam.googleapis.com/${google_iam_workload_identity_pool.nomad.name}/subject/global:default:gcs-job:gcs-group:gcs-task:tutorial"
  ]

  depends_on = [
    google_iam_workload_identity_pool.nomad
  ]
}
