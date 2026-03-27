terraform {
  required_version = ">= 1.7"
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_azure_tenant" {
  source = "../../tenant"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  tenant_name           = var.tenant_name
  tenant_id             = var.tenant_id
  subscription_ids      = var.subscription_ids
  mode                  = var.mode

  enable_nsg_management  = var.enable_nsg_management
  enable_azfw_management = var.enable_azfw_management
}

variable "illumio_client_id" {
  description = "Illumio CloudSecure OAuth 2 client ID."
  type        = string
  sensitive   = true
}

variable "illumio_client_secret" {
  description = "Illumio CloudSecure OAuth 2 client secret."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "tenant_name" {
  description = "Display name in CloudSecure."
  type        = string
}

variable "subscription_ids" {
  description = "List of subscription IDs to register with CloudSecure."
  type        = list(string)
}

variable "mode" {
  description = "Access mode: Read or ReadWrite."
  type        = string
  default     = "ReadWrite"
}

variable "enable_nsg_management" {
  description = "Enable NSG management permissions."
  type        = bool
  default     = false
}

variable "enable_azfw_management" {
  description = "Enable Azure Firewall management permissions."
  type        = bool
  default     = false
}

output "application_id" {
  value = module.illumio_azure_tenant.application_id
}
