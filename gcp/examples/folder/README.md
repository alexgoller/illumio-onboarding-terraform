# Example: GCP Folder Onboarding

This example onboards a GCP folder into Illumio CloudSecure, providing visibility and optional enforcement for all projects within the folder.

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
- A GCP project for the service account (can be any project in the org)
- Illumio CloudSecure service account credentials
