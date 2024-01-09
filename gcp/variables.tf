variable "region" {
  description = "The GCP region to deploy to."
  default     = "us-central1"
}


variable "zone" {
  description = "The GCP zone to deploy to."
  default     = "us-central1-a"
}

variable "project" {
  description = "The GCP project to use."
}

variable "parent_zone_name" {
  description = "Parent domain for HTTPS certificate. Must already exist."
}

variable "domain" {
  description = "Domain for HTTPS certificate. Must match oidc_issuer."
}

locals {
  issuer_uri = "https://${var.domain}/"
}
