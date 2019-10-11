output "email" {
  description = "The email address of the custom gke service account."
  value       = google_service_account.velero_service_account.email
}

output "velero-sa-keyfile" {
  value = google_service_account_key.velero.private_key
}
