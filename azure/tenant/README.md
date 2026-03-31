# Azure Tenant Onboarding for Illumio CloudSecure

Creates an Azure AD application with tenant-wide Reader permissions (at the root management group), then registers one or more subscriptions with Illumio CloudSecure using shared credentials.

## When to Use This vs. the Subscription Module

| | Subscription Module | Tenant Module |
|---|---|---|
| **Scope** | Single subscription | Entire tenant |
| **Reader role** | Scoped to one subscription | Scoped to root management group (all subscriptions) |
| **Custom roles** | Scoped to subscription | Scoped to root management group |
| **Registrations** | One subscription | Multiple subscriptions via `subscription_ids` |
| **Best for** | Individual subscription onboarding | Centralized onboarding of many subscriptions |

## Prerequisites

- **Terraform** >= 1.7
- **azurerm provider** >= 3.0, **azuread provider** >= 2.0, **illumio-cloudsecure provider** >= 1.7.0
- Azure CLI authenticated with **Owner** or **User Access Administrator** on the tenant root management group
- Permission to create Azure AD applications (Application Administrator or Global Administrator)
- You may need to enable "Access management for Azure resources" in Azure AD > Properties
- Illumio CloudSecure service account credentials

## Usage

```hcl
provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_tenant" {
  # Use a local path, Git URL, or Terraform Registry source, e.g.:
  #   source = "../../azure/tenant"                                             # local path
  #   source = "git::https://github.com/<org>/illumio-onboarding-terraform.git//azure/tenant"  # Git
  source = "path/to/azure/tenant"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  tenant_id             = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_name           = "Production Tenant"
  subscription_ids      = [
    "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | CloudSecure OAuth 2 client ID | `string` | — | yes |
| `illumio_client_secret` | CloudSecure OAuth 2 client secret | `string` | — | yes |
| `tenant_id` | Azure AD tenant ID | `string` | — | yes |
| `tenant_name` | Display name in CloudSecure | `string` | — | yes |
| `subscription_ids` | Subscription IDs to register with CloudSecure | `list(string)` | — | yes |
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
| `illumio_subscription_ids` | Map of subscription IDs to CloudSecure resource IDs | no |

## Important Notes

- **Secret expiration**: Same as the subscription module — the app secret defaults to 365 days. Re-run `terraform apply` before expiration.
- **Elevated permissions**: The root management group scope requires elevated access. You may need to enable "Access management for Azure resources" under Azure AD > Properties.
- **Adding subscriptions**: To onboard additional subscriptions, add them to `subscription_ids` and re-run `terraform apply`. The existing AD app and roles are reused.
- **Destroy behavior**: Removes the AD application, all role assignments at the management group scope, and deregisters all subscriptions from CloudSecure.
