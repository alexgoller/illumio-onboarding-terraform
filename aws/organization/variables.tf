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

variable "organization_name" {
  description = "Display name for the AWS Organization in Illumio CloudSecure."
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
  description = "Name of the IAM role to create for Illumio CloudSecure in all accounts."
  type        = string
  default     = "IllumioCloudIntegrationRole"
}

variable "illumio_aws_account_id" {
  description = "Illumio's AWS account ID that will assume the cross-account role."
  type        = string
  default     = "712001342241"
}

variable "target_ou_ids" {
  description = "List of AWS Organization Unit IDs to deploy the IAM role StackSet to."
  type        = list(string)

  validation {
    condition     = length(var.target_ou_ids) > 0
    error_message = "At least one target OU ID must be provided."
  }
}

variable "member_account_ids" {
  description = "Optional set of member account IDs to register with Illumio CloudSecure. If empty, only the management account is registered."
  type        = set(string)
  default     = []
}

variable "flow_logs_s3_bucket_arn" {
  description = "Optional ARN of an S3 bucket containing VPC flow logs. Set to empty string to skip."
  type        = string
  default     = ""
}

variable "stackset_failure_tolerance_percentage" {
  description = "The percentage of accounts for which StackSet operations can fail before the operation is stopped."
  type        = number
  default     = 0
}

variable "stackset_max_concurrent_percentage" {
  description = "The maximum percentage of accounts in which to perform StackSet operations at one time."
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags to apply to AWS resources."
  type        = map(string)
  default     = {}
}
