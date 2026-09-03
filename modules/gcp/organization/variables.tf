variable "billing_account_id" {
  description = "Billing account ID to associate with created projects; null creates projects without billing."
  type        = string
  default     = null
  nullable    = true
}

variable "folder_creators" {
  description = "Principals granted roles/resourcemanager.folderCreator on the organization."
  type        = set(string)
  default     = []
}

variable "folders" {
  description = "Top-level organization folders, including additive IAM memberships, keyed by a stable identifier."
  type = map(object({
    display_name        = string
    deletion_protection = optional(bool, true)
    iam_members         = optional(map(set(string)), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for folder in keys(var.folders) : can(regex("^[a-z][a-z0-9_-]*$", folder))
    ])
    error_message = "Folder keys must start with a lowercase letter and contain only lowercase letters, digits, hyphens, or underscores."
  }

  validation {
    condition = alltrue([
      for folder in values(var.folders) :
      length(folder.display_name) >= 3 &&
      length(folder.display_name) <= 30 &&
      can(regex("^[A-Za-z0-9][A-Za-z0-9 _-]*[A-Za-z0-9]$", folder.display_name))
    ])
    error_message = "Folder display names must be 3-30 characters, start and end with a letter or digit, and contain only letters, digits, spaces, hyphens, or underscores."
  }

  validation {
    condition = length(distinct([
      for folder in values(var.folders) : folder.display_name
    ])) == length(var.folders)
    error_message = "Top-level folder display names must be unique within the organization."
  }

  validation {
    condition = alltrue(flatten([
      for folder in values(var.folders) : [
        for role in keys(folder.iam_members) :
        can(regex("^(roles/[A-Za-z0-9_.]+|organizations/[0-9]+/roles/[A-Za-z0-9_.]+)$", role))
      ]
    ]))
    error_message = "Folder IAM keys must be predefined roles or organization-level custom role resource names."
  }
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
  description = "Optional list of IAM principals such as 'group:team@example.com' or 'user:alice@example.com' granted roles/resourcemanager.projectCreator on the organization and, when billing_account_id is set, roles/billing.user on the billing account."
  type        = list(string)
  default     = []
}

variable "default_labels" {
  description = "Default labels applied to all created projects. Project-level labels from tfvars override these keys on conflict."
  type        = map(string)
  default = {
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
  description = "Projects keyed by Google Cloud project ID. Set folder to place a project in a managed folder; omit it to keep the project at the organization root."
  type = map(object({
    folder = optional(string)
    labels = optional(map(string), {})
    name   = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for project_id in keys(var.projects) : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project_id))
    ])
    error_message = "Each projects key must be a valid 6-30 character project ID: start with a lowercase letter, end with a lowercase letter or digit, and contain only lowercase letters, digits, or hyphens."
  }

  validation {
    condition = alltrue([
      for project in values(var.projects) :
      project.folder == null || contains(keys(var.folders), project.folder)
    ])
    error_message = "Each non-null project folder must identify a key in folders."
  }
}
