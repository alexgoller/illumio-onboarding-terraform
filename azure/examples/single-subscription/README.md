# Example: Single Azure Subscription Onboarding

Onboards a single Azure subscription into Illumio CloudSecure. See the [module documentation](../../subscription/README.md) for full details.

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
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Clean Up

```bash
terraform destroy
```

This removes the AD application, service principal, role assignments, and deregisters from CloudSecure.
