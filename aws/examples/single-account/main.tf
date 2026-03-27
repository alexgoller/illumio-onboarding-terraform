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

module "illumio_aws_account" {
  source = "../../account"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  account_name          = var.account_name
  mode                  = var.mode

  flow_logs_s3_bucket_arn = var.flow_logs_s3_bucket_arn

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

variable "account_name" {
  description = "Display name for this AWS account in CloudSecure."
  type        = string
}

variable "mode" {
  description = "Access mode: Read or ReadWrite."
  type        = string
  default     = "ReadWrite"
}

variable "flow_logs_s3_bucket_arn" {
  description = "S3 bucket ARN for VPC flow logs (optional)."
  type        = string
  default     = ""
}

output "role_arn" {
  value = module.illumio_aws_account.role_arn
}

output "account_id" {
  value = module.illumio_aws_account.account_id
}
