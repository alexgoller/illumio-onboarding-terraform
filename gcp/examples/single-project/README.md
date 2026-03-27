# Example: Single GCP Project Onboarding

This example onboards a single GCP project into Illumio CloudSecure.

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
- Illumio CloudSecure service account credentials
