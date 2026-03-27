# Azure Tenant Onboarding for Illumio CloudSecure

This Terraform module onboards an Azure tenant to Illumio CloudSecure. It creates an Azure AD Application Registration and Service Principal with permissions scoped at the root management group level, then registers specified subscriptions within the tenant with Illumio CloudSecure.

## Prerequisites

- Terraform >= 1.7
- An Azure account with permissions to create AD applications, service principals, and role assignments at the management group scope
- An Illumio CloudSecure account with API credentials (client ID and secret)
- The Azure AD tenant ID and a list of subscription IDs to onboard

## Usage

```hcl
module "illumio_azure_tenant" {
  source = "./azure/tenant"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret

  tenant_name = "My Azure Tenant"
  tenant_id   = "00000000-0000-0000-0000-000000000000"

  subscription_ids = [
    "11111111-1111-1111-1111-111111111111",
    "22222222-2222-2222-2222-222222222222",
  ]

  mode = "ReadWrite"

  enable_nsg_management  = true
  enable_azfw_management = false

  flow_logs_storage_account_ids = [
    "/subscriptions/.../storageAccounts/mystorageaccount"
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| illumio_client_id | The client ID for authenticating with the Illumio CloudSecure API. | `string` | n/a | yes |
| illumio_client_secret | The client secret for authenticating with the Illumio CloudSecure API. | `string` | n/a | yes |
| tenant_name | The display name for the tenant in Illumio CloudSecure. | `string` | n/a | yes |
| tenant_id | The Azure AD tenant ID to onboard. | `string` | n/a | yes |
| subscription_ids | A list of Azure subscription IDs within the tenant to register with Illumio CloudSecure. | `list(string)` | n/a | yes |
| mode | The onboarding mode for Illumio CloudSecure (`Read` or `ReadWrite`). | `string` | `"ReadWrite"` | no |
| app_name | The display name for the Azure AD application registration. | `string` | `"Illumio-CloudSecure-Access"` | no |
| secret_expiration_days | The number of days before the application password expires. | `number` | `365` | no |
| enable_nsg_management | Whether to enable Network Security Group management permissions. | `bool` | `false` | no |
| enable_azfw_management | Whether to enable Azure Firewall management permissions. | `bool` | `false` | no |
| flow_logs_storage_account_ids | A list of Azure Storage Account resource IDs containing flow logs. | `list(string)` | `[]` | no |
| tags | A map of tags to apply to resources that support tagging. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| application_id | The Application (client) ID of the Azure AD application. |
| service_principal_id | The Object ID of the Azure AD service principal. |
| client_secret | The client secret for the Azure AD application (sensitive). |
| illumio_subscription_ids | A map of Azure subscription IDs to their Illumio CloudSecure resource IDs. |

## Resources Created

- **azuread_application** - Azure AD application registration for Illumio CloudSecure
- **azuread_service_principal** - Service principal linked to the application
- **azuread_application_password** - Client secret for the application
- **azurerm_role_assignment (Reader)** - Reader role on the root management group
- **azurerm_role_definition (Firewall Admin)** - Custom role for Azure Firewall management at management group scope (conditional)
- **azurerm_role_assignment (Firewall Admin)** - Firewall admin role assignment at management group scope (conditional)
- **azurerm_role_definition (NSG Admin)** - Custom role for NSG management at management group scope (conditional)
- **azurerm_role_assignment (NSG Admin)** - NSG admin role assignment at management group scope (conditional)
- **azurerm_role_assignment (Storage Blob Data Reader)** - Per storage account for flow logs (conditional)
- **illumio-cloudsecure_azure_subscription** - Registers each subscription with Illumio CloudSecure (one per subscription_id)
- **illumio-cloudsecure_azure_flow_logs_storage_account** - Registers flow log storage accounts (conditional)

## Key Differences from the Subscription Module

| Aspect | Subscription Module | Tenant Module |
|--------|-------------------|---------------|
| Scope | Single subscription | Root management group (tenant-wide) |
| Role assignments | Scoped to `/subscriptions/{id}` | Scoped to `/providers/Microsoft.Management/managementGroups/{tenant_id}` |
| CloudSecure registration | Single subscription | Multiple subscriptions via `for_each` |
| Custom role names | Suffixed with subscription ID | Suffixed with tenant ID |
