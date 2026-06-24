variable "infra_ops_project_id" {
  description = "The ID of the central Infra-Ops project (e.g., cloudkite-infra-ops)"
  type        = string
}

variable "monitored_project_ids" {
  description = "List of project IDs to monitor (e.g., cloudkite-dev, cloudkite-prod)"
  type        = list(string)
}

# Link the projects (Metrics Scope)
resource "google_monitoring_monitored_project" "projects" {
  for_each = toset(var.monitored_project_ids)

  metrics_scope = var.infra_ops_project_id
  name          = each.value
}
