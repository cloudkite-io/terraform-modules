[![Maintained by cloudkite.io](https://img.shields.io/badge/maintained%20by-cloudkite.io-%235849a6.svg)](https://cloudkite.io/)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/cloudkite-io/terraform-modules.svg?label=latest)](https://github.com/cloudkite-io/terraform-modules/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.9-blue.svg)

# Terraform Modules

This repo contains [Terraform](https://www.terraform.io/docs/configuration/modules.html) modules for building and maintaining cloud infrastructure.

These modules are opinionated based on what we consider good defaults.

## Repo content

### Modules:

* [cloud sql dashboard](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/gcp/cloudsql-dashboard): GCP Cloudsql Dashboard
* [gke](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/gcp/gke): GKE module for Google Compute Platform
* [vpc](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/gcp/vpc): GCP VPC
* [velero](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/gcp/velero): GCP IAM Service Account and backups GCP Storage bucket for [Velero](https://velero.io)

## Inputs

The following map is required by the gke_nodepools map used in the cloudkite's gke module:

| Name | Description | Type | Required |
|------|-------------|:----:|:-----:|
| auto\_repair | Whether the nodes will be automatically repaired. | bool | yes |
| auto\_upgrade | Whether the nodes will be automatically upgraded. | bool | yes |
| min\_node\_count | Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count. | number| yes |
| max\_node\_count | Maximum number of nodes in the NodePool. Must be >= min_node_count. | number | yes |
| machine\_type | The VM instance type. | string | yes |
| disk\_size | Size of the disk attached to each node, specified in GB. The smallest allowed disk size is 10GB. Defaults to 100GB. | string | yes |
| preemptible | A boolean that represents whether or not the underlying node VMs are preemptible. See the official documentation for more information. Defaults to false. | bool | yes |
| version | The Kubernetes version on the nodes. Must either be unset or set to the same value as min_master_version on create. Defaults to the default version set by GKE which is not necessarily the latest version. This only affects nodes in the default node pool. While a fuzzy version can be specified, it's recommended that you specify explicit versions as Terraform will see spurious diffs when fuzzy versions are used. See the google_container_engine_versions data source's version_prefix field to approximate fuzzy versions in a Terraform-compatible way. To update nodes in other node pools, use the version attribute on the node pool. | string | yes |

## License

Please see [LICENSE](https://github.com/cloudkite-io/terraform-modules/blob/master/LICENSE) for how the code in this
repo is licensed.

Copyright &copy; 2019 Cloudkite.io
