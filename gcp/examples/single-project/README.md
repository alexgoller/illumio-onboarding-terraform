# Example: Single GCP Project Onboarding

Onboards a single GCP project into Illumio CloudSecure. See the [module documentation](../../project/README.md) for full details.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

gcloud auth application-default login
terraform init
terraform plan
terraform apply
```

## Prerequisites

- Google Cloud SDK authenticated with project Owner or IAM Admin permissions
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Clean Up

```bash
terraform destroy
```

This removes the service account, IAM bindings, and deregisters from CloudSecure.
