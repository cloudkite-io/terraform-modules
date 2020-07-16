output "network" {
  description = "A reference (self_link) to the VPC network"
  value       = google_compute_network.network.self_link
}

output "network_name" {
  description = "A reference (name) to the VPC network"
  value       = google_compute_network.network.name
}

# GKE Subnetwork Outputs

output "gke_subnetwork" {
  description = "A reference (self_link) to the private subnetwork"
  value       = google_compute_subnetwork.gke-subnetwork.self_link
}

output "gke_subnetwork_name" {
  description = "Name of the private subnetwork"
  value       = google_compute_subnetwork.gke-subnetwork.name
}

output "gke_subnetwork_cidr_block" {
  value = google_compute_subnetwork.gke-subnetwork.ip_cidr_range
}

output "gke_subnetwork_gateway" {
  value = google_compute_subnetwork.gke-subnetwork.gateway_address
}

output "gke_subnetwork_secondary_cidr_block_services" {
  value = google_compute_subnetwork.gke-subnetwork.secondary_ip_range[0].ip_cidr_range
}

output "gke_subnetwork_secondary_range_name_services" {
  value = google_compute_subnetwork.gke-subnetwork.secondary_ip_range[0].range_name
}

output "gke_subnetwork_secondary_cidr_block_pods" {
  value = google_compute_subnetwork.gke-subnetwork.secondary_ip_range[1].ip_cidr_range
}

output "gke_subnetwork_secondary_range_name_pods" {
  value = google_compute_subnetwork.gke-subnetwork.secondary_ip_range[1].range_name
}
