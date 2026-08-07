# A single Azure AD application + service principal that can carry any combination of
# OIDC federated credentials (GitHub, GitLab, Kubernetes, or arbitrary issuers) and an
# optional rotating client secret. This unifies the previously separate Kubernetes /
# GitHub / Databricks service-principal definitions into one reusable building block.

resource "azuread_application" "this" {
  display_name                   = var.display_name
  description                    = var.description
  sign_in_audience               = var.sign_in_audience
  owners                         = var.owners
  prevent_duplicate_names        = true
  identifier_uris                = var.identifier_uris
  fallback_public_client_enabled = var.fallback_public_client_enabled
  group_membership_claims        = var.group_membership_claims

  dynamic "optional_claims" {
    for_each = var.optional_claims != null ? [1] : []
    content {
      dynamic "access_token" {
        for_each = coalesce(var.optional_claims.access_token, [])
        content {
          name                  = access_token.value.name
          essential             = access_token.value.essential
          additional_properties = access_token.value.additional_properties
        }
      }
      dynamic "id_token" {
        for_each = coalesce(var.optional_claims.id_token, [])
        content {
          name                  = id_token.value.name
          essential             = id_token.value.essential
          additional_properties = id_token.value.additional_properties
        }
      }
      dynamic "saml2_token" {
        for_each = coalesce(var.optional_claims.saml2_token, [])
        content {
          name                  = saml2_token.value.name
          essential             = saml2_token.value.essential
          additional_properties = saml2_token.value.additional_properties
        }
      }
    }
  }

  dynamic "web" {
    for_each = var.web != null ? [1] : []
    content {
      homepage_url  = var.web.homepage_url
      logout_url    = var.web.logout_url
      redirect_uris = var.web.redirect_uris
      dynamic "implicit_grant" {
        for_each = var.web.implicit_grant != null ? [1] : []
        content {
          access_token_issuance_enabled = var.web.implicit_grant.access_token_issuance_enabled
          id_token_issuance_enabled     = var.web.implicit_grant.id_token_issuance_enabled
        }
      }
    }
  }

  dynamic "required_resource_access" {
    for_each = var.resource_app_id != "" ? [1] : []
    content {
      resource_app_id = var.resource_app_id
      dynamic "resource_access" {
        for_each = var.resource_access
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  dynamic "api" {
    for_each = (var.requested_access_token_version != null || length(var.oauth2_permission_scopes) > 0) ? [1] : []
    content {
      requested_access_token_version = var.requested_access_token_version
      dynamic "oauth2_permission_scope" {
        for_each = var.oauth2_permission_scopes
        content {
          admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
          admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
          enabled                    = oauth2_permission_scope.value.enabled
          id                         = oauth2_permission_scope.value.id
          type                       = oauth2_permission_scope.value.type
          value                      = oauth2_permission_scope.value.value
        }
      }
    }
  }
}

resource "azuread_service_principal" "this" {
  client_id                    = azuread_application.this.client_id
  owners                       = var.owners
  use_existing                 = true
  app_role_assignment_required = var.app_role_assignment_required
}

locals {
  # All federation kinds collapse into a single set keyed by "<provider>-<key>".
  # Each provider only differs in how (issuer, subject, audiences) are derived.
  federations = merge(
    {
      for key, value in var.github_federations : "github-${key}" => {
        issuer    = "https://token.actions.githubusercontent.com"
        subject   = value.subject
        audiences = ["api://AzureADTokenExchange"]
      }
    },
    {
      for key, value in var.gitlab_federations : "gitlab-${key}" => {
        issuer    = value.issuer
        subject   = value.subject
        audiences = [value.audience]
      }
    },
    {
      for key, value in var.kubernetes_federations : "k8s-${key}" => {
        display_name = coalesce(value.display_name, "k8s-${key}")
        issuer       = value.cluster_oidc_url
        subject      = "system:serviceaccount:${value.namespace}:${value.serviceaccount}"
        audiences    = ["api://AzureADTokenExchange"]
      }
    },
    {
      for key, value in var.oidc_federations : "oidc-${key}" => {
        issuer    = value.issuer
        subject   = value.subject
        audiences = value.audiences
      }
    },
  )
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each       = local.federations
  application_id = azuread_application.this.id
  display_name   = try(each.value.display_name, each.key)
  description    = var.description
  audiences      = each.value.audiences
  issuer         = each.value.issuer
  subject        = each.value.subject

}

# Flexible federated identity credentials — expression-based wildcard matching.
# Requires azuread >= 3.7.0 and is a preview feature in Microsoft Entra.
# Only GitHub, GitLab, and Terraform Cloud issuers are supported by the API.
# Kubernetes and arbitrary OIDC issuers must use the exact-match resource above.
resource "azuread_application_flexible_federated_identity_credential" "this" {
  for_each                   = var.flexible_federations
  application_id             = azuread_application.this.id
  display_name               = "flex-${each.key}"
  description                = each.value.description
  audience                   = each.value.audience
  issuer                     = each.value.issuer
  claims_matching_expression = each.value.claims_matching_expression
}

resource "time_rotating" "secret" {
  count         = try(var.client_secret.enabled, false) ? 1 : 0
  rotation_days = try(var.client_secret.rotation_days, 730)
}

resource "azuread_application_password" "secret" {
  count          = try(var.client_secret.enabled, false) ? 1 : 0
  display_name   = format("%s-%s", var.display_name, "client-secret")
  application_id = azuread_application.this.id

  rotate_when_changed = {
    rotation = time_rotating.secret[0].id
  }
}
