resource "google_project_service" "container-api" {
  project = "${var.gcp["project"]}"
  service = "container.googleapis.com"
}

resource "google_container_cluster" "gke-cluster" {
  provider = "google-beta"

  depends_on = ["google_project_service.container-api"]

  project            = var.gcp["project"]
  location             = var.gke["location"]
  name               = "${var.environment}-gke"

  network          = var.network
  subnetwork       = var.subnetwork

  # Stackdriver
  logging_service = var.logging_service
  monitoring_service = var.monitoring_service

  # Disable kubernetes dashboard
  addons_config {
    horizontal_pod_autoscaling {
      disabled = ! var.horizontal_pod_autoscaling
    }
    http_load_balancing {
      disabled = ! var.http_load_balancing
    }
    kubernetes_dashboard {
      disabled = ! var.kubernetes_dashboard
    }
    network_policy_config {
      disabled = ! var.network_policy
    }
  }

  initial_node_count = 1

  ip_allocation_policy {
    cluster_secondary_range_name = var.gke_services_secondary_range_name
    services_secondary_range_name = var.gke_services_secondary_range_name
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "08:00"
    }
  }

  # Disable client cert (and implicitly disable basic auth)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
    username = ""
    password = ""
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks_config
      content {
        cidr_block    = cidr_blocks.value.cidr_block
        display_name  = cidr_blocks.value.display_name
      }
    }
  }

  min_master_version = "${var.gke["min_master_version"]}"

  network_policy {
    enabled = var.enable_network_policy
  }

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "${var.gke["master_ipv4_cidr_block"]}"
  }

  remove_default_node_pool = true
}

resource "google_container_node_pool" "pools" {
  project = var.gcp["project"]
  count = length(var.gke_nodepools)

  name = "${google_container_cluster.gke-cluster.name}-pool-${count.index}"
  cluster = google_container_cluster.gke-cluster.name
  depends_on = ["google_container_cluster.gke-cluster"]
  autoscaling {
    min_node_count = lookup(var.gke_nodepools[count.index], "min_node_count")
    max_node_count = lookup(var.gke_nodepools[count.index], "max_node_count")
  }
  management {
    auto_repair = lookup(var.gke_nodepools[count.index], "auto_repair")
    auto_upgrade = lookup(var.gke_nodepools[count.index], "auto_upgrade")
  }
  node_config {
    machine_type = lookup(var.gke_nodepools[count.index], "machine_type")
    disk_size_gb = lookup(var.gke_nodepools[count.index], "disk_size_gb")
    preemptible = lookup(var.gke_nodepools[count.index], "preemptible")
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    service_account = var.gke_service_account
  }
  initial_node_count = lookup(var.gke_nodepools[count.index], "min_node_count")
  location = var.gke["location"]
  version = lookup(var.gke_nodepools[count.index], "version")
  lifecycle {
    ignore_changes = [
      "initial_node_count",
      "version",
      "node_config"
    ]
  }
}

resource "google_compute_firewall" "cert-manager-admission-webhook" {
  depends_on = ["google_container_node_pool.pools"]

  name = "cert-manager-admission-webhook"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = [var.gke["master_ipv4_cidr_block"]]
  target_service_accounts = [var.gke_service_account]
}
