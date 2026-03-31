# GCP Project Onboarding for Illumio CloudSecure

Creates a GCP service account with appropriate IAM bindings and registers a single GCP project with Illumio CloudSecure.

## Prerequisites

- **Terraform** >= 1.7
- **Google provider** >= 5.0
- **Illumio CloudSecure provider** >= 1.7.0
- Google Cloud SDK authenticated (`gcloud auth application-default login`)
- IAM permissions: `iam.serviceAccounts.create`, `resourcemanager.projects.setIamPolicy`, `iam.roles.create`
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Usage

```hcl
provider "google" {
  project = "my-gcp-project"
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_gcp" {
  # Use a local path, Git URL, or Terraform Registry source, e.g.:
  #   source = "../../gcp/project"                                             # local path
  #   source = "git::https://github.com/<org>/illumio-onboarding-terraform.git//gcp/project"  # Git
  source = "path/to/gcp/project"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  project_id            = "my-gcp-project"
  project_name          = "Production GCP Project"
  organization_id       = "organizations/123456789012"
  mode                  = "ReadWrite"

  # Optional: Pub/Sub topic for VPC flow logs
  # flow_logs_pubsub_topic_id = "projects/my-project/topics/flow-logs"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | CloudSecure OAuth 2 client ID | `string` | — | yes |
| `illumio_client_secret` | CloudSecure OAuth 2 client secret | `string` | — | yes |
| `project_id` | GCP project ID | `string` | — | yes |
| `project_name` | Display name in CloudSecure | `string` | — | yes |
| `organization_id` | GCP organization ID (format: `"organizations/123456789012"`) | `string` | — | yes |
| `mode` | `"Read"` or `"ReadWrite"` | `string` | `"ReadWrite"` | no |
| `sa_name` | Service account name | `string` | `"illumio-cloudsecure"` | no |
| `sa_display_name` | Service account display name | `string` | `"Illumio CloudSecure Service Account"` | no |
| `illumio_sa_email` | Illumio's SA email for impersonation | `string` | `"illumio-onboarding@cs-prod-01.iam.gserviceaccount.com"` | no |
| `enable_api_enablement` | Grant `serviceusage` permissions | `bool` | `true` | no |
| `flow_logs_pubsub_topic_id` | Pub/Sub topic ID for flow logs | `string` | `""` | no |

> **Note on `organization_id` format**: This module expects the full format with prefix (e.g., `"organizations/123456789012"`). The [organization](../organization/) and [folder](../folder/) modules expect just the numeric ID.

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `service_account_email` | Email of the created service account | no |
| `service_account_id` | Fully qualified ID of the service account | no |
| `illumio_project_id` | CloudSecure project resource ID | no |

## Resources Created

| Resource | Purpose |
|----------|---------|
| `google_service_account` | Service account for CloudSecure |
| `google_project_service` (x2) | Enables `iamcredentials` and `cloudresourcemanager` APIs |
| `google_project_iam_member` (x3) | Binds `securityReviewer`, `compute.viewer`, `cloudasset.viewer` |
| `google_service_account_iam_member` | Grants `serviceAccountTokenCreator` to Illumio's SA for impersonation |
| `google_project_iam_custom_role` (API) | Grants `serviceusage` permissions (when `enable_api_enablement = true`) |
| `google_project_iam_custom_role` (write) | Grants firewall rule management (when `mode = "ReadWrite"`) |
| `illumio-cloudsecure_gcp_project` | Registers the project with CloudSecure |
| `illumio-cloudsecure_gcp_flow_logs_pubsub_topic` | Registers flow log topic (if provided) |

## Important Notes

- **Impersonation**: Illumio's service account (`illumio-onboarding@cs-prod-01.iam.gserviceaccount.com`) is granted `serviceAccountTokenCreator` on the created service account. This allows Illumio to impersonate it without storing long-lived keys.
- **API enablement**: The module enables `iamcredentials.googleapis.com` and `cloudresourcemanager.googleapis.com` in your project. Existing APIs are not affected.
- **Destroy behavior**: Removes the service account, all IAM bindings, custom roles, and deregisters from CloudSecure.
