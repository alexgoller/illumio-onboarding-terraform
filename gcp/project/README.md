# GCP Project Onboarding for Illumio CloudSecure

This Terraform module onboards a single GCP project into Illumio CloudSecure. It creates a dedicated service account, configures the necessary IAM bindings, enables required APIs, and registers the project with Illumio CloudSecure.

## Prerequisites

- Terraform >= 1.7
- Google provider >= 5.0
- Illumio CloudSecure provider >= 1.7.0
- An Illumio CloudSecure API key (client ID and secret)
- GCP project with permissions to create service accounts and manage IAM
- The GCP project must belong to a GCP organization

## Usage

```hcl
module "illumio_project" {
  source = "path/to/gcp/project"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret

  project_id      = "my-gcp-project-id"
  project_name    = "My GCP Project"
  organization_id = "organizations/123456789012"
  mode            = "ReadWrite"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| illumio_client_id | Illumio CloudSecure API client ID | `string` | n/a | yes |
| illumio_client_secret | Illumio CloudSecure API client secret | `string` | n/a | yes |
| project_id | GCP project ID to onboard | `string` | n/a | yes |
| project_name | Display name for the project in Illumio CloudSecure | `string` | n/a | yes |
| organization_id | GCP organization ID (e.g. "organizations/123456789012") | `string` | n/a | yes |
| mode | Onboarding mode: "Read" or "ReadWrite" | `string` | `"ReadWrite"` | no |
| sa_name | Name of the GCP service account to create | `string` | `"illumio-cloudsecure"` | no |
| sa_display_name | Display name for the GCP service account | `string` | `"Illumio CloudSecure Service Account"` | no |
| illumio_sa_email | Illumio's service account email for impersonation | `string` | `"illumio-onboarding@cs-prod-01.iam.gserviceaccount.com"` | no |
| enable_api_enablement | Whether to grant serviceusage permissions | `bool` | `true` | no |
| flow_logs_pubsub_topic_id | Optional Pub/Sub topic ID for flow logs | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_account_email | Email address of the created GCP service account |
| service_account_id | Fully qualified ID of the created GCP service account |
| illumio_project_id | Illumio CloudSecure project resource ID |
