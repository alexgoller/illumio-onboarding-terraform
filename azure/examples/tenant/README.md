# Example: Azure Tenant Onboarding

This example onboards an Azure tenant into Illumio CloudSecure, registering multiple subscriptions under a single AD App Registration.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

az login
terraform init
terraform plan
terraform apply
```

## Prerequisites

- Azure CLI authenticated with Owner or User Access Administrator role on the tenant root management group
- Illumio CloudSecure service account credentials
