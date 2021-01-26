// source https://github.com/GoogleCloudPlatform/monitoring-dashboard-samples/blob/master/terraform/main.tf
resource "google_project_service" "enable_destination_api" {
  project            = var.project
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = file(var.dashboard_json_file)
  project        = var.project
}