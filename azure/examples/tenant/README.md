# Example: Azure Tenant Onboarding

Onboards an Azure tenant with multiple subscriptions into Illumio CloudSecure. See the [module documentation](../../tenant/README.md) for full details.

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
- Illumio CloudSecure service account credentials ([create here](https://console.illum.io/#/serviceAccounts))

## Clean Up

```bash
terraform destroy
```

This removes the AD application, role assignments at the management group scope, and deregisters all subscriptions from CloudSecure.
