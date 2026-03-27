# -----------------------------------------------------------------------------
# Service Account (created in the designated project)
# -----------------------------------------------------------------------------

resource "google_service_account" "illumio" {
  project      = var.sa_project_id
  account_id   = var.sa_name
  display_name = var.sa_display_name
}

# -----------------------------------------------------------------------------
# Enable Required APIs in the SA project
# -----------------------------------------------------------------------------

resource "google_project_service" "iamcredentials" {
  project = var.sa_project_id
  service = "iamcredentials.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.sa_project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# Organization-Level Read-Only IAM Bindings
# -----------------------------------------------------------------------------

resource "google_organization_iam_member" "security_reviewer" {
  org_id = var.organization_id
  role   = "roles/iam.securityReviewer"
  member = "serviceAccount:${google_service_account.illumio.email}"
}

resource "google_organization_iam_member" "compute_viewer" {
  org_id = var.organization_id
  role   = "roles/compute.viewer"
  member = "serviceAccount:${google_service_account.illumio.email}"
}

resource "google_organization_iam_member" "cloudasset_viewer" {
  org_id = var.organization_id
  role   = "roles/cloudasset.viewer"
  member = "serviceAccount:${google_service_account.illumio.email}"
}

resource "google_organization_iam_member" "browser" {
  org_id = var.organization_id
  role   = "roles/browser"
  member = "serviceAccount:${google_service_account.illumio.email}"
}

# -----------------------------------------------------------------------------
# Service Account Impersonation
# -----------------------------------------------------------------------------

resource "google_service_account_iam_member" "token_creator" {
  service_account_id = google_service_account.illumio.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${var.illumio_sa_email}"
}

# -----------------------------------------------------------------------------
# API Enablement Custom Role (conditional)
# -----------------------------------------------------------------------------

resource "google_organization_iam_custom_role" "api_enablement" {
  count = var.enable_api_enablement ? 1 : 0

  org_id      = var.organization_id
  role_id     = "illumioCloudSecureApiEnablement"
  title       = "Illumio CloudSecure API Enablement"
  description = "Allows Illumio CloudSecure to enable required GCP APIs."
  permissions = [
    "serviceusage.services.enable",
    "serviceusage.services.list",
    "serviceusage.services.get",
  ]
}

resource "google_organization_iam_member" "api_enablement" {
  count = var.enable_api_enablement ? 1 : 0

  org_id = var.organization_id
  role   = google_organization_iam_custom_role.api_enablement[0].id
  member = "serviceAccount:${google_service_account.illumio.email}"
}

# -----------------------------------------------------------------------------
# ReadWrite Custom Role (conditional)
# -----------------------------------------------------------------------------

resource "google_organization_iam_custom_role" "readwrite" {
  count = var.mode == "ReadWrite" ? 1 : 0

  org_id      = var.organization_id
  role_id     = "illumioCloudSecureReadWrite"
  title       = "Illumio CloudSecure ReadWrite"
  description = "Allows Illumio CloudSecure to manage firewall rules."
  permissions = [
    "compute.firewalls.create",
    "compute.firewalls.delete",
    "compute.firewalls.get",
    "compute.firewalls.update",
    "compute.networks.updatePolicy",
  ]
}

resource "google_organization_iam_member" "readwrite" {
  count = var.mode == "ReadWrite" ? 1 : 0

  org_id = var.organization_id
  role   = google_organization_iam_custom_role.readwrite[0].id
  member = "serviceAccount:${google_service_account.illumio.email}"
}

# -----------------------------------------------------------------------------
# Illumio CloudSecure Resources
# -----------------------------------------------------------------------------

resource "illumio-cloudsecure_gcp_project" "this" {
  project_id            = var.sa_project_id
  name                  = var.organization_name
  organization_id       = "organizations/${var.organization_id}"
  mode                  = var.mode
  service_account_email = google_service_account.illumio.email

  depends_on = [
    google_project_service.iamcredentials,
    google_project_service.cloudresourcemanager,
    google_organization_iam_member.security_reviewer,
    google_organization_iam_member.compute_viewer,
    google_organization_iam_member.cloudasset_viewer,
    google_organization_iam_member.browser,
    google_service_account_iam_member.token_creator,
  ]
}

resource "illumio-cloudsecure_gcp_flow_logs_pubsub_topic" "this" {
  count = var.flow_logs_pubsub_topic_id != "" ? 1 : 0

  project_id      = var.sa_project_id
  pubsub_topic_id = var.flow_logs_pubsub_topic_id
}
