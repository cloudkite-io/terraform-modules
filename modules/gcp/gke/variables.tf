variable "project" {
  description = "The project ID to host the cluster in (required)"
  type        = string
}

variable "environment" {
  description = "The environment for <development|production> workloads."
  type        = string
}

variable "location" {
  description = "The location (region or zone) of the GKE cluster."
  type        = string
}

variable "min_master_version" {
  type        = string
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region."
  default     = "latest"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation (size must be /28) to use for the hosted master network."
  default     = "172.31.0.0/28"
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
}

variable "network" {
  type        = string
  description = "The VPC network to host the cluster in (required). If this isn't passed in, the module tries projects/{{project}}/global/networks/{var.environment}-vpc"
  default     = ""
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork to host the cluster in (required)."
}

variable "logging_service" {
  type        = string
  description = "The logging service that the cluster should write logs to."
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  type        = string
  description = "The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Google Cloud Monitoring API.."
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "horizontal_pod_autoscaling" {
  type        = bool
  description = "Enable horizontal pod autoscaling addon."
  default     = true
}

variable "http_load_balancing" {
  type        = bool
  description = "Enable httpload balancer addon."
  default     = true
}

variable "network_policy_config_disabled" {
  type        = bool
  description = "Enable network policy addon."
  default     = false
}

variable "gke_services_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the gke services to use."
  type        = string
}

variable "gke_pods_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the pods to use."
  type        = string
}

variable "gke_master_authorized_networks" {
  description = "The networks from which a connection to the master can be established"
  type        = list(map(string))
}

variable "enable_network_policy" {
  description = "Whether to enable Kubernetes NetworkPolicy on the master. It is required to be enabled to be used on Nodes."
  type        = bool
  default     = true
}

variable "gke_nodepools" {
  type        = map(any)
  description = "List of maps containing node pools"

  default = {}
}

variable "service_account_roles" {
  description = "Additional roles to be added to the service account."
  type        = list(string)
  default     = []
}
