output "application_id" {
  description = "The Application (client) ID of the Azure AD application."
  value       = azuread_application.illumio.client_id
}

output "service_principal_id" {
  description = "The Object ID of the Azure AD service principal."
  value       = azuread_service_principal.illumio.object_id
}

output "client_secret" {
  description = "The client secret for the Azure AD application."
  value       = azuread_application_password.illumio.value
  sensitive   = true
}

output "illumio_subscription_ids" {
  description = "A map of Azure subscription IDs to their Illumio CloudSecure resource IDs."
  value       = { for k, v in illumio-cloudsecure_azure_subscription.this : k => v.id }
}
