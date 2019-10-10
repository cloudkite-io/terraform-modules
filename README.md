[![Maintained by cloudkite.io](https://img.shields.io/badge/maintained%20by-cloudkite.io-%235849a6.svg)](https://cloudkite.io/)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/cloudkite-io/terraform-modules.svg?label=latest)](https://github.com/cloudkite-io/terraform-modules/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.9-blue.svg)

# Terraform Modules

This repo contains [Terraform](https://www.terraform.io/docs/configuration/modules.html) modules for building and maintaing cloud infrastructure.

These modules are opinionated based on what we consider good defaults.

## Repo content

### Modules:

* [gke](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/gke): GKE module for Google Compute Platform
* [gke-service-account](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/gke-service-account): Service Account for GKE Nodes 
* [network/vpc](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/network/vpc): GCP VPC
* [velero service account](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/velero-service-account): GCP IAM Service Account for [Velero](https://velero.io)

## License

Please see [LICENSE](https://github.com/cloudkite-io/terraform-modules/blob/master/LICENSE) for how the code in this
repo is licensed.

Copyright &copy; 2019 Cloudkite.io
