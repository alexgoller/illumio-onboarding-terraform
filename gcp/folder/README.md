# GCP Folder Onboarding for Illumio CloudSecure

Creates a GCP service account with folder-level IAM bindings and registers the folder with Illumio CloudSecure, providing visibility (and optional enforcement) across all projects in the folder.

## Prerequisites

- **Terraform** >= 1.7
- **Google provider** >= 5.0
- **Illumio CloudSecure provider** >= 1.7.0
- Google Cloud SDK authenticated with Folder Admin and Organization Role Admin permissions
- A GCP project to host the service account
- The organization ID (required because GCP does not support folder-level custom IAM roles)
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Usage

```hcl
provider "google" {
  project = "my-admin-project"
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_gcp_folder" {
  source = "path/to/gcp/folder"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  folder_id             = "123456789012"
  folder_name           = "Production Folder"
  organization_id       = "987654321098"
  sa_project_id         = "my-admin-project"
  mode                  = "ReadWrite"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | CloudSecure OAuth 2 client ID | `string` | — | yes |
| `illumio_client_secret` | CloudSecure OAuth 2 client secret | `string` | — | yes |
| `folder_id` | GCP folder numeric ID | `string` | — | yes |
| `folder_name` | Display name in CloudSecure | `string` | — | yes |
| `organization_id` | GCP organization numeric ID (for custom role creation) | `string` | — | yes |
| `sa_project_id` | GCP project where the service account is created | `string` | — | yes |
| `mode` | `"Read"` or `"ReadWrite"` | `string` | `"ReadWrite"` | no |
| `sa_name` | Service account name | `string` | `"illumio-cloudsecure"` | no |
| `sa_display_name` | Service account display name | `string` | `"Illumio CloudSecure Service Account"` | no |
| `illumio_sa_email` | Illumio's SA email for impersonation | `string` | `"illumio-onboarding@cs-prod-01.iam.gserviceaccount.com"` | no |
| `enable_api_enablement` | Grant `serviceusage` permissions | `bool` | `true` | no |
| `flow_logs_pubsub_topic_id` | Pub/Sub topic ID for flow logs | `string` | `""` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `service_account_email` | Email of the created service account | no |
| `service_account_id` | Fully qualified ID of the service account | no |
| `illumio_resource_id` | CloudSecure resource ID for this folder | no |

## Why `organization_id` Is Required

GCP does not support custom IAM roles at the folder level. When `mode = "ReadWrite"` or `enable_api_enablement = true`, this module creates custom roles at the **organization** level and binds them at the **folder** level.

## Important Notes

- **Custom roles at org level**: The `illumioCloudSecureReadWrite` and `illumioCloudSecureApiEnablement` custom roles are created at the organization level even though bindings are folder-scoped. This is a GCP platform limitation.
- **Browser role**: Like the organization module, `roles/browser` is assigned at the folder level for CloudSecure to enumerate projects.
- **Destroy behavior**: Removes the service account, folder-level IAM bindings, organization-level custom roles, and deregisters from CloudSecure.
