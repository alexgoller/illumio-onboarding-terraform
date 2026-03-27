output "management_account_role_arn" {
  description = "ARN of the IAM role created in the management account."
  value       = aws_iam_role.illumio.arn
}

output "management_account_id" {
  description = "AWS management account ID that was onboarded."
  value       = data.aws_caller_identity.current.account_id
}

output "role_external_id" {
  description = "External ID used for cross-account role assumption (shared across all accounts)."
  value       = random_id.external_id.hex
  sensitive   = true
}

output "stack_set_id" {
  description = "ID of the CloudFormation StackSet deploying roles to member accounts."
  value       = aws_cloudformation_stack_set.illumio_role.stack_set_id
}

output "illumio_management_account_id" {
  description = "Illumio CloudSecure resource ID for the management account."
  value       = illumio-cloudsecure_aws_account.management.id
}

output "illumio_member_account_ids" {
  description = "Map of member account IDs to their Illumio CloudSecure resource IDs."
  value       = { for k, v in illumio-cloudsecure_aws_account.member : k => v.id }
}

output "organization_id" {
  description = "AWS Organization ID."
  value       = data.aws_organizations_organization.current.id
}
