output "role_arn" {
  description = "ARN of the IAM role created for Illumio CloudSecure."
  value       = aws_iam_role.illumio.arn
}

output "role_external_id" {
  description = "External ID used for the cross-account role assumption."
  value       = random_id.external_id.hex
  sensitive   = true
}

output "account_id" {
  description = "AWS account ID that was onboarded."
  value       = data.aws_caller_identity.current.account_id
}

output "illumio_account_id" {
  description = "Illumio CloudSecure account resource ID."
  value       = illumio-cloudsecure_aws_account.this.id
}
