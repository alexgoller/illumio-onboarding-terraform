# AWS Account Onboarding for Illumio CloudSecure

Creates an IAM cross-account role and registers a single AWS account with Illumio CloudSecure.

## Prerequisites

- **Terraform** >= 1.7
- **AWS provider** >= 5.0
- **Illumio CloudSecure provider** >= 1.7.0
- AWS credentials with permission to create IAM roles and policies
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Usage

```hcl
provider "aws" {
  region = "us-west-2"
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_aws" {
  # Use a local path, Git URL, or Terraform Registry source, e.g.:
  #   source = "../../aws/account"                                             # local path
  #   source = "git::https://github.com/<org>/illumio-onboarding-terraform.git//aws/account"  # Git
  source = "path/to/aws/account"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  account_name          = "Production AWS Account"
  mode                  = "ReadWrite"

  # Optional: register a flow logs bucket
  # flow_logs_s3_bucket_arn = "arn:aws:s3:::my-flow-logs-bucket"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | CloudSecure OAuth 2 client ID | `string` | — | yes |
| `illumio_client_secret` | CloudSecure OAuth 2 client secret | `string` | — | yes |
| `account_name` | Display name in CloudSecure | `string` | — | yes |
| `mode` | `"Read"` or `"ReadWrite"` | `string` | `"ReadWrite"` | no |
| `role_name` | Name of the IAM role to create | `string` | `"IllumioCloudIntegrationRole"` | no |
| `illumio_aws_account_id` | Illumio's AWS account ID for trust policy | `string` | `"712001342241"` | no |
| `flow_logs_s3_bucket_arn` | S3 bucket ARN for VPC flow logs | `string` | `""` | no |
| `tags` | Tags to apply to AWS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `role_arn` | ARN of the created IAM role | no |
| `role_external_id` | External ID for cross-account assumption | yes |
| `account_id` | AWS account ID that was onboarded | no |
| `illumio_account_id` | CloudSecure account resource ID | no |

## Resources Created

| Resource | Purpose |
|----------|---------|
| `aws_iam_role` | Cross-account role trusting Illumio's AWS account (`712001342241`) with ExternalId |
| `aws_iam_role_policy_attachment` | Attaches the `SecurityAudit` managed policy |
| `aws_iam_role_policy` (read) | Inline policy with read-only access to 60+ AWS services |
| `aws_iam_role_policy` (write) | Inline policy for security group and NACL management (ReadWrite mode only) |
| `illumio-cloudsecure_aws_account` | Registers the account with CloudSecure |
| `illumio-cloudsecure_aws_flow_logs_s3_bucket` | Registers flow log bucket (if provided) |

## Important Notes

- The **external ID** is auto-generated and stored in Terraform state. If you lose your state, you must destroy and re-create the integration.
- **Destroying** this module removes the IAM role and deregisters the account from CloudSecure. Any active enforcement rules will stop being applied.
