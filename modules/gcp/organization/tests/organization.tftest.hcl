mock_provider "google" {
  override_during = plan

  mock_resource "google_folder" {
    defaults = {
      folder_id = "987654321098"
      name      = "folders/987654321098"
    }
  }
}

variables {
  organization_id = "123456789012"
  folder_creators = [
    "group:gcp-admins@example.com",
  ]
  folders = {
    workloads = {
      display_name = "Workloads"
      iam_members = {
        "roles/viewer" = [
          "group:developers@example.com",
        ]
      }
    }
  }
  projects = {
    example-root = {
      name = "Example Root"
    }
    example-workload = {
      folder = "workloads"
      labels = {
        environment = "test"
      }
      name = "Example Workload"
    }
  }
}

run "manages_folders_and_project_placement" {
  command = plan

  assert {
    condition     = length(google_folder.folder) == 1
    error_message = "The module must create every configured top-level folder."
  }

  assert {
    condition     = length(google_organization_iam_member.folder_creator) == 1
    error_message = "The module must grant Folder Creator to every configured principal."
  }

  assert {
    condition     = length(google_folder_iam_member.member) == 1
    error_message = "The module must manage every configured folder IAM membership additively."
  }

  assert {
    condition     = output.folders["workloads"].display_name == "Workloads"
    error_message = "Folder outputs must retain their stable input keys."
  }

  assert {
    condition     = output.project_folders["example-root"] == null
    error_message = "Projects without a folder must remain at the organization root."
  }

  assert {
    condition     = output.project_folders["example-workload"] == "workloads"
    error_message = "Projects must support placement by stable managed-folder key."
  }

  assert {
    condition = (
      google_project.project["example-root"].org_id == var.organization_id &&
      google_project.project["example-root"].folder_id == null
    )
    error_message = "Projects without a folder must use the organization as their parent."
  }

  assert {
    condition = (
      google_project.project["example-workload"].org_id == null &&
      google_project.project["example-workload"].folder_id == "folders/987654321098"
    )
    error_message = "Projects assigned to a folder must use that folder as their only parent."
  }

  assert {
    condition     = output.folder_iam_members["workloads|roles/viewer|group:developers@example.com"].role == "roles/viewer"
    error_message = "Folder IAM outputs must be keyed by folder, role, and member."
  }
}

run "rejects_unknown_project_folder" {
  command = plan

  variables {
    projects = {
      invalid-project = {
        folder = "missing"
        name   = "Invalid Project"
      }
    }
  }

  expect_failures = [var.projects]
}
