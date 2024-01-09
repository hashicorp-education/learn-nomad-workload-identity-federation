variable "gcp_project_id" {
  description = "Google Cloud Project ID Number"
}

variable "gcs_bucket" {
  description = "Google Cloud Storage Bucket Name"
}

variable "wid_provider" {
  description = "Google Cloud IAM Workload Identity Pool Provider Name"
}

variable "service_account" {
  description = "Google Cloud Service Account Email"
}

job "gcs-job" {
  type = "batch"

  group "gcs-group" {
    task "gcs-task" {
      driver = "docker"

      # Example batch job which authenticates using its workload identity and
      # uploads a templated file to the specified GCS Bucket.
      config {
        command        = "/bin/sh"
        args           = ["-c", "echo 'running; check stderr' && gcloud auth login --cred-file=/local/cred.json && gcloud storage cp /local/test.txt gs://${NOMAD_META_bucket}"]
        image          = "google/cloud-sdk:457.0.0"
        auth_soft_fail = true
      }

      meta {
        project      = var.gcp_project_id
        bucket       = var.gcs_bucket
        wid_provider = var.wid_provider
        service_acct = var.service_account
      }

      # Nomad Workload Identity for authenticating with Google Federated
      # Workload Identity Provider
      identity {
        # Name must match the file parameter in the credential config template
        # below *and* the principal used in the Service Account IAM Binding.
        name = "tutorial"
        file = true

        # Audience must match the audience specified in the Google IAM Workload
        # Identity Pool Provider.
        aud  = ["gcp"]
        ttl  = "1h"
      }

      # Example file for uploading to GCS
      template {
        destination = "local/test.txt"
        data        = <<EOF
Job:          {{ env "NOMAD_JOB_NAME" }}
Alloc:        {{ env "NOMAD_ALLOC_ID" }}
Project:      {{ env "NOMAD_META_project" }}
Bucket:       {{ env "NOMAD_META_bucket" }}
WID Provider: {{ env "NOMAD_META_wid_provider" }}
Service Acct: {{ env "NOMAD_META_service_acct" }}
EOF
      }

      # Credential file for Google's Cloud SDK
      # Can be generated with:
      #   gcloud iam workload-identity-pools create-cred-config
      template {
        destination = "local/cred.json"
        data        = <<EOF
{
  "type": "external_account",
  "audience": "//iam.googleapis.com/{{ env "NOMAD_META_wid_provider" }}",
  "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
  "token_url": "https://sts.googleapis.com/v1/token",
  "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/{{ env "NOMAD_META_service_acct" }}:generateAccessToken",
  "credential_source": {
    "file": "/secrets/nomad_tutorial.jwt",
    "format": {
      "type": "text"
    }
  }
}
EOF
      }

      resources {
        cpu    = 500
        memory = 600
      }

    } # Task
  }   # Group
}     # Job
