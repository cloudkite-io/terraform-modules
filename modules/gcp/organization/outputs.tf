output "folder_iam_members" {
  description = "Managed additive folder IAM memberships keyed by folder, role, and member."
  value = {
    for key, membership in google_folder_iam_member.member : key => {
      folder = local.folder_iam_members[key].folder
      role   = membership.role
      member = membership.member
    }
  }
}

output "folders" {
  description = "Managed folder identifiers keyed like folders."
  value = {
    for folder, resource in google_folder.folder : folder => {
      display_name = resource.display_name
      folder_id    = resource.folder_id
      name         = resource.name
      parent       = resource.parent
    }
  }
}

output "project_folders" {
  description = "Configured managed-folder placement for each project; null means the organization root."
  value       = { for project_id, project in var.projects : project_id => project.folder }
}

output "project_ids" {
  description = "Created project IDs, keyed by the input project ID."
  value = {
    for project_id, project in google_project.project : project_id => project.project_id
  }
}

output "project_numbers" {
  description = "Created project numbers, keyed by the input project ID."
  value = {
    for project_id, project in google_project.project : project_id => project.number
  }
}
