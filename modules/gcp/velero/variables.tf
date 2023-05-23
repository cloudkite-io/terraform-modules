variable "project" {
  description = "The name of the GCP Project where all resources will be launched."
  type        = string
}

variable "backup_project" {
  description = "The name of the GCP Project where all backups will be stored."
  type        = string
}

variable "service_account_name" {
  description = "The name of the custom service account. This parameter is limited to a maximum of 28 characters."
  type        = string
}

variable "backups_bucket_name" {
  description = "The name of the bucket used by velero to storage backups."
  type        = string
}

variable "backups_bucket_location" {
  description = "The location of the bucket used by velero to storage backups."
  type        = string
}
