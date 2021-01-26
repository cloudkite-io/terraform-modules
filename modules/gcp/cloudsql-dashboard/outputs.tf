output "project_id" {
  value = var.project
}

output "resource_id" {
  description = "The resource id for the dashboard"
  value       = google_monitoring_dashboard.dashboard.id
}

output "console_link" {
  description = "The destination console URL for the dashboard."
  value       = join("", ["https://console.cloud.google.com/monitoring/dashboards/custom/",
                          element(split("/", google_monitoring_dashboard.dashboard.id), 3),
                          "?project=",
                          var.project])
}
