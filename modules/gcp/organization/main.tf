locals {
  billing_account_project_creators = var.billing_account_id == null ? toset([]) : toset(var.project_creators)

  folder_iam_members = {
    for membership in flatten([
      for folder, config in var.folders : [
        for role, members in config.iam_members : [
          for member in members : {
            folder = folder
            role   = role
            member = member
          }
        ]
      ]
    ]) : "${membership.folder}|${membership.role}|${membership.member}" => membership
  }

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
  folder_id           = each.value.folder == null ? null : google_folder.folder[each.value.folder].name
  labels              = merge(var.default_labels, each.value.labels)
  name                = each.value.name
  org_id              = each.value.folder == null ? var.organization_id : null
  project_id          = each.key

  depends_on = [google_billing_account_iam_member.project_creator]
}

resource "google_organization_iam_member" "folder_creator" {
  for_each = var.folder_creators

  org_id = var.organization_id
  role   = "roles/resourcemanager.folderCreator"
  member = each.value
}

resource "google_billing_account_iam_member" "project_creator" {
  for_each = local.billing_account_project_creators

  billing_account_id = var.billing_account_id
  member             = each.key
  role               = "roles/billing.user"
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

resource "google_folder" "folder" {
  for_each = var.folders

  display_name        = each.value.display_name
  parent              = "organizations/${var.organization_id}"
  deletion_protection = each.value.deletion_protection

  depends_on = [google_organization_iam_member.folder_creator]
}

resource "google_folder_iam_member" "member" {
  for_each = local.folder_iam_members

  folder = google_folder.folder[each.value.folder].name
  role   = each.value.role
  member = each.value.member
}
