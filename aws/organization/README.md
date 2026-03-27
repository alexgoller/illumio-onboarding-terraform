# AWS Organization Onboarding for Illumio CloudSecure

This Terraform module onboards an entire AWS Organization to Illumio CloudSecure. It creates the necessary IAM roles in both the management account and member accounts (via CloudFormation StackSets), then registers the accounts with Illumio CloudSecure.

## What this module does

1. **Management account IAM role** -- Creates an IAM role in the management account with the required read (and optionally write) policies for Illumio CloudSecure cross-account access.
2. **Member account IAM roles via StackSet** -- Deploys a CloudFormation StackSet using the `SERVICE_MANAGED` permission model to automatically create the same IAM role in all member accounts within the specified Organizational Units.
3. **Illumio CloudSecure registration** -- Registers the management account with Illumio CloudSecure and optionally registers specified member accounts.
4. **Flow logs** -- Optionally registers an S3 bucket containing VPC flow logs.

## Prerequisites

- Terraform >= 1.7
- AWS provider >= 5.0
- An AWS Organization with CloudFormation StackSets enabled (trusted access for `member.org.stacksets.cloudformation.amazonaws.com`)
- Illumio CloudSecure tenant with a Service Account (OAuth 2 client ID and secret)
- The AWS provider must be configured with credentials for the **management account** (or a delegated administrator account)

## Usage

```hcl
module "illumio_org" {
  source = "path/to/aws/organization"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  organization_name     = "My Organization"
  target_ou_ids         = ["ou-abc1-23456789"]

  # Optional: register specific member accounts with Illumio
  member_account_ids = ["111111111111", "222222222222"]

  # Optional: flow logs
  flow_logs_s3_bucket_arn = "arn:aws:s3:::my-flow-logs-bucket"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Provider configuration

This module requires both the AWS and Illumio CloudSecure providers to be configured:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | Illumio CloudSecure OAuth 2 client ID (from Service Account). | `string` | n/a | yes |
| `illumio_client_secret` | Illumio CloudSecure OAuth 2 client secret (from Service Account). | `string` | n/a | yes |
| `organization_name` | Display name for the AWS Organization in Illumio CloudSecure. | `string` | n/a | yes |
| `target_ou_ids` | List of AWS Organization Unit IDs to deploy the IAM role StackSet to. | `list(string)` | n/a | yes |
| `mode` | Access mode: `"ReadWrite"` for policy enforcement, `"Read"` for visibility only. | `string` | `"ReadWrite"` | no |
| `role_name` | Name of the IAM role to create for Illumio CloudSecure. | `string` | `"IllumioCloudIntegrationRole"` | no |
| `illumio_aws_account_id` | Illumio's AWS account ID that will assume the cross-account role. | `string` | `"712001342241"` | no |
| `member_account_ids` | Optional set of member account IDs to register with Illumio CloudSecure. | `set(string)` | `[]` | no |
| `flow_logs_s3_bucket_arn` | Optional ARN of an S3 bucket containing VPC flow logs. | `string` | `""` | no |
| `stackset_failure_tolerance_percentage` | Percentage of accounts for which StackSet operations can fail. | `number` | `0` | no |
| `stackset_max_concurrent_percentage` | Maximum percentage of accounts for concurrent StackSet operations. | `number` | `100` | no |
| `tags` | Tags to apply to AWS resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `management_account_role_arn` | ARN of the IAM role created in the management account. |
| `management_account_id` | AWS management account ID that was onboarded. |
| `role_external_id` | External ID used for cross-account role assumption (sensitive). |
| `stack_set_id` | ID of the CloudFormation StackSet deploying roles to member accounts. |
| `illumio_management_account_id` | Illumio CloudSecure resource ID for the management account. |
| `illumio_member_account_ids` | Map of member account IDs to their Illumio CloudSecure resource IDs. |
| `organization_id` | AWS Organization ID. |

## Notes

- The StackSet uses the `SERVICE_MANAGED` permission model with `auto_deployment` enabled. New accounts added to the target OUs will automatically receive the IAM role.
- All accounts (management and members) share the same `ExternalId` for the trust policy. This is generated once by Terraform and passed to the StackSet as a parameter.
- Member accounts must be explicitly listed in `member_account_ids` to be registered with Illumio CloudSecure. The StackSet creates the IAM roles, but Illumio registration is a separate step.
- When accounts are removed from an OU, the StackSet will automatically clean up the IAM role (`retain_stacks_on_account_removal = false`).
