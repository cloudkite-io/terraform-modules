[![Maintained by cloudkite.io](https://img.shields.io/badge/maintained%20by-cloudkite.io-%235849a6.svg)](https://cloudkite.io/)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/cloudkite-io/terraform-modules.svg?label=latest)](https://github.com/cloudkite-io/terraform-modules/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.9-blue.svg)

# Terraform Modules

This repo contains [Terraform](https://www.terraform.io) modules for running a Private Kubernetes cluster on [Google Cloud Platform (GCP)](https://cloud.google.com/)
using [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/).

## Repo content

### Modules:

* [gke](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/gke): This folder contains the main implementation 
for the kubernetes cluster.
* [gke-service-account](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/gke-service-account): Here you will
find the main implementation of the GCP service account to use with a GKE cluster, and the associated iam binding roles.
* [network/vpc](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/network/vpc): This folder contains the main
implementation of the vpc network to host the cluster in.
* [velero service account](https://github.com/cloudkite-io/terraform-modules/tree/master/modules/velero-service-account): This folder
contains the main implementation of the GCP service account to use with velero.

## License

Please see [LICENSE](https://github.com/cloudkite-io/terraform-modules/blob/master/LICENSE) for how the code in this
repo is licensed.

Copyright &copy; 2019 Cloudkite.io