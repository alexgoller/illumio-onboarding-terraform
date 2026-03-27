variable "illumio_client_id" {
  description = "Illumio CloudSecure API client ID."
  type        = string
}

variable "illumio_client_secret" {
  description = "Illumio CloudSecure API client secret."
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "GCP folder ID to onboard (numeric ID, e.g. '123456789012')."
  type        = string
}

variable "folder_name" {
  description = "Display name for the folder in Illumio CloudSecure."
  type        = string
}

variable "organization_id" {
  description = "GCP organization numeric ID. Required for custom role creation since GCP does not support folder-level custom roles."
  type        = string
}

variable "sa_project_id" {
  description = "GCP project ID where the service account will be created."
  type        = string
}

variable "mode" {
  description = "Onboarding mode. 'Read' for read-only or 'ReadWrite' for full management."
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["Read", "ReadWrite"], var.mode)
    error_message = "Mode must be either 'Read' or 'ReadWrite'."
  }
}

variable "sa_name" {
  description = "Name of the GCP service account to create."
  type        = string
  default     = "illumio-cloudsecure"
}

variable "sa_display_name" {
  description = "Display name for the GCP service account."
  type        = string
  default     = "Illumio CloudSecure Service Account"
}

variable "illumio_sa_email" {
  description = "Illumio's service account email for impersonation."
  type        = string
  default     = "illumio-onboarding@cs-prod-01.iam.gserviceaccount.com"
}

variable "enable_api_enablement" {
  description = "Whether to grant serviceusage permissions for API enablement."
  type        = bool
  default     = true
}

variable "flow_logs_pubsub_topic_id" {
  description = "Optional Pub/Sub topic ID for flow logs. Leave empty to skip."
  type        = string
  default     = ""
}
