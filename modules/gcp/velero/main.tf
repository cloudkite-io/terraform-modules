# Create a service account for Velero
resource "google_service_account" "velero_service_account" {
  project      = var.project
  account_id   = var.name
  display_name = "Velero Service Account"
}

locals {
  all_service_account_roles = concat(var.service_account_roles, [
    "roles/storage.objectAdmin",
    "roles/compute.storageAdmin",
    "roles/iam.serviceAccountAdmin"
  ])
}

# Allow velero_service_account admin access to Google Cloud Storage and service accounts.
# The iam binding required between K8s SA and Google SA
# needs iam.serviceAccounts.setIamPolicy permission on the Google service account.
resource "google_project_iam_member" "service_account-roles" {
  for_each = toset(local.all_service_account_roles)

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.velero_service_account.email}"
}

# Allow the Kubernetes service account to use the Google service account
resource "google_service_account_iam_binding" "velero_service_iam_binding" {
  service_account_id = google_service_account.velero_service_account.name
  role  = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project}.svc.id.goog[velero/velero-server]"
  ]
}

# Create the velero backups bucket
resource "google_storage_bucket" "backups" {
  name = var.backups_bucket_name
  location = var.backups_bucket_location
}

resource "google_service_account_key" "velero" {
  service_account_id = google_service_account.velero_service_account.id
}
