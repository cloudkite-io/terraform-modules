resource "google_project_service" "service" {
  for_each = var.services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
