# Project module

Configures enabled APIs in an existing Google Cloud project. It never creates, owns, or deletes the project itself.

API resources use `disable_on_destroy = false`, so APIs remain enabled if their Terraform configuration is removed or the module is destroyed.

## Inputs

| Name | Type | Description |
| --- | --- | --- |
| `project_id` | `string` | Required existing Google Cloud project ID. |
| `services` | `set(string)` | Optional Google API service hostnames to enable. |

## Outputs

| Name | Description |
| --- | --- |
| `enabled_services` | Sorted API service names enabled by this module. |
