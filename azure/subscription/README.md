# Azure Subscription Onboarding for Illumio CloudSecure

This Terraform module onboards a single Azure subscription to Illumio CloudSecure. It creates an Azure AD Application Registration, Service Principal, assigns the necessary roles, and registers the subscription with Illumio CloudSecure.

## Prerequisites

- Terraform >= 1.7
- An Azure account with permissions to create AD applications, service principals, and role assignments
- An Illumio CloudSecure account with API credentials (client ID and secret)
- The Azure subscription ID to onboard

## Usage

```hcl
module "illumio_azure_subscription" {
  source = "./azure/subscription"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret

  subscription_name = "My Azure Subscription"
  subscription_id   = "00000000-0000-0000-0000-000000000000"
  mode              = "ReadWrite"

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
| subscription_name | The display name for the subscription in Illumio CloudSecure. | `string` | n/a | yes |
| subscription_id | The Azure subscription ID to onboard. | `string` | n/a | yes |
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
| illumio_subscription_id | The Illumio CloudSecure subscription resource ID. |

## Resources Created

- **azuread_application** - Azure AD application registration for Illumio CloudSecure
- **azuread_service_principal** - Service principal linked to the application
- **azuread_application_password** - Client secret for the application
- **azurerm_role_assignment (Reader)** - Reader role on the subscription
- **azurerm_role_definition (Firewall Admin)** - Custom role for Azure Firewall management (conditional)
- **azurerm_role_assignment (Firewall Admin)** - Firewall admin role assignment (conditional)
- **azurerm_role_definition (NSG Admin)** - Custom role for NSG management (conditional)
- **azurerm_role_assignment (NSG Admin)** - NSG admin role assignment (conditional)
- **azurerm_role_assignment (Storage Blob Data Reader)** - Per storage account for flow logs (conditional)
- **illumio-cloudsecure_azure_subscription** - Registers the subscription with Illumio CloudSecure
- **illumio-cloudsecure_azure_flow_logs_storage_account** - Registers flow log storage accounts (conditional)
