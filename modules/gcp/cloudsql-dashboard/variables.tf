
variable "project" {
  description = "The project ID to host the cluster in (required)"
  type = string
}

variable "dashboard_json_file" {
  description = "The JSON file of the dashboard."
  type        = string
  default = "cloudsql-monitoring.json"
}