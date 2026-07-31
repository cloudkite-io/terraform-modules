output "enabled_services" {
  description = "Sorted service names enabled by this module."
  value       = sort(keys(google_project_service.service))
}
