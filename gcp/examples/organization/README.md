# Example: GCP Organization Onboarding

Onboards a GCP organization into Illumio CloudSecure. See the [module documentation](../../organization/README.md) for full details.

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

- Google Cloud SDK authenticated with Organization Admin permissions
- A GCP project for the service account (can be any project in the org)
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Clean Up

```bash
terraform destroy
```

This removes the service account, organization-level IAM bindings, and deregisters from CloudSecure.
