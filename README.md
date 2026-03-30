# Illumio CloudSecure Terraform Onboarding

Terraform modules for onboarding AWS, Azure, and GCP cloud accounts into [Illumio CloudSecure](https://www.illumio.com/products/cloudsecure). Each module creates the required cloud-provider resources (IAM roles, service accounts, AD app registrations) **and** registers them with CloudSecure in a single `terraform apply`.

## Motivation

Cloud teams expect Infrastructure as Code. This repo replaces the previous mix of CloudFormation templates, PowerShell scripts, and bash scripts with a consistent, auditable Terraform workflow across all three CSPs.

## Repository Structure

```
.
├── aws/
│   ├── account/            Single AWS account
│   ├── organization/       AWS Organization (StackSet-based)
│   └── examples/
├── azure/
│   ├── subscription/       Single Azure subscription
│   ├── tenant/             Azure tenant (multi-subscription)
│   └── examples/
├── gcp/
│   ├── project/            Single GCP project
│   ├── organization/       GCP organization
│   ├── folder/             GCP folder
│   └── examples/
└── archive/                Original scripts for reference
```

## Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.7
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))
- Cloud provider CLI authenticated with sufficient permissions (see each module's README)

### AWS

```bash
cd aws/examples/single-account
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init && terraform apply
```

### Azure

```bash
cd azure/examples/single-subscription
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
az login
terraform init && terraform apply
```

### GCP

```bash
cd gcp/examples/single-project
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
gcloud auth application-default login
terraform init && terraform apply
```

## Modules

| Module | Scope | Documentation |
|--------|-------|---------------|
| [`aws/account`](aws/account/) | Single AWS account | [README](aws/account/README.md) |
| [`aws/organization`](aws/organization/) | AWS Organization via StackSets | [README](aws/organization/README.md) |
| [`azure/subscription`](azure/subscription/) | Single Azure subscription | [README](azure/subscription/README.md) |
| [`azure/tenant`](azure/tenant/) | Azure tenant (multiple subscriptions) | [README](azure/tenant/README.md) |
| [`gcp/project`](gcp/project/) | Single GCP project | [README](gcp/project/README.md) |
| [`gcp/organization`](gcp/organization/) | GCP organization | [README](gcp/organization/README.md) |
| [`gcp/folder`](gcp/folder/) | GCP folder | [README](gcp/folder/README.md) |

## Access Modes

All modules support two modes via the `mode` variable:

| Mode | Behavior |
|------|----------|
| `Read` | Visibility only. CloudSecure discovers and inventories cloud resources but cannot modify them. |
| `ReadWrite` | Policy enforcement. CloudSecure can manage security groups (AWS), firewall rules (GCP), and — when separately enabled — NSGs and Azure Firewall (Azure). |

> **Azure note:** Setting `mode = "ReadWrite"` alone only registers the subscription in read-write mode with CloudSecure. To grant actual write permissions for NSGs or Azure Firewall, you must also set `enable_nsg_management = true` and/or `enable_azfw_management = true`. See the [Azure subscription README](azure/subscription/README.md) for details.

## Flow Logs

Each CSP has a different flow log mechanism. All modules support optional flow log configuration:

| CSP | Variable | Backend |
|-----|----------|---------|
| AWS | `flow_logs_s3_bucket_arn` | S3 bucket |
| Azure | `flow_logs_storage_account_ids` | Storage accounts |
| GCP | `flow_logs_pubsub_topic_id` | Pub/Sub topic |

## Providers

| Provider | Source | Min Version |
|----------|--------|-------------|
| [illumio-cloudsecure](https://registry.terraform.io/providers/illumio/illumio-cloudsecure/latest) | `illumio/illumio-cloudsecure` | >= 1.7.0 |
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | `hashicorp/aws` | >= 5.0 |
| [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | `hashicorp/azurerm` | >= 3.0 |
| [azuread](https://registry.terraform.io/providers/hashicorp/azuread/latest) | `hashicorp/azuread` | >= 2.0 |
| [google](https://registry.terraform.io/providers/hashicorp/google/latest) | `hashicorp/google` | >= 5.0 |

> **Azure modules** require both `azurerm` and `azuread` providers to be configured.

## Security

- All credential variables (`illumio_client_id`, `illumio_client_secret`, Azure client secrets, IAM external IDs) are marked `sensitive` and will not appear in plan output.
- Use environment variables to avoid storing credentials in files:
  ```bash
  export TF_VAR_illumio_client_id="your-client-id"
  export TF_VAR_illumio_client_secret="your-client-secret"
  ```
- Never commit `terraform.tfvars` files. Only `.tfvars.example` files are tracked in git.
- Use a [remote backend](https://developer.hashicorp.com/terraform/language/settings/backends) with encryption for state files, which contain sensitive values.

## Destroy Behavior

Running `terraform destroy` on any module will:

1. **Remove IAM roles / service principals / service accounts** from your cloud provider
2. **Deregister the account** from Illumio CloudSecure

This means CloudSecure **immediately loses visibility and enforcement** for that account. Any active security policies enforced by CloudSecure will stop being applied. This operation is not easily reversible — you would need to re-run `terraform apply` to re-onboard.

> **Azure:** The AD application and its client secret are deleted on destroy. If other systems depend on that application, use `lifecycle { prevent_destroy = true }` on the `azuread_application` resource.

## State Management

Terraform state for these modules contains sensitive values (IAM external IDs, Azure client secrets). Recommendations:

- Use a remote backend with encryption (S3 + DynamoDB, Azure Storage, GCS)
- Enable state locking to prevent concurrent modifications
- Restrict access to the state backend to the same team that manages cloud security
- **Do not lose your state file** — the AWS IAM external ID and Azure client secrets are generated during apply and cannot be recovered without re-creating the resources
