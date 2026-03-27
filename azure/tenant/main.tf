###############################################################################
# Locals
###############################################################################

locals {
  management_group_scope = "/providers/Microsoft.Management/managementGroups/${var.tenant_id}"
}

###############################################################################
# Data Sources
###############################################################################

data "azurerm_client_config" "current" {}

###############################################################################
# Azure AD Application & Service Principal
###############################################################################

resource "azuread_application" "illumio" {
  display_name = var.app_name
  tags         = values(var.tags)
}

resource "azuread_service_principal" "illumio" {
  client_id = azuread_application.illumio.client_id
}

resource "azuread_application_password" "illumio" {
  application_id    = azuread_application.illumio.id
  end_date_relative = "${var.secret_expiration_days * 24}h"
}

###############################################################################
# Reader Role Assignment (Management Group scope)
###############################################################################

resource "azurerm_role_assignment" "reader" {
  scope                = local.management_group_scope
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.illumio.object_id
}

###############################################################################
# Firewall Administrator Custom Role (conditional)
###############################################################################

resource "azurerm_role_definition" "firewall_admin" {
  count = (var.enable_azfw_management || var.enable_nsg_management) ? 1 : 0

  name        = "Illumio Firewall Administrator-${var.tenant_id}"
  scope       = local.management_group_scope
  description = "Custom role for Illumio CloudSecure Azure Firewall administration."

  permissions {
    actions = [
      "Microsoft.Network/azurefirewalls/read",
      "Microsoft.Network/azurefirewalls/learnedIPPrefixes/action",
      "Microsoft.Network/azureFirewalls/applicationRuleCollections/write",
      "Microsoft.Network/azureFirewalls/applicationRuleCollections/delete",
      "Microsoft.Network/azureFirewalls/applicationRuleCollections/read",
      "Microsoft.Network/azurefirewalls/providers/Microsoft.Insights/logDefinitions/read",
      "Microsoft.Network/azureFirewalls/natRuleCollections/write",
      "Microsoft.Network/azureFirewalls/natRuleCollections/read",
      "Microsoft.Network/azureFirewalls/natRuleCollections/delete",
      "Microsoft.Network/azureFirewalls/networkRuleCollections/read",
      "Microsoft.Network/azureFirewalls/networkRuleCollections/write",
      "Microsoft.Network/azureFirewalls/networkRuleCollections/delete",
      "Microsoft.Network/azureFirewallFqdnTags/read",
      "Microsoft.Network/azurefirewalls/providers/Microsoft.Insights/metricDefinitions/read",
      "Microsoft.Network/firewallPolicies/read",
      "Microsoft.Network/firewallPolicies/write",
      "Microsoft.Network/firewallPolicies/join/action",
      "Microsoft.Network/firewallPolicies/certificates/action",
      "Microsoft.Network/firewallPolicies/delete",
      "Microsoft.Network/firewallPolicies/ruleCollectionGroups/read",
      "Microsoft.Network/firewallPolicies/ruleCollectionGroups/write",
      "Microsoft.Network/firewallPolicies/ruleCollectionGroups/delete",
      "Microsoft.Network/firewallPolicies/ruleGroups/read",
      "Microsoft.Network/firewallPolicies/ruleGroups/write",
      "Microsoft.Network/firewallPolicies/ruleGroups/delete",
      "Microsoft.Network/ipGroups/read",
      "Microsoft.Network/ipGroups/write",
      "Microsoft.Network/ipGroups/validate/action",
      "Microsoft.Network/ipGroups/updateReferences/action",
      "Microsoft.Network/ipGroups/join/action",
      "Microsoft.Network/ipGroups/delete",
    ]
  }

  assignable_scopes = [
    local.management_group_scope,
  ]
}

resource "azurerm_role_assignment" "firewall_admin" {
  count = (var.enable_azfw_management || var.enable_nsg_management) ? 1 : 0

  scope              = local.management_group_scope
  role_definition_id = azurerm_role_definition.firewall_admin[0].role_definition_resource_id
  principal_id       = azuread_service_principal.illumio.object_id
}

###############################################################################
# Network Security Administrator Custom Role (conditional)
###############################################################################

resource "azurerm_role_definition" "nsg_admin" {
  count = var.enable_nsg_management ? 1 : 0

  name        = "Illumio Network Security Administrator-${var.tenant_id}"
  scope       = local.management_group_scope
  description = "Custom role for Illumio CloudSecure Network Security Group administration."

  permissions {
    actions = [
      "Microsoft.Network/networkInterfaces/effectiveNetworkSecurityGroups/action",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/write",
      "Microsoft.Network/networkSecurityGroups/delete",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/networkSecurityGroups/defaultSecurityRules/read",
      "Microsoft.Network/networkSecurityGroups/securityRules/write",
      "Microsoft.Network/networkSecurityGroups/securityRules/delete",
      "Microsoft.Network/networksecuritygroups/providers/Microsoft.Insights/diagnosticSettings/read",
      "Microsoft.Network/networksecuritygroups/providers/Microsoft.Insights/diagnosticSettings/write",
      "Microsoft.Network/networksecuritygroups/providers/Microsoft.Insights/logDefinitions/read",
      "Microsoft.Network/networkWatchers/securityGroupView/action",
      "Microsoft.Network/networkSecurityGroups/*",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/write",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Authorization/locks/*",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/join/action",
    ]
  }

  assignable_scopes = [
    local.management_group_scope,
  ]
}

resource "azurerm_role_assignment" "nsg_admin" {
  count = var.enable_nsg_management ? 1 : 0

  scope              = local.management_group_scope
  role_definition_id = azurerm_role_definition.nsg_admin[0].role_definition_resource_id
  principal_id       = azuread_service_principal.illumio.object_id
}

###############################################################################
# Flow Logs Storage Account Role Assignments (conditional)
###############################################################################

resource "azurerm_role_assignment" "flow_logs_reader" {
  for_each = toset(var.flow_logs_storage_account_ids)

  scope                = each.value
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.illumio.object_id
}

###############################################################################
# Illumio CloudSecure Subscription Registrations (per subscription)
###############################################################################

resource "illumio-cloudsecure_azure_subscription" "this" {
  for_each = toset(var.subscription_ids)

  subscription_id = each.value
  name            = "${var.tenant_name}-${each.value}"
  mode            = var.mode
  client_id       = azuread_application.illumio.client_id
  client_secret   = azuread_application_password.illumio.value
  tenant_id       = var.tenant_id

  depends_on = [
    azurerm_role_assignment.reader,
    azurerm_role_assignment.firewall_admin,
    azurerm_role_assignment.nsg_admin,
  ]
}

###############################################################################
# Illumio CloudSecure Flow Logs Storage Accounts (conditional)
###############################################################################

resource "illumio-cloudsecure_azure_flow_logs_storage_account" "this" {
  for_each = toset(var.flow_logs_storage_account_ids)

  # Use the first subscription registration for flow logs association
  subscription_id             = var.subscription_ids[0]
  storage_account_resource_id = each.value
}
