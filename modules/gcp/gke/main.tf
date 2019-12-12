
resource "google_project_service" "container-api" {
  project = var.project
  service = "container.googleapis.com"
}

resource "google_container_cluster" "gke-cluster" {
  provider = "google-beta"

  depends_on = ["google_project_service.container-api"]

  project            = var.project
  location             = var.location
  name               = "${var.environment}-gke"

  network          = var.network == "" ? "projects/${var.project}/global/networks/${var.environment}-vpc" : var.network
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
    network_policy_config {
      disabled = var.network_policy_config_disabled
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
      for_each = var.gke_master_authorized_networks
      content {
        cidr_block    = cidr_blocks.value.cidr_block
        display_name  = cidr_blocks.value.display_name
      }
    }
  }

  min_master_version = var.min_master_version

  network_policy {
    enabled = var.enable_network_policy
  }

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }

  remove_default_node_pool = true

  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
  }
}

resource "google_container_node_pool" "pools" {
  provider = "google-beta"
  project = var.project
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
    service_account = google_service_account.gke_service_account.email
    tags = ["gke-node"]

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
  }
  initial_node_count = lookup(var.gke_nodepools[count.index], "min_node_count")
  location = var.location
  version = lookup(var.gke_nodepools[count.index], "version")
  lifecycle {
    ignore_changes = [
      "initial_node_count",
      "name",
      "version",
      "node_config"
    ]
  }
}

resource "google_service_account" "gke_service_account" {
  project      = var.project
  account_id   = "${google_container_cluster.gke-cluster.name}-sa"
  display_name = "${google_container_cluster.gke-cluster.name} Service Account"
}

locals {
  all_service_account_roles = concat(var.service_account_roles, [
    "roles/logging.logWriter",
    "roles/monitoring.editor",
    "roles/cloudtrace.agent"
  ])
}

resource "google_project_iam_member" "service_account-roles" {
  for_each = toset(local.all_service_account_roles)

  project = var.project
  role    = each.value
  #Allow gke_service_account write access to Stackdriver Logging, Stackdriver Logging and Stackdriver Trace
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

resource "google_storage_bucket_iam_binding" "gke_cluster_members" {
  bucket = "artifacts.${var.project}.appspot.com"
  role = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${google_service_account.gke_service_account.email}",
  ]
}

resource "google_compute_firewall" "cert-manager-webhook-firewall" {
  name = "${var.region}-${var.environment}-cert-manager-webhook-firewall-rule"
  network = var.network == "" ? "projects/${var.project}/global/networks/${var.environment}-vpc" : var.network

  allow {
    protocol = "tcp"
    ports = ["6443"]
  }

  direction = "INGRESS"
  source_ranges = [
    var.master_ipv4_cidr_block
  ]
  target_tags = ["gke-node"]
}
