output "name" {
  description = "The name of the cluster master. This output is used for interpolation with node pools, other modules."

  value = google_container_cluster.gke-cluster.name
}

output "gke-sa" {
  value = google_service_account.gke_service_account.email
}
