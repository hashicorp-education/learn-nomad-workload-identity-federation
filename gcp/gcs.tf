resource "random_id" "bucket_suffix" {
  byte_length = 12
}

resource "google_storage_bucket" "nomad" {
  location                    = "US"
  name                        = "${random_pet.main.id}-${random_id.bucket_suffix.hex}"
  uniform_bucket_level_access = "true"
  public_access_prevention    = "enforced"


  # DO NOT USE THIS IN PRODUCTION
  # Deletes all bucket objects on `terraform destroy`. Good for demos, bad for
  # production.
  force_destroy = true
}

resource "google_storage_bucket_acl" "nomad" {
  bucket = google_storage_bucket.nomad.name
}

resource "google_storage_bucket_iam_member" "nomad" {
  bucket = google_storage_bucket.nomad.name

  role   = "roles/storage.admin"
  member = google_service_account.nomad.member
}
