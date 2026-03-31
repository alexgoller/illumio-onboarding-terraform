# GCP Organization Onboarding for Illumio CloudSecure

Creates a GCP service account with organization-level IAM bindings and registers the organization with Illumio CloudSecure, providing visibility (and optional enforcement) across all projects.

## Prerequisites

- **Terraform** >= 1.7
- **Google provider** >= 5.0
- **Illumio CloudSecure provider** >= 1.7.0
- Google Cloud SDK authenticated with Organization Admin permissions
- A GCP project to host the service account (can be any project in the org)
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

module "illumio_gcp_org" {
  # Use a local path, Git URL, or Terraform Registry source, e.g.:
  #   source = "../../gcp/organization"                                             # local path
  #   source = "git::https://github.com/<org>/illumio-onboarding-terraform.git//gcp/organization"  # Git
  source = "path/to/gcp/organization"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  organization_id       = "123456789012"
  organization_name     = "My GCP Organization"
  sa_project_id         = "my-admin-project"
  mode                  = "ReadWrite"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | CloudSecure OAuth 2 client ID | `string` | — | yes |
| `illumio_client_secret` | CloudSecure OAuth 2 client secret | `string` | — | yes |
| `organization_id` | GCP organization numeric ID (e.g., `"123456789012"`) | `string` | — | yes |
| `organization_name` | Display name in CloudSecure | `string` | — | yes |
| `sa_project_id` | GCP project where the service account is created | `string` | — | yes |
| `mode` | `"Read"` or `"ReadWrite"` | `string` | `"ReadWrite"` | no |
| `sa_name` | Service account name | `string` | `"illumio-cloudsecure"` | no |
| `sa_display_name` | Service account display name | `string` | `"Illumio CloudSecure Service Account"` | no |
| `illumio_sa_email` | Illumio's SA email for impersonation | `string` | `"illumio-onboarding@cs-prod-01.iam.gserviceaccount.com"` | no |
| `enable_api_enablement` | Grant `serviceusage` permissions | `bool` | `true` | no |
| `flow_logs_pubsub_topic_id` | Pub/Sub topic ID for flow logs | `string` | `""` | no |

> **Note on `organization_id` format**: This module expects just the numeric ID (e.g., `"123456789012"`). The [project module](../project/) expects the full format `"organizations/123456789012"`.

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `service_account_email` | Email of the created service account | no |
| `service_account_id` | Fully qualified ID of the service account | no |
| `illumio_resource_id` | CloudSecure resource ID for this organization | no |

## Differences from the Project Module

| Aspect | Project Module | Organization Module |
|--------|---------------|-------------------|
| IAM bindings | Project-level | Organization-level |
| Custom roles | Project-level | Organization-level |
| `roles/browser` | Not assigned | Assigned (required for org visibility) |
| Service account | Created in the target project | Created in `sa_project_id` |
| `organization_id` format | `"organizations/123456789012"` | `"123456789012"` (numeric only) |

## Important Notes

- **IAM propagation**: Organization-level IAM changes can take several minutes to propagate to all projects. CloudSecure may not see all projects immediately after apply.
- **Browser role**: The `roles/browser` binding is required for CloudSecure to list projects within the organization. This is a read-only role.
- **Destroy behavior**: Removes the service account, all organization-level IAM bindings, custom roles, and deregisters from CloudSecure.
