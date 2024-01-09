resource "local_file" "agenthcl" {
  content  = templatefile("agent.hcl.tftpl", { oidc_issuer = local.issuer_uri })
  filename = "agent.hcl"
}

output "random_name" {
  value       = random_pet.main.id
  description = "Random pet name used for some resources. Informational only."
}

output "gcp_project_id" {
  value       = data.google_project.main.number
  description = "Google Cloud Project Number for use in gcs.nomad.hcl"
}

output "gcs_bucket" {
  value       = google_storage_bucket.nomad.name
  description = "Google Cloud Storage Bucket for use in gcs.nomad.hcl"
}

output "wid_provider" {
  value       = google_iam_workload_identity_pool_provider.nomad_provider.name
  description = "Google Workload Identity Pool Provider Name for use in gcs.nomad.hcl"
}

output "service_account" {
  value       = google_service_account.nomad.email
  description = "Google Service Account Email for use in gcs.nomad.hcl"
}

output "oidc_issuer_uri" {
  value       = local.issuer_uri
  description = "Put this in your Nomad agent config file."
}
