# Example: AWS Organization Onboarding

Onboards an AWS Organization into Illumio CloudSecure via StackSets. See the [module documentation](../../organization/README.md) for full details.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

## Prerequisites

- AWS CLI configured with **management account** credentials
- CloudFormation StackSets trusted access enabled
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Clean Up

```bash
terraform destroy
```

This removes IAM roles from all member accounts (via StackSet deletion) and deregisters accounts from CloudSecure.
