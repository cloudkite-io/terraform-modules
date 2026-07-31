locals {
  organization_iam_members = {
    for membership in flatten([
      for role, members in var.organization_iam_members : [
        for member in members : {
          role   = role
          member = member
        }
      ]
    ]) : "${membership.role}|${membership.member}" => membership
  }
}

resource "google_project" "project" {
  for_each = var.projects

  auto_create_network = false
  billing_account     = var.billing_account_id
  deletion_policy     = "PREVENT"
  labels              = merge(var.default_labels, each.value.labels)
  name                = each.value.name
  org_id              = var.organization_id
  project_id          = each.key
}

resource "google_organization_policy" "disable_project_creation" {
  count      = var.prevent_project_creation ? 1 : 0
  org_id     = var.organization_id
  constraint = "constraints/resourcemanager.disableProjectCreation"

  boolean_policy {
    enforced = true
  }
}

resource "google_organization_iam_member" "project_creator" {
  for_each = toset(var.project_creators)
  org_id   = var.organization_id
  role     = "roles/resourcemanager.projectCreator"
  member   = each.key
}

resource "google_organization_iam_member" "member" {
  for_each = local.organization_iam_members

  member = each.value.member
  org_id = var.organization_id
  role   = each.value.role
}
