# GCP+Nomad Example

Example code for using Nomad Workload Identities to authenticate with Google
Cloud services using Google's Federated Workload Identities.

## Prequisites

- GCP Project
- DNS Zone - This will create a `google_dns_record_set` but assume the
  parent `google_dns_managed_zone` already exists.

## Layout

- Jobspecs
 - `gcs.nomad.hcl` - Puts `test.txt` into GCS using its Workload Identity
 - `proxy.nomad.hcl` - **REQUIRED** Runs an nginx proxy for ui & OIDC
- Terraform
 - `agent.hcl.tftpl` - Terraform Template for creating the Agent config
 - `compute.tf` - Instance group
 - `iam.tf` - Identity management
 - `outputs.tf` - Outputs for `gcs.nomad.hcl` variable inputs
 - `provider.tf` - Terraform provider
 - `variables.tf` - Variables
