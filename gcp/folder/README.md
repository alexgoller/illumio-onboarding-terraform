# GCP Folder Onboarding for Illumio CloudSecure

This Terraform module onboards a GCP folder into Illumio CloudSecure. It creates a service account in a designated project, configures folder-level IAM bindings, enables required APIs, and registers the folder with Illumio CloudSecure.

Note: Custom roles are created at the organization level because GCP does not support folder-level custom roles.

## Prerequisites

- Terraform >= 1.7
- Google provider >= 5.0
- Illumio CloudSecure provider >= 1.7.0
- An Illumio CloudSecure API key (client ID and secret)
- A GCP project for hosting the service account
- Folder-level IAM permissions to manage bindings
- Organization-level permissions for custom role creation

## Usage

```hcl
module "illumio_folder" {
  source = "path/to/gcp/folder"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret

  folder_id       = "123456789012"
  folder_name     = "My GCP Folder"
  organization_id = "987654321098"
  sa_project_id   = "my-admin-project"
  mode            = "ReadWrite"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| illumio_client_id | Illumio CloudSecure API client ID | `string` | n/a | yes |
| illumio_client_secret | Illumio CloudSecure API client secret | `string` | n/a | yes |
| folder_id | GCP folder ID (numeric) | `string` | n/a | yes |
| folder_name | Display name for the folder in Illumio CloudSecure | `string` | n/a | yes |
| organization_id | GCP organization numeric ID (for custom role creation) | `string` | n/a | yes |
| sa_project_id | GCP project ID where the service account will be created | `string` | n/a | yes |
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
