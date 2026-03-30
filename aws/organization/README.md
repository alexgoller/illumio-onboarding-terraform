# AWS Organization Onboarding for Illumio CloudSecure

Onboards an entire AWS Organization by creating IAM roles in the management account and all member accounts (via CloudFormation StackSets), then registering them with Illumio CloudSecure.

## How It Works

1. **Management account** — Creates an IAM role directly via Terraform with read (and optionally write) policies.
2. **Member accounts** — Deploys a CloudFormation StackSet (`SERVICE_MANAGED`) that creates the same IAM role in all accounts within the target OUs. New accounts added to those OUs are automatically onboarded.
3. **CloudSecure registration** — Registers the management account and any explicitly listed member accounts with Illumio CloudSecure.
4. **Flow logs** — Optionally registers an S3 bucket for VPC flow logs.

## Prerequisites

- **Terraform** >= 1.7
- **AWS provider** >= 5.0
- **Illumio CloudSecure provider** >= 1.7.0
- AWS credentials for the **management account** (or a delegated StackSet administrator)
- CloudFormation StackSets trusted access enabled (`member.org.stacksets.cloudformation.amazonaws.com`)
- Illumio CloudSecure service account credentials

## Usage

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_org" {
  source = "path/to/aws/organization"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  organization_name     = "My Organization"
  target_ou_ids         = ["ou-abc1-23456789"]

  # Optional: register specific member accounts with CloudSecure
  member_account_ids = ["111111111111", "222222222222"]

  # Optional: flow logs
  # flow_logs_s3_bucket_arn = "arn:aws:s3:::my-flow-logs-bucket"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | CloudSecure OAuth 2 client ID | `string` | — | yes |
| `illumio_client_secret` | CloudSecure OAuth 2 client secret | `string` | — | yes |
| `organization_name` | Display name in CloudSecure | `string` | — | yes |
| `target_ou_ids` | OU IDs to deploy the StackSet to | `list(string)` | — | yes |
| `mode` | `"Read"` or `"ReadWrite"` | `string` | `"ReadWrite"` | no |
| `role_name` | IAM role name | `string` | `"IllumioCloudIntegrationRole"` | no |
| `illumio_aws_account_id` | Illumio's AWS account ID for trust policy | `string` | `"712001342241"` | no |
| `member_account_ids` | Member accounts to register with CloudSecure | `set(string)` | `[]` | no |
| `flow_logs_s3_bucket_arn` | S3 bucket ARN for VPC flow logs | `string` | `""` | no |
| `stackset_failure_tolerance_percentage` | % of accounts allowed to fail | `number` | `0` | no |
| `stackset_max_concurrent_percentage` | Max % of concurrent operations | `number` | `100` | no |
| `tags` | Tags for AWS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `management_account_role_arn` | ARN of the IAM role in the management account | no |
| `management_account_id` | Management account ID | no |
| `role_external_id` | External ID for cross-account assumption | yes |
| `stack_set_id` | CloudFormation StackSet ID | no |
| `illumio_management_account_id` | CloudSecure resource ID for management account | no |
| `illumio_member_account_ids` | Map of member account IDs to CloudSecure resource IDs | no |
| `organization_id` | AWS Organization ID | no |

## Important Notes

- **Auto-deployment**: The StackSet uses `SERVICE_MANAGED` permissions with auto-deployment enabled. New accounts in the target OUs automatically receive the IAM role.
- **Shared ExternalId**: All accounts (management + members) share the same ExternalId, generated once by Terraform.
- **Member registration is explicit**: The StackSet creates IAM roles automatically, but you must list accounts in `member_account_ids` for them to be registered with CloudSecure.
- **StackSet timing**: Deploying to many accounts can take several minutes. If Terraform times out, re-run `terraform apply` — the StackSet operation continues in the background.
- **Destroy behavior**: Destroying removes the StackSet (which removes IAM roles from all member accounts), the management account role, and all CloudSecure registrations. `retain_stacks_on_account_removal` is set to `false`.
