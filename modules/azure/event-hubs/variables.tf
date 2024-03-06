variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "environment" {
  description = "Environment like: infra-ops, dev, stage, prod"
  type        = string
}

variable "vnet_name" {
  description = "Name of the vnet on which private link is to be setup"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet on which private link is to be setup"
  type        = string
}

variable "key_vault_id" {
  description = "Id of the Keyvault where event hub primary connection strings are stored"
  type        = string
}
variable "event_hubs_namespaces" {
  description = "Azure event hub configurations"
  type = map(object({
    sku            = string
    capacity       = number
    zone_redundant = bool
    auto_inflate = object({
      enabled                  = bool
      maximum_throughput_units = number
    })
    network_rules = object({
      ip_rules                       = list(string)
      subnet_ids                     = list(string)
      public_network_access_enabled  = bool
      trusted_service_access_enabled = bool
    })
    private_endpoint = object({
      enabled = bool
    })
    event_hubs = map(object({
      message_retention = number
      partition_count   = number
    }))
  }))
}
