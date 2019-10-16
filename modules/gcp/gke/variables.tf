variable environment {
  description = "The environment for <development|production> workloads."
  type = "string"
}

variable "gcp" {
  description = "Map of Google Cloud Platform specific variables."
  type = "map"
}

variable "gke" {
  description = "Map of Google Kubernetes Engine specific variables."
  type = "map"
}

variable "network" {
  type        = string
  description = "The VPC network to host the cluster in (required)."
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

variable "kubernetes_dashboard" {
  type        = bool
  description = "Enable kubernetes dashboard addon."
  default     = false
}

variable "network_policy_config_disabled" {
  type        = bool
  description = "Enable network policy addon."
  default = false
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
  type        = "list"
}

variable "enable_network_policy" {
  description = "Whether to enable Kubernetes NetworkPolicy on the master. It is required to be enabled to be used on Nodes."
  type        = bool
  default = true
}

variable "gke_nodepools" {
  type        = list(map(string))
  description = "List of maps containing node pools"
}

variable "service_account_roles" {
  description = "Additional roles to be added to the service account."
  type        = list(string)
  default     = []
}