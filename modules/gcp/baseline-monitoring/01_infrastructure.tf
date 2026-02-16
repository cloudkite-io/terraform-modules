# LOG-BASED METRICS (Iterated per project)
resource "google_logging_metric" "oom_events" {
  for_each = toset(var.monitored_project_ids)

  name    = "k8s_oom_events"
  project = each.value
  
  description = "Count of OOMKilled events from GKE containers"
  filter      = "resource.type=\"k8s_container\" AND textPayload:\"OOMKilled\""
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# INFRASTRUCTURE DASHBOARD
resource "google_monitoring_dashboard" "infrastructure_dashboard" {
  project      = var.infra_ops_project_id
  
  dashboard_json = <<EOF
{}
EOF
}
