variable "project" {
  description = "The project ID to host the cluster in (required)"
  type        = string
}

variable "service_account_email" {
  description = "The email of the custom service account."
  type        = string
}


variable "bq_datasets" {
  type        = map(any)
  description = "BQ Datasets to create."
}

variable "stored_procedures" {
  type        = map(any)
  description = "Stored Procedures to create."
}

variable "cloudsql_scheduled_postgres_transfers" {
  type        = map(any)
  description = "CloudSQL Postgres configurations for scheduled transfers."
}

variable "cloudsql_connections" {
  type        = map(any)
  description = "BQ CloudSQL External connection"
}

variable "clickhouse_connections" {
  type        = map(any)
  description = "BQ Clickhouse External connection"
  default     = {}
}

variable "postgres_password" {
  type        = string
  description = "Postgres Password, set export TF_VAR_postgres_password='your_secret_password'"
  sensitive   = true
}
