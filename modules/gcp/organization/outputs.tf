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
