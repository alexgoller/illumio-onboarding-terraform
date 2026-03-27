# Example: Single AWS Account Onboarding

This example onboards a single AWS account into Illumio CloudSecure.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

## Prerequisites

- AWS CLI configured with credentials that have IAM admin permissions
- Illumio CloudSecure service account credentials
