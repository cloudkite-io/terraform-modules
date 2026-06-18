output "application_id" {
  description = "The resource ID of the Azure AD application (e.g. /applications/<object-id>)."
  value       = azuread_application.this.id
}

output "application_object_id" {
  description = "The object ID of the Azure AD application."
  value       = azuread_application.this.object_id
}

output "client_id" {
  description = "The client ID (application ID) of the service principal."
  value       = azuread_service_principal.this.client_id
}

output "object_id" {
  description = "The object ID of the service principal."
  value       = azuread_service_principal.this.object_id
}

output "client_secret" {
  description = "The generated client secret value, or null when no client secret was requested."
  value       = try(azuread_application_password.secret[0].value, null)
  sensitive   = true
}

output "client_secret_enabled" {
  description = "Whether a client secret was created for this service principal."
  value       = try(var.client_secret.enabled, false)
}
