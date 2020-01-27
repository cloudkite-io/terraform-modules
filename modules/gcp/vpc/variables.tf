variable environment {
  description = "The environment for <development|production> workloads"
  type = string
}

variable "project" {
  description = "The project ID to host the cluster in (required)"
  type = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
}

variable "network-prefix" {
  description = "A network segment prefix in the VPC network to host the cluster in"
  type        = string
}
