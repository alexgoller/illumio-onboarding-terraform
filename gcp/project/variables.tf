variable "illumio_client_id" {
  description = "Illumio CloudSecure API client ID."
  type        = string
  sensitive   = true
}

variable "illumio_client_secret" {
  description = "Illumio CloudSecure API client secret."
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "GCP project ID to onboard."
  type        = string
}

variable "project_name" {
  description = "Display name for the project in Illumio CloudSecure."
  type        = string
}

variable "organization_id" {
  description = "GCP organization ID in the format 'organizations/123456789012'. Required by the Illumio provider."
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
