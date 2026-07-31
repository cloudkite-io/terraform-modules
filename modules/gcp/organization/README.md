# Organization module

Creates a defined set of Google Cloud projects and adds explicitly declared organization IAM members. The organization stack is the intended caller.

## Behavior

Projects are keyed by project ID, use `deletion_policy = "PREVENT"`, and set
`auto_create_network = false`. Terraform prevents their deletion and projects do
not retain Google Cloud's default auto-mode VPC; add networking explicitly in a
later layer. Organization IAM uses additive `google_organization_iam_member`
resources: each declared role/member pair is managed independently and does not
replace other members for the role.

This module can optionally manage an organization policy that prevents creation of new projects by organization members.

## Inputs

| Name | Type | Description |
| --- | --- | --- |
| `organization_id` | `string` | Required numeric organization ID. |
| `projects` | `map(object)` | Required projects keyed by project ID, with `name` and optional `labels`. |
| `billing_account_id` | `string` | Optional billing account ID; `null` creates projects without billing. |
| `organization_iam_members` | `map(set(string))` | Optional additive IAM members grouped by role. |
| `prevent_project_creation` | `bool` | Optional flag to enforce an organization policy that blocks new project creation. |
| `project_creators` | `list(string)` | Optional IAM principal strings granted project creation permissions, such as `group:team@example.com` or `user:alice@example.com`. |
| `default_labels` | `map(string)` | Default labels applied to all created projects; project-level labels override conflicts. |

## Outputs

| Name | Description |
| --- | --- |
| `project_ids` | Created project IDs keyed by input project ID. |
| `project_numbers` | Created project numbers keyed by input project ID. |
