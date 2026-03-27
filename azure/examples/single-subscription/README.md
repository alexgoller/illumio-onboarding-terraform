# Example: Single Azure Subscription Onboarding

This example onboards a single Azure subscription into Illumio CloudSecure.

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

- Azure CLI authenticated with Owner or User Access Administrator role on the subscription
- Illumio CloudSecure service account credentials
