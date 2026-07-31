variable "billing_account_id" {
  description = "Billing account ID to associate with created projects; null creates projects without billing."
  type        = string
  default     = null
  nullable    = true
}

variable "organization_iam_members" {
  description = "Additive organization IAM memberships, grouped by role; this module manages only the listed role/member pairs."
  type        = map(set(string))
  default     = {}
}

variable "prevent_project_creation" {
  description = "When true, enforces an organization policy that prevents creation of new projects by organization members."
  type        = bool
  default     = true
}

variable "project_creators" {
  description = "Optional list of IAM principals such as 'group:team@example.com' or 'user:alice@example.com' granted roles/resourcemanager.projectCreator on the organization."
  type        = list(string)
  default     = []
}

variable "default_labels" {
  description = "Default labels applied to all created projects. Project-level labels from tfvars override these keys on conflict."
  type        = map(string)
  default     = {
    provisioned-by = "terraform"
  }
}

variable "organization_id" {
  description = "Numeric Google Cloud organization ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "organization_id must contain digits only."
  }
}

variable "projects" {
  description = "Projects to create, keyed by Google Cloud project ID."
  type = map(object({
    labels = optional(map(string), {})
    name   = string
  }))
  default = {
    foobar-dev = {
      labels = {
        environment = "dev"
      }
      name = "foobar-dev"
    }
  }

  validation {
    condition = alltrue([
      for project_id in keys(var.projects) : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project_id))
    ])
    error_message = "Each projects key must be a valid 6-30 character project ID: start with a lowercase letter, end with a lowercase letter or digit, and contain only lowercase letters, digits, or hyphens."
  }
}
