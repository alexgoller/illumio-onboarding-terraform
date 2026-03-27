terraform {
  required_version = ">= 1.7"
}

provider "google" {
  project = var.sa_project_id
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_gcp_organization" {
  source = "../../organization"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  organization_id       = var.organization_id
  organization_name     = var.organization_name
  sa_project_id         = var.sa_project_id
  mode                  = var.mode
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

variable "organization_id" {
  description = "GCP organization ID (numeric)."
  type        = string
}

variable "organization_name" {
  description = "Display name in CloudSecure."
  type        = string
}

variable "sa_project_id" {
  description = "GCP project to create the service account in."
  type        = string
}

variable "mode" {
  description = "Access mode: Read or ReadWrite."
  type        = string
  default     = "ReadWrite"
}

output "service_account_email" {
  value = module.illumio_gcp_organization.service_account_email
}
