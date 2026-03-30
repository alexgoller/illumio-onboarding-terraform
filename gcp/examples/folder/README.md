# Example: GCP Folder Onboarding

Onboards a GCP folder into Illumio CloudSecure. See the [module documentation](../../folder/README.md) for full details.

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

- Google Cloud SDK authenticated with Folder Admin and Organization Role Admin permissions
- A GCP project for the service account
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Clean Up

```bash
terraform destroy
```

This removes the service account, folder-level IAM bindings, organization-level custom roles, and deregisters from CloudSecure.
