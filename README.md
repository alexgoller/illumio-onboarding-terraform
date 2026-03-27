# Illumio CloudSecure Terraform Onboarding

Terraform modules for onboarding AWS, Azure, and GCP cloud accounts into [Illumio CloudSecure](https://www.illumio.com/products/cloudsecure). Each module creates the required cloud-provider resources (IAM roles, service accounts, AD app registrations) and registers them with Illumio CloudSecure in a single `terraform apply`.

## Why Terraform?

Cloud teams prefer Infrastructure as Code over shell scripts, PowerShell, or CloudFormation. This repo replaces the previous mix of onboarding tools with a consistent, auditable, and repeatable Terraform workflow.

## Repository Structure

```
.
├── aws/
│   ├── account/          # Single AWS account onboarding
│   ├── organization/     # AWS Organization onboarding (StackSet-based)
│   └── examples/
├── azure/
│   ├── subscription/     # Single Azure subscription onboarding
│   ├── tenant/           # Azure tenant-level onboarding
│   └── examples/
├── gcp/
│   ├── project/          # Single GCP project onboarding
│   ├── organization/     # GCP organization-level onboarding
│   ├── folder/           # GCP folder-level onboarding
│   └── examples/
└── archive/              # Original scripts (CloudFormation, PowerShell, bash)
```

## Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.7
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))
- Cloud provider CLI authenticated with appropriate permissions

### AWS Account

```bash
cd aws/examples/single-account
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials
terraform init && terraform apply
```

### Azure Subscription

```bash
cd azure/examples/single-subscription
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials
az login
terraform init && terraform apply
```

### GCP Project

```bash
cd gcp/examples/single-project
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials
gcloud auth application-default login
terraform init && terraform apply
```

## Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| [aws/account](aws/account/) | Onboard a single AWS account | [README](aws/account/README.md) |
| [aws/organization](aws/organization/) | Onboard an AWS Organization via StackSets | [README](aws/organization/README.md) |
| [azure/subscription](azure/subscription/) | Onboard a single Azure subscription | [README](azure/subscription/README.md) |
| [azure/tenant](azure/tenant/) | Onboard an Azure tenant (multiple subscriptions) | [README](azure/tenant/README.md) |
| [gcp/project](gcp/project/) | Onboard a single GCP project | [README](gcp/project/README.md) |
| [gcp/organization](gcp/organization/) | Onboard a GCP organization | [README](gcp/organization/README.md) |
| [gcp/folder](gcp/folder/) | Onboard a GCP folder | [README](gcp/folder/README.md) |

## Access Modes

All modules support two access modes via the `mode` variable:

- **`Read`** — Visibility only. Illumio can discover and inventory cloud resources but cannot modify them.
- **`ReadWrite`** (default) — Full policy enforcement. Illumio can manage security groups (AWS), NSGs/Azure Firewall (Azure), and firewall rules (GCP).

## Flow Logs

Each module supports optional flow log configuration:

- **AWS**: Provide an S3 bucket ARN via `flow_logs_s3_bucket_arn`
- **Azure**: Provide storage account resource IDs via `flow_logs_storage_account_ids`
- **GCP**: Provide a Pub/Sub topic ID via `flow_logs_pubsub_topic_id`

## Security

- IAM credentials (client secrets, external IDs) are marked as `sensitive` in Terraform and will not appear in plan output
- Use environment variables (`TF_VAR_illumio_client_id`, `TF_VAR_illumio_client_secret`) to avoid storing credentials in tfvars files
- Never commit `terraform.tfvars` files — only `.tfvars.example` files are tracked in git

## Providers

This project uses the following Terraform providers:

| Provider | Registry |
|----------|----------|
| [illumio-cloudsecure](https://registry.terraform.io/providers/illumio/illumio-cloudsecure/latest) | `illumio/illumio-cloudsecure` |
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | `hashicorp/aws` |
| [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | `hashicorp/azurerm` |
| [azuread](https://registry.terraform.io/providers/hashicorp/azuread/latest) | `hashicorp/azuread` |
| [google](https://registry.terraform.io/providers/hashicorp/google/latest) | `hashicorp/google` |
