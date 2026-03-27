variable "illumio_client_id" {
  description = "Illumio CloudSecure OAuth 2 client ID (from Service Account)."
  type        = string
  sensitive   = true
}

variable "illumio_client_secret" {
  description = "Illumio CloudSecure OAuth 2 client secret (from Service Account)."
  type        = string
  sensitive   = true
}

variable "account_name" {
  description = "Display name for the AWS account in Illumio CloudSecure."
  type        = string
}

variable "mode" {
  description = "Access mode for Illumio CloudSecure. \"ReadWrite\" allows policy enforcement, \"Read\" is visibility only."
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["Read", "ReadWrite"], var.mode)
    error_message = "Mode must be \"Read\" or \"ReadWrite\"."
  }
}

variable "role_name" {
  description = "Name of the IAM role to create for Illumio CloudSecure."
  type        = string
  default     = "IllumioCloudIntegrationRole"
}

variable "illumio_aws_account_id" {
  description = "Illumio's AWS account ID that will assume the cross-account role."
  type        = string
  default     = "712001342241"
}

variable "flow_logs_s3_bucket_arn" {
  description = "Optional ARN of an S3 bucket containing VPC flow logs. Set to empty string to skip."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to AWS resources."
  type        = map(string)
  default     = {}
}
