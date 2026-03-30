# Example: Single AWS Account Onboarding

Onboards a single AWS account into Illumio CloudSecure. See the [module documentation](../../account/README.md) for full details.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

## Prerequisites

- AWS CLI configured with IAM admin permissions
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Clean Up

```bash
terraform destroy
```

This removes the IAM role and deregisters the account from CloudSecure.
