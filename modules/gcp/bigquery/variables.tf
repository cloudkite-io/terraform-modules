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


variable "cloudsql_scheduled_postgres_transfers" {
  type        = map(any)
  description = "Schedule"
}

variable "postgres_password" {
  type        = string
  description = "Postgres Password, set by export TF_VAR_postgres_password=secret_password"
  sensitive   = true
}