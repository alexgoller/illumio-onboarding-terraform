output "service_account_email" {
  description = "Email address of the created GCP service account."
  value       = google_service_account.illumio.email
}

output "service_account_id" {
  description = "Fully qualified ID of the created GCP service account."
  value       = google_service_account.illumio.id
}

output "illumio_resource_id" {
  description = "Illumio CloudSecure resource ID for this organization."
  value       = illumio-cloudsecure_gcp_project.this.id
}
