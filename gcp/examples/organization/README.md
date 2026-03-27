# Example: GCP Organization Onboarding

This example onboards an entire GCP organization into Illumio CloudSecure.

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
- Illumio CloudSecure service account credentials
