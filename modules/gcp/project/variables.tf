variable "project_id" {
  description = "Existing Google Cloud project ID to configure."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid 6-30 character project ID: start with a lowercase letter, end with a lowercase letter or digit, and contain only lowercase letters, digits, or hyphens."
  }
}

variable "services" {
  description = "Google APIs to enable in the existing project."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for service in var.services : can(regex("^[a-z0-9.-]+\\.googleapis\\.com$", service))
    ])
    error_message = "Each service must be a Google API hostname ending in .googleapis.com and containing only lowercase letters, digits, dots, or hyphens."
  }
}
