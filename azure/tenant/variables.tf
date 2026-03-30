variable "illumio_client_id" {
  description = "The client ID for authenticating with the Illumio CloudSecure API."
  type        = string
  sensitive   = true
}

variable "illumio_client_secret" {
  description = "The client secret for authenticating with the Illumio CloudSecure API."
  type        = string
  sensitive   = true
}

variable "tenant_name" {
  description = "The display name for the tenant in Illumio CloudSecure."
  type        = string
}

variable "tenant_id" {
  description = "The Azure AD tenant ID to onboard."
  type        = string
}

variable "subscription_ids" {
  description = "A list of Azure subscription IDs within the tenant to register with Illumio CloudSecure."
  type        = list(string)
}

variable "mode" {
  description = "The onboarding mode for Illumio CloudSecure. Must be 'Read' or 'ReadWrite'."
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["Read", "ReadWrite"], var.mode)
    error_message = "Mode must be either 'Read' or 'ReadWrite'."
  }
}

variable "app_name" {
  description = "The display name for the Azure AD application registration."
  type        = string
  default     = "Illumio-CloudSecure-Access"
}

variable "secret_expiration_days" {
  description = "The number of days before the application password expires."
  type        = number
  default     = 365
}

variable "enable_nsg_management" {
  description = "Whether to enable Network Security Group (NSG) management permissions."
  type        = bool
  default     = false
}

variable "enable_azfw_management" {
  description = "Whether to enable Azure Firewall management permissions."
  type        = bool
  default     = false
}

variable "flow_logs_storage_account_ids" {
  description = "A list of Azure Storage Account resource IDs containing flow logs."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to apply to resources that support tagging."
  type        = map(string)
  default     = {}
}
