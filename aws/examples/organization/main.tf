terraform {
  required_version = ">= 1.7"
}

provider "aws" {
  region = "us-west-2"
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_aws_organization" {
  source = "../../organization"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  organization_name     = var.organization_name
  mode                  = var.mode
  target_ou_ids         = var.target_ou_ids

  tags = {
    ManagedBy = "terraform"
    Purpose   = "illumio-cloudsecure"
  }
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

variable "organization_name" {
  description = "Display name for this organization in CloudSecure."
  type        = string
}

variable "mode" {
  description = "Access mode: Read or ReadWrite."
  type        = string
  default     = "ReadWrite"
}

variable "target_ou_ids" {
  description = "List of AWS Organizational Unit IDs to deploy to."
  type        = list(string)
}

output "management_account_role_arn" {
  value = module.illumio_aws_organization.management_account_role_arn
}
