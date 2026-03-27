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

output "illumio_subscription_id" {
  description = "The Illumio CloudSecure subscription resource ID."
  value       = illumio-cloudsecure_azure_subscription.this.id
}
