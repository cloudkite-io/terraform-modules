variable "project" {
  description = "The name of the GCP Project where all resources will be launched."
  type        = string
}

variable "name" {
  description = "The name of the custom service account. This parameter is limited to a maximum of 28 characters."
  type        = string
}

variable "description" {
  description = "The description of the custom service account."
  type        = string
  default     = ""
}

variable "service_account_roles" {
  description = "Additional roles to be added to the service account."
  type        = list(string)
  default     = []
}