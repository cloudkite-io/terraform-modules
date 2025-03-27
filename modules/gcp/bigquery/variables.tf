variable "bq_datasets" {
  type        = map(any)
  description = "BQ Datasets to create."
}

variable "bq_tables" {
  type        = map(any)
  description = "BQ Tables to create."
}

variable "stored_procedures" {
  type        = map(any)
  description = "Stored Procedures to create."
}

variable "scheduled_queries" {
  type        = map(any)
  description = "Scheduled Queries to create."
}

variable "cloudsql_connections" {
  type        = map(any)
  description = "BQ CloudSQL External connection"
}

variable "postgres_password" {
  type        = string
  description = "Postgres Password, set export TF_VAR_postgres_password='your_secret_password'"
  sensitive   = true
}
