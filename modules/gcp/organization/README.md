# Organization module

Creates top-level Google Cloud folders and projects, and adds explicitly declared organization and folder IAM members. The organization stack is the intended caller.

## Behavior

Projects are keyed by project ID, use `deletion_policy = "PREVENT"`, and set
`auto_create_network = false`. Terraform prevents their deletion and projects do
not retain Google Cloud's default auto-mode VPC; add networking explicitly in a
later layer. Organization IAM uses additive `google_organization_iam_member`
resources: each declared role/member pair is managed independently and does not
replace other members for the role.

Folders are keyed by stable caller-defined identifiers and are created directly
beneath the organization. Folder IAM also uses additive member resources. A
project remains at the organization root unless its optional `folder` attribute
names one of the managed folder keys. Adding or changing that attribute moves an
existing project and changes its inherited IAM, so review such plans carefully.

Each `folder_creators` principal receives
`roles/resourcemanager.folderCreator` on the organization. Folder creation waits
for those grants, allowing the applying organization administrator to bootstrap
the identities that will manage folders.

Each `project_creators` principal receives
`roles/resourcemanager.projectCreator` on the organization. When
`billing_account_id` is set, the module also grants those principals
`roles/billing.user` on that billing account using additive IAM membership. The
billing grants are created before projects so project creators can associate new
projects with the configured billing account.

The credentials applying the initial billing grants need
`billing.accounts.getIamPolicy` and `billing.accounts.setIamPolicy` on the
billing account, commonly provided by `roles/billing.admin`. After bootstrap,
the managed `roles/billing.user` grant supplies
`billing.resourceAssociations.create` for project association.

This module can optionally manage an organization policy that prevents creation of new projects by organization members.

## Inputs

| Name | Type | Description |
| --- | --- | --- |
| `organization_id` | `string` | Required numeric organization ID. |
| `projects` | `map(object)` | Projects keyed by project ID, with `name`, optional `labels`, and an optional managed `folder` key. |
| `billing_account_id` | `string` | Optional billing account ID; `null` creates projects without billing. |
| `folder_creators` | `set(string)` | Optional principals granted Folder Creator on the organization. |
| `folders` | `map(object)` | Optional top-level folders with display name, deletion protection, and additive IAM memberships. |
| `organization_iam_members` | `map(set(string))` | Optional additive IAM members grouped by role. |
| `prevent_project_creation` | `bool` | Optional flag to enforce an organization policy that blocks new project creation. |
| `project_creators` | `list(string)` | Optional IAM principal strings granted project creation permissions and, when `billing_account_id` is set, billing account association permissions. |
| `default_labels` | `map(string)` | Default labels applied to all created projects; project-level labels override conflicts. |

## Outputs

| Name | Description |
| --- | --- |
| `folder_iam_members` | Managed additive folder IAM memberships keyed by folder, role, and member. |
| `folders` | Managed folder identifiers keyed by input folder key. |
| `project_folders` | Configured managed-folder placement for each project. |
| `project_ids` | Created project IDs keyed by input project ID. |
| `project_numbers` | Created project numbers keyed by input project ID. |
