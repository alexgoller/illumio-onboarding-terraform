terraform {
  required_version = ">= 1.7"
}

provider "google" {
  project = var.project_id
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_gcp_project" {
  source = "../../project"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  project_id            = var.project_id
  project_name          = var.project_name
  organization_id       = var.organization_id
  mode                  = var.mode

  flow_logs_pubsub_topic_id = var.flow_logs_pubsub_topic_id
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

variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "project_name" {
  description = "Display name in CloudSecure."
  type        = string
}

variable "organization_id" {
  description = "GCP organization ID (e.g. 'organizations/123456789012')."
  type        = string
}

variable "mode" {
  description = "Access mode: Read or ReadWrite."
  type        = string
  default     = "ReadWrite"
}

variable "flow_logs_pubsub_topic_id" {
  description = "Pub/Sub topic resource ID for flow logs (optional)."
  type        = string
  default     = ""
}

output "service_account_email" {
  value = module.illumio_gcp_project.service_account_email
}
