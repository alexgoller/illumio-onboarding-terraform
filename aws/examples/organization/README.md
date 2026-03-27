# Example: AWS Organization Onboarding

This example onboards an entire AWS Organization into Illumio CloudSecure by deploying IAM roles to all accounts in the specified Organizational Units.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

## Prerequisites

- AWS CLI configured with credentials for the **management account**
- Management account must have CloudFormation StackSets enabled with service-managed permissions
- Illumio CloudSecure service account credentials
