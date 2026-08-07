variable "display_name" {
  description = "Display name of the Azure AD application / service principal. Must be unique within the tenant."
  type        = string
}

variable "description" {
  description = "Description of the Azure AD application and service principal."
  type        = string
  default     = ""
}

variable "sign_in_audience" {
  description = "The Microsoft account types that are supported for the application. Use 'AzureADMultipleOrgs' for multi-tenant SPs."
  type        = string
  default     = "AzureADMyOrg"
}

variable "app_role_assignment_required" {
  description = "Whether users/groups need explicit app role assignment to sign in to this enterprise app."
  type        = bool
  default     = false
}

variable "requested_access_token_version" {
  description = "Optional access token version for the api block. Required to be 2 for personal Microsoft account audiences."
  type        = number
  default     = null
}

variable "owners" {
  description = "List of already-resolved object IDs that own the application and service principal."
  type        = list(string)
  default     = []
}

variable "github_federations" {
  description = <<-EOT
    GitHub Actions OIDC federated credentials. The issuer is fixed to GitHub.
    The map key is used to build a unique credential display name ("github-<key>").
    `subject` is the GitHub OIDC subject, e.g. "repo:Over-haul/my-repo" or "repository_owner:Over-haul".
  EOT
  type = map(object({
    subject = string
  }))
  default = {}
}

variable "gitlab_federations" {
  description = <<-EOT
    GitLab CI/CD OIDC federated credentials. Defaults to GitLab.com; override `issuer` for self-hosted.
    The map key is used to build a unique credential display name ("gitlab-<key>").
    `subject` is the GitLab OIDC subject, e.g. "project_path:group/project:ref_type:branch:ref:main".
    NOTE: Azure AD matches the subject exactly (no wildcards); one entry per ref you want to trust.
  EOT
  type = map(object({
    subject  = string
    issuer   = optional(string, "https://gitlab.com")
    audience = optional(string, "api://AzureADTokenExchange")
  }))
  default = {}
}

variable "kubernetes_federations" {
  description = <<-EOT
    Kubernetes workload-identity federated credentials. The issuer is the cluster OIDC URL.
    The map key is used to build a unique credential display name ("k8s-<key>").
    The subject is derived as "system:serviceaccount:<namespace>:<serviceaccount>".
  EOT
  type = map(object({
    cluster_oidc_url = string
    namespace        = string
    serviceaccount   = string
    display_name     = optional(string, null)
  }))
  default = {}
}

variable "oidc_federations" {
  description = <<-EOT
    Generic OIDC federated credentials escape hatch for arbitrary issuers (Bitbucket, CircleCI, etc.).
    The map key is used to build a unique credential display name ("oidc-<key>").
  EOT
  type = map(object({
    issuer    = string
    subject   = string
    audiences = optional(list(string), ["api://AzureADTokenExchange"])
  }))
  default = {}
}

variable "flexible_federations" {
  description = <<-EOT
    Flexible federated identity credentials using wildcard/expression matching
    (azuread_application_flexible_federated_identity_credential, requires azuread >= 3.7.0).
    The map key is used to build a unique credential display name ("flex-<key>").

    `claims_matching_expression` is an Entra expression language string evaluated against
    incoming token claims. Only `sub` is matchable for GitLab; GitHub also supports
    `job_workflow_ref`. Operators: `matches` (supports `*` and `?` wildcards), `eq`, `and`.

    Supported issuers: GitHub, GitLab (including self-hosted), Terraform Cloud only.
    Kubernetes and arbitrary OIDC issuers are NOT supported by flexible FICs; use the
    exact-match `kubernetes_federations` or `oidc_federations` inputs for those.

    NOTE: `flexible_federations` and the exact-match federation inputs are complementary
    and can be combined on the same SP (total FIC cap: 20 per application).

    Example expressions:
      GitLab — all branches of a repo:
        "claims['sub'] matches 'project_path:over-haul/my-repo:ref_type:branch:ref:*'"
      GitHub — all branches of a repo:
        "claims['sub'] matches 'repo:Over-haul/my-repo:ref:refs/heads/*'"
      GitHub — all PRs:
        "claims['sub'] matches 'repo:Over-haul/my-repo:pull_request'"
      GitHub — branch wildcard AND reusable workflow restriction:
        "claims['sub'] matches 'repo:Over-haul/my-repo:ref:refs/heads/*' and claims['job_workflow_ref'] matches 'Over-haul/my-repo/.github/workflows/*.yml@refs/heads/main'"
  EOT
  type = map(object({
    issuer                     = string
    claims_matching_expression = string
    audience                   = optional(string, "api://AzureADTokenExchange")
    description                = optional(string, "")
  }))
  default = {}
}

variable "client_secret" {
  description = <<-EOT
    Optional rotating client secret (M2M), e.g. for Databricks access.
    When `enabled` is true a password is created and rotated every `rotation_days`.
    The module exposes the secret as an output; storing it in Key Vault is the caller's responsibility.
  EOT
  type = object({
    enabled       = optional(bool, false)
    rotation_days = optional(number, 730)
  })
  default = {}
}

variable "web" {
  description = "Optional web configuration for the application (homepage, redirect URIs, implicit grant)."
  type = object({
    homepage_url  = optional(string, null)
    logout_url    = optional(string, null)
    redirect_uris = optional(list(string), [])
    implicit_grant = optional(object({
      access_token_issuance_enabled = optional(bool, null)
      id_token_issuance_enabled     = optional(bool, null)
    }), null)
  })
  default = null
}

variable "resource_app_id" {
  description = "Optional resource app ID for required_resource_access (e.g. Microsoft Graph for multi-tenant SPs)."
  type        = string
  default     = ""
}

variable "resource_access" {
  description = "Optional list of resource_access entries to pair with resource_app_id."
  type = list(object({
    id   = string
    type = string
  }))
  default = []
}
