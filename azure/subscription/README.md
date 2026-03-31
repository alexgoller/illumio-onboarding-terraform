# Azure Subscription Onboarding for Illumio CloudSecure

Creates an Azure AD application, service principal, and role assignments, then registers a single Azure subscription with Illumio CloudSecure.

## Prerequisites

- **Terraform** >= 1.7
- **azurerm provider** >= 3.0, **azuread provider** >= 2.0, **illumio-cloudsecure provider** >= 1.7.0
- Azure CLI authenticated (`az login`) with **Owner** or **User Access Administrator** role on the target subscription
- Permission to create Azure AD applications (Application Administrator or Global Administrator)
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Usage

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_azure" {
  # Use a local path, Git URL, or Terraform Registry source, e.g.:
  #   source = "../../azure/subscription"                                             # local path
  #   source = "git::https://github.com/<org>/illumio-onboarding-terraform.git//azure/subscription"  # Git
  source = "path/to/azure/subscription"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  subscription_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  subscription_name     = "Production Subscription"
  mode                  = "ReadWrite"

  # Optional: enable write permissions for NSG and/or Azure Firewall
  # enable_nsg_management  = true
  # enable_azfw_management = true

  # Optional: storage accounts for NSG flow logs
  # flow_logs_storage_account_ids = [
  #   "/subscriptions/.../providers/Microsoft.Storage/storageAccounts/saname"
  # ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | CloudSecure OAuth 2 client ID | `string` | — | yes |
| `illumio_client_secret` | CloudSecure OAuth 2 client secret | `string` | — | yes |
| `subscription_id` | Azure subscription ID to onboard | `string` | — | yes |
| `subscription_name` | Display name in CloudSecure | `string` | — | yes |
| `mode` | `"Read"` or `"ReadWrite"` | `string` | `"ReadWrite"` | no |
| `app_name` | Azure AD application display name | `string` | `"Illumio-CloudSecure-Access"` | no |
| `secret_expiration_days` | Days until the app secret expires | `number` | `365` | no |
| `enable_nsg_management` | Grant NSG management permissions | `bool` | `false` | no |
| `enable_azfw_management` | Grant Azure Firewall management permissions | `bool` | `false` | no |
| `flow_logs_storage_account_ids` | Storage account resource IDs for flow logs | `list(string)` | `[]` | no |
| `tags` | Tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `application_id` | Azure AD application (client) ID | no |
| `service_principal_id` | Azure AD service principal object ID | no |
| `client_secret` | Azure AD application password | yes |
| `illumio_subscription_id` | CloudSecure subscription resource ID | no |

## Resources Created

| Resource | Purpose |
|----------|---------|
| `azuread_application` | AD App Registration for CloudSecure |
| `azuread_service_principal` | Service Principal for the app |
| `azuread_application_password` | Client secret with configurable expiration |
| `azurerm_role_assignment` (Reader) | Reader role on the subscription |
| `azurerm_role_definition` (Firewall Admin) | Custom role for Azure Firewall management (when enabled) |
| `azurerm_role_definition` (NSG Admin) | Custom role for NSG management (when enabled) |
| `azurerm_role_assignment` (Storage) | Storage Blob Data Reader per storage account (for flow logs) |
| `illumio-cloudsecure_azure_subscription` | Registers the subscription with CloudSecure |
| `illumio-cloudsecure_azure_flow_logs_storage_account` | Registers flow log storage accounts (if provided) |

## Understanding `mode` vs. `enable_nsg_management` / `enable_azfw_management`

The `mode` variable controls how CloudSecure **treats** the subscription (read-only visibility vs. active enforcement). The `enable_*` flags control which **Azure RBAC permissions** are granted:

| Configuration | Effect |
|---------------|--------|
| `mode = "Read"` | CloudSecure monitors only, no write permissions granted regardless of enable flags |
| `mode = "ReadWrite"` | CloudSecure can enforce policy, but only has Reader role by default |
| `mode = "ReadWrite"` + `enable_nsg_management = true` | Adds NSG Admin + Firewall Admin custom roles for NSG enforcement |
| `mode = "ReadWrite"` + `enable_azfw_management = true` | Adds Firewall Admin custom role for Azure Firewall enforcement |

## Important Notes

- **Secret expiration**: The app secret expires after `secret_expiration_days` (default: 365 days). When it expires, CloudSecure loses access. Re-run `terraform apply` before expiration to rotate the secret.
- **Destroy behavior**: Destroying removes the AD application, service principal, all role assignments, and deregisters from CloudSecure. If other systems depend on the AD application, add `lifecycle { prevent_destroy = true }`.
- **Sensitive outputs**: The `client_secret` output is sensitive. Use an encrypted remote backend for state storage.
