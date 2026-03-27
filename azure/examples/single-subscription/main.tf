terraform {
  required_version = ">= 1.7"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_azure_subscription" {
  source = "../../subscription"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  subscription_name     = var.subscription_name
  subscription_id       = var.subscription_id
  mode                  = var.mode

  enable_nsg_management  = var.enable_nsg_management
  enable_azfw_management = var.enable_azfw_management

  flow_logs_storage_account_ids = var.flow_logs_storage_account_ids
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

variable "subscription_id" {
  description = "Azure subscription ID to onboard."
  type        = string
}

variable "subscription_name" {
  description = "Display name in CloudSecure."
  type        = string
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

variable "flow_logs_storage_account_ids" {
  description = "List of storage account resource IDs for flow logs."
  type        = list(string)
  default     = []
}

output "application_id" {
  value = module.illumio_azure_subscription.application_id
}
