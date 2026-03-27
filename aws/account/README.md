# AWS Account Onboarding for Illumio CloudSecure

This Terraform module onboards a single AWS account into Illumio CloudSecure. It creates the required cross-account IAM role and registers the account with CloudSecure in a single `terraform apply`.

## Prerequisites

- Terraform >= 1.7
- AWS credentials with IAM administrative permissions
- Illumio CloudSecure service account credentials (create at [console.illum.io](https://console.illum.io/#/serviceAccounts))

## Usage

```hcl
provider "aws" {
  region = "us-west-2"
}

provider "illumio-cloudsecure" {
  client_id     = var.illumio_client_id
  client_secret = var.illumio_client_secret
}

module "illumio_aws_account" {
  source = "../../aws/account"

  illumio_client_id     = var.illumio_client_id
  illumio_client_secret = var.illumio_client_secret
  account_name          = "Production AWS Account"
  mode                  = "ReadWrite"

  # Optional: flow logs
  # flow_logs_s3_bucket_arn = "arn:aws:s3:::my-flow-logs-bucket"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `illumio_client_id` | Illumio CloudSecure OAuth 2 client ID | `string` | - | yes |
| `illumio_client_secret` | Illumio CloudSecure OAuth 2 client secret | `string` | - | yes |
| `account_name` | Display name in CloudSecure | `string` | - | yes |
| `mode` | `"Read"` or `"ReadWrite"` | `string` | `"ReadWrite"` | no |
| `role_name` | IAM role name | `string` | `"IllumioCloudIntegrationRole"` | no |
| `illumio_aws_account_id` | Illumio's AWS account ID | `string` | `"712001342241"` | no |
| `flow_logs_s3_bucket_arn` | S3 bucket ARN for VPC flow logs | `string` | `""` | no |
| `tags` | Tags for AWS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | ARN of the IAM role created for Illumio CloudSecure |
| `role_external_id` | External ID for cross-account role assumption (sensitive) |
| `account_id` | AWS account ID that was onboarded |
| `illumio_account_id` | Illumio CloudSecure account resource ID |

## What Gets Created

- **IAM Role** (`IllumioCloudIntegrationRole`) — Cross-account role trusting Illumio's AWS account with ExternalId condition
- **SecurityAudit Policy** — AWS managed policy for broad read-only security visibility
- **Read-Only Inline Policy** — Additional read permissions for EC2, ECS, EKS, RDS, Lambda, CloudWatch, etc.
- **Write Inline Policy** (ReadWrite mode only) — Permissions to manage security groups and network ACLs
- **Illumio CloudSecure Registration** — Account registered with CloudSecure for monitoring/enforcement
