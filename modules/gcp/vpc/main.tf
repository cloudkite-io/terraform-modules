resource "google_compute_network" "network" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
  project                 = var.project
}

resource "google_compute_subnetwork" "gke-subnetwork" {
  name                     = "${var.region}-gke"
  ip_cidr_range            = "${var.network-prefix}.0.0/19"
  region                   = var.region
  private_ip_google_access = "true"
  network                  = google_compute_network.network.name
  project                  = var.project

  secondary_ip_range = [
    {
      range_name          = "${var.region}-gke-services"
      ip_cidr_range       = "${var.network-prefix}.32.0/19"
    },
    {
      range_name          = "${var.region}-gke-pods"
      ip_cidr_range       = "${var.network-prefix}.128.0/17"
    }
  ]
}

resource "google_compute_address" "nat-address" {
  count   = 2
  project = var.project
  name    = "nat-external-address-${count.index}"
  region  = google_compute_subnetwork.gke-subnetwork.region
}

resource "google_compute_router" "router" {
  project = var.project
  name    = "${var.region}-${var.environment}-router"
  region  = google_compute_subnetwork.gke-subnetwork.region
  network = google_compute_network.network.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.region}-${var.environment}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.nat-address.*.self_link
}
