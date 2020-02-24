# Create the velero backups bucket
resource "google_storage_bucket" "backups" {
  name = var.backups_bucket_name
  location = var.backups_bucket_location
}

# Create a service account for Velero
resource "google_service_account" "velero-service-account" {
  project      = var.project
  account_id   = var.service_account_name
  display_name = "Velero Service Account"
}

# Grant full control over objects, including listing, creating, viewing, and deleting storage objects in bucket.
resource "google_storage_bucket_iam_member" "editor" {
  bucket = google_storage_bucket.backups.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.velero-service-account.email}"
}

# Allow Velero to make GCP API calls for Disks
resource "google_project_iam_custom_role" "velero-server" {
  role_id     = "velero.server"
  title       = "Velero Server Custom Role"
  description = "This role allows Velero to make GCP API calls for Disks"
  permissions = [
    "compute.disks.get",
    "compute.disks.create",
    "compute.disks.createSnapshot",
    "compute.snapshots.get",
    "compute.snapshots.create",
    "compute.snapshots.useReadOnly",
    "compute.snapshots.delete",
    "compute.zones.get",
  ]
}

# Add velero.server role to velero sa
resource "google_project_iam_binding" "velero-sa-binding" {
  project = var.project
  role = google_project_iam_custom_role.velero-server.id

  members = [
    "serviceAccount:${google_service_account.velero-service-account.email}",
  ]
}

# Grant to service accounts the permission to sign urls for the GCP bucket
resource "google_project_iam_custom_role" "blob-signer" {
  role_id     = "blob.signer"
  title       = "Blob Signer Custom Role"
  description = "Grant to service accounts the permission to sign urls for the GCP bucket"
  permissions = ["iam.serviceAccounts.signBlob"]
}

# Add the blob-signer role to the service account
resource "google_project_iam_binding" "velero-blob-signer" {
  project = var.project
  role = google_project_iam_custom_role.blob-signer.id

  members = [
    "serviceAccount:${google_service_account.velero-service-account.email}",
  ]
}

# Create a relationship between the Kubernetes service account and the GCP service account
resource "google_service_account_iam_binding" "velero-sa-role-binding" {
  service_account_id = google_service_account.velero-service-account.name
  role  = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project}.svc.id.goog[velero/velero]"
  ]
}