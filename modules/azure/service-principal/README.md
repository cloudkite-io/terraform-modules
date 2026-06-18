# Terraform Azure AD Service Principal

This Terraform module creates a unified, multi-purpose Azure AD service principal.

<!-- markdownlint-disable MD013 MD033 MD034 MD051 -->

A single identity can carry any combination of OIDC federated credentials (GitHub Actions,
GitLab CI, Kubernetes workload identity, or any arbitrary OIDC issuer) and an optional
rotating client secret, unifying what were previously three separate definitions into one
reusable building block.

Two credential types are supported:

- **Exact-match** (`github_federations`, `gitlab_federations`, `kubernetes_federations`,
  `oidc_federations`) — subject must match exactly; one entry per ref/branch/repo.
- **Flexible** (`flexible_federations`) — expression-based wildcard matching; one entry
  covers multiple branches, PRs, or repos. Requires azuread >= 3.7.0 and is a Microsoft
  Entra **preview** feature. Supported issuers: GitHub, GitLab, Terraform Cloud only.

The module does **not** write the client secret to Key Vault; it exposes the secret as an
output so the caller stores it through its own centralised Key Vault path.

```shell
module "service_principals" {
  # Pinned to commit <sha> (<date>) for stability. Update this comment with the PR/date when bumping.
  source   = "git@github.com:Over-haul/infrastructure.git//terraform/modules/azuread/service-principal?ref=<sha>"
  for_each = var.service_principals

  display_name           = each.value.display_name != "" ? each.value.display_name : each.key
  description            = each.value.description
  sign_in_audience       = each.value.sign_in_audience
  owners                 = [for owner in var.app_owners : var.identities_mapper[owner]]
  github_federations     = each.value.github_federations
  gitlab_federations     = each.value.gitlab_federations
  kubernetes_federations = each.value.kubernetes_federations
  oidc_federations       = each.value.oidc_federations
  flexible_federations   = each.value.flexible_federations
  web                    = each.value.web
  resource_app_id        = each.value.resource_app_id
  resource_access        = each.value.resource_access

  client_secret = {
    enabled       = each.value.client_secret.enabled
    rotation_days = each.value.client_secret.rotation_days
  }
}
```

Example `service_principals` variable value:

```hcl
service_principals = {
  # Exact subject on a single branch (works today, no special requirements)
  "release-bot-main" = {
    description        = "Deploys to prod from main only"
    github_federations = { gh = { subject = "repo:Over-haul/app:ref:refs/heads/main" } }
    gitlab_federations = { gl = { subject = "project_path:over-haul/app:ref_type:branch:ref:main" } }
    client_secret = {
      enabled                       = true
      store_in_key_vault            = true
      key_vault_name                = "dbw-oh-prod"
      key_vault_resource_group_name = "oh-analytics-prod"
    }
  }

  # Flexible FIC — all branches + all PRs without enumerating each one
  "ci-runner" = {
    description = "CI identity usable from any branch or PR in GitHub and GitLab"
    flexible_federations = {
      github-branches = {
        issuer                     = "https://token.actions.githubusercontent.com"
        claims_matching_expression = "claims['sub'] matches 'repo:Over-haul/app:ref:refs/heads/*'"
      }
      github-prs = {
        issuer                     = "https://token.actions.githubusercontent.com"
        claims_matching_expression = "claims['sub'] matches 'repo:Over-haul/app:pull_request'"
      }
      gitlab-branches = {
        issuer                     = "https://gitlab.com"
        claims_matching_expression = "claims['sub'] matches 'project_path:over-haul/app:ref_type:branch:ref:*'"
      }
    }
  }

  # All three exact federations, no secret
  "etl-runner-prod" = {
    description            = "ETL identity for AKS, GitHub, and GitLab"
    github_federations     = { deploy = { subject = "repo:Over-haul/etl" } }
    gitlab_federations     = { deploy = { subject = "project_path:over-haul/etl:ref_type:branch:ref:main" } }
    kubernetes_federations = {
      prod = {
        cluster_oidc_url = "https://<prod-aks-oidc-issuer-url>/"
        namespace        = "etl"
        serviceaccount   = "etl"
      }
    }
  }

  # Generic OIDC escape hatch (no module change needed for new issuers)
  "bitbucket-deployer" = {
    description = "Example arbitrary OIDC issuer"
    oidc_federations = {
      main = {
        issuer  = "https://api.bitbucket.org/2.0/workspaces/over-haul/pipelines-config/identity/oidc"
        subject = "{<bitbucket-subject>}"
      }
    }
  }
}
```

## Claims and subject reference

### GitHub — exact-match subjects (no provider upgrade required)

Azure AD evaluates the GitHub OIDC `sub` claim exactly as emitted. The claim format is
controlled by the repository's OIDC subject customisation template
(`github_actions_repository_oidc_subject_claim_customization_template` in `github.tf`).

| Subject value | Trusts |
| ------------- | ------ |
| `repo:Over-haul/REPO:ref:refs/heads/main` | `main` branch only |
| `repo:Over-haul/REPO:ref:refs/heads/BRANCH` | one specific branch |
| `repo:Over-haul/REPO:pull_request` | every PR-triggered run |
| `repo:Over-haul/REPO:environment:NAME` | runs targeting GitHub Environment `NAME` |
| `repo:Over-haul/REPO` | every run in the repo (requires template `include_claim_keys = ["repository"]`) |
| `repository_owner:Over-haul` | every repo in the org (already the org default in `github.tf`) |

### GitLab — exact-match subjects (no provider upgrade required)

GitLab's `sub` claim is always `project_path:GROUP/PROJECT:ref_type:TYPE:ref:REF` and
is not customisable. Each ref that needs trust requires its own entry.

| Subject value | Trusts |
| ------------- | ------ |
| `project_path:over-haul/REPO:ref_type:branch:ref:main` | `main` branch |
| `project_path:over-haul/REPO:ref_type:branch:ref:BRANCH` | one named branch |
| `project_path:over-haul/REPO:ref_type:tag:ref:v1.0.0` | one specific tag |

### Flexible FICs — wildcard expression matching (requires azuread >= 3.7.0)

Use `flexible_federations` when you need to trust multiple branches, PRs, or tags without
enumerating each one. Entra evaluates `claims_matching_expression` against the incoming token.

Supported issuers: `https://token.actions.githubusercontent.com` (GitHub),
`https://gitlab.com` (and self-hosted GitLab), `https://app.terraform.io`.
**Kubernetes and arbitrary OIDC issuers are not supported by flexible FICs.**

Supported claims and operators:

| Claim | Supported by | Operators |
| ----- | ------------ | --------- |
| `sub` | GitHub, GitLab, Terraform Cloud | `matches`, `eq` |
| `job_workflow_ref` | GitHub only | `matches`, `eq` |

Operators: `matches` (wildcards: `*` = any chars, `?` = one char), `eq` (exact), `and`.

Common expression patterns:

```text
# GitLab — all branches of a repo
claims['sub'] matches 'project_path:over-haul/REPO:ref_type:branch:ref:*'

# GitHub — all branches of a repo
claims['sub'] matches 'repo:Over-haul/REPO:ref:refs/heads/*'

# GitHub — all PRs
claims['sub'] matches 'repo:Over-haul/REPO:pull_request'

# GitHub — any branch, but only via a specific reusable workflow
claims['sub'] matches 'repo:Over-haul/REPO:ref:refs/heads/*' and claims['job_workflow_ref'] matches 'Over-haul/REPO/.github/workflows/*.yml@refs/heads/main'
```

> **Security:** broader expressions (e.g. `repo:ORG/REPO:pull_request`) allow any
> contributor's fork PRs to mint tokens for this identity. Prefer scoping to protected
> branches or environments for privileged SPs, and use `job_workflow_ref` to restrict
> to controlled workflows where possible.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.3.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 3.7.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.13.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | >= 3.7.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azuread_application.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_federated_identity_credential.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential) | resource |
| [azuread_application_flexible_federated_identity_credential.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_flexible_federated_identity_credential) | resource |
| [azuread_application_password.secret](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_service_principal.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [time_rotating.secret](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_client_secret"></a> [client\_secret](#input\_client\_secret) | Optional rotating client secret (M2M), e.g. for Databricks access.<br/>When `enabled` is true a password is created and rotated every `rotation_days`.<br/>The module exposes the secret as an output; storing it in Key Vault is the caller's responsibility. | <pre>object({<br/>    enabled       = optional(bool, false)<br/>    rotation_days = optional(number, 730)<br/>  })</pre> | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the Azure AD application and service principal. | `string` | `""` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | Display name of the Azure AD application / service principal. Must be unique within the tenant. | `string` | n/a | yes |
| <a name="input_flexible_federations"></a> [flexible\_federations](#input\_flexible\_federations) | Flexible federated identity credentials using wildcard/expression matching<br/>(azuread\_application\_flexible\_federated\_identity\_credential, requires azuread >= 3.7.0).<br/>The map key is used to build a unique credential display name ("flex-<key>").<br/><br/>`claims_matching_expression` is an Entra expression language string evaluated against<br/>incoming token claims. Only `sub` is matchable for GitLab; GitHub also supports<br/>`job_workflow_ref`. Operators: `matches` (supports `*` and `?` wildcards), `eq`, `and`.<br/><br/>Supported issuers: GitHub, GitLab (including self-hosted), Terraform Cloud only.<br/>Kubernetes and arbitrary OIDC issuers are NOT supported by flexible FICs; use the<br/>exact-match `kubernetes_federations` or `oidc_federations` inputs for those.<br/><br/>NOTE: `flexible_federations` and the exact-match federation inputs are complementary<br/>and can be combined on the same SP (total FIC cap: 20 per application).<br/><br/>Example expressions:<br/>  GitLab — all branches of a repo:<br/>    "claims['sub'] matches 'project\_path:over-haul/my-repo:ref\_type:branch:ref:*'"<br/>  GitHub — all branches of a repo:<br/>    "claims['sub'] matches 'repo:Over-haul/my-repo:ref:refs/heads/*'"<br/>  GitHub — all PRs:<br/>    "claims['sub'] matches 'repo:Over-haul/my-repo:pull\_request'"<br/>  GitHub — branch wildcard AND reusable workflow restriction:<br/>    "claims['sub'] matches 'repo:Over-haul/my-repo:ref:refs/heads/*' and claims['job\_workflow\_ref'] matches 'Over-haul/my-repo/.github/workflows/*.yml@refs/heads/main'" | <pre>map(object({<br/>    issuer                     = string<br/>    claims_matching_expression = string<br/>    audience                   = optional(string, "api://AzureADTokenExchange")<br/>    description                = optional(string, "")<br/>  }))</pre> | `{}` | no |
| <a name="input_github_federations"></a> [github\_federations](#input\_github\_federations) | GitHub Actions OIDC federated credentials. The issuer is fixed to GitHub.<br/>The map key is used to build a unique credential display name ("github-<key>").<br/>`subject` is the GitHub OIDC subject, e.g. "repo:Over-haul/my-repo" or "repository\_owner:Over-haul". | <pre>map(object({<br/>    subject = string<br/>  }))</pre> | `{}` | no |
| <a name="input_gitlab_federations"></a> [gitlab\_federations](#input\_gitlab\_federations) | GitLab CI/CD OIDC federated credentials. Defaults to GitLab.com; override `issuer` for self-hosted.<br/>The map key is used to build a unique credential display name ("gitlab-<key>").<br/>`subject` is the GitLab OIDC subject, e.g. "project\_path:group/project:ref\_type:branch:ref:main".<br/>NOTE: Azure AD matches the subject exactly (no wildcards); one entry per ref you want to trust. | <pre>map(object({<br/>    subject  = string<br/>    issuer   = optional(string, "https://gitlab.com")<br/>    audience = optional(string, "api://AzureADTokenExchange")<br/>  }))</pre> | `{}` | no |
| <a name="input_kubernetes_federations"></a> [kubernetes\_federations](#input\_kubernetes\_federations) | Kubernetes workload-identity federated credentials. The issuer is the cluster OIDC URL.<br/>The map key is used to build a unique credential display name ("k8s-<key>").<br/>The subject is derived as "system:serviceaccount:<namespace>:<serviceaccount>". | <pre>map(object({<br/>    cluster_oidc_url = string<br/>    namespace        = string<br/>    serviceaccount   = string<br/>  }))</pre> | `{}` | no |
| <a name="input_oidc_federations"></a> [oidc\_federations](#input\_oidc\_federations) | Generic OIDC federated credentials escape hatch for arbitrary issuers (Bitbucket, CircleCI, etc.).<br/>The map key is used to build a unique credential display name ("oidc-<key>"). | <pre>map(object({<br/>    issuer    = string<br/>    subject   = string<br/>    audiences = optional(list(string), ["api://AzureADTokenExchange"])<br/>  }))</pre> | `{}` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | List of already-resolved object IDs that own the application and service principal. | `list(string)` | `[]` | no |
| <a name="input_resource_access"></a> [resource\_access](#input\_resource\_access) | Optional list of resource\_access entries to pair with resource\_app\_id. | <pre>list(object({<br/>    id   = string<br/>    type = string<br/>  }))</pre> | `[]` | no |
| <a name="input_resource_app_id"></a> [resource\_app\_id](#input\_resource\_app\_id) | Optional resource app ID for required\_resource\_access (e.g. Microsoft Graph for multi-tenant SPs). | `string` | `""` | no |
| <a name="input_sign_in_audience"></a> [sign\_in\_audience](#input\_sign\_in\_audience) | The Microsoft account types that are supported for the application. Use 'AzureADMultipleOrgs' for multi-tenant SPs. | `string` | `"AzureADMyOrg"` | no |
| <a name="input_web"></a> [web](#input\_web) | Optional web configuration for the application (homepage, redirect URIs, implicit grant). | <pre>object({<br/>    homepage_url  = optional(string, null)<br/>    logout_url    = optional(string, null)<br/>    redirect_uris = optional(list(string), [])<br/>    implicit_grant = optional(object({<br/>      access_token_issuance_enabled = optional(bool, null)<br/>      id_token_issuance_enabled     = optional(bool, null)<br/>    }), null)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | The resource ID of the Azure AD application (e.g. /applications/<object-id>). |
| <a name="output_application_object_id"></a> [application\_object\_id](#output\_application\_object\_id) | The object ID of the Azure AD application. |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | The client ID (application ID) of the service principal. |
| <a name="output_client_secret"></a> [client\_secret](#output\_client\_secret) | The generated client secret value, or null when no client secret was requested. |
| <a name="output_client_secret_enabled"></a> [client\_secret\_enabled](#output\_client\_secret\_enabled) | Whether a client secret was created for this service principal. |
| <a name="output_object_id"></a> [object\_id](#output\_object\_id) | The object ID of the service principal. |
<!-- END_TF_DOCS -->
