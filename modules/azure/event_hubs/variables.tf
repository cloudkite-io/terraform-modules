variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "event_hubs_namespaces" {
  description = "Azure event hub configurations"
  type = map(object({
    override_name  = optional(string, null)
    sku            = string
    capacity       = number
    zone_redundant = bool
    auto_inflate = object({
      enabled                  = bool
      maximum_throughput_units = number
    })
    public_network_access_enabled  = optional(bool, false)
    trusted_service_access_enabled = optional(bool, false)
    ip_rules                       = optional(list(string), [])
    public_uri_key_vaults = optional(map(object({
      resource_group_name = string
    })), {})
    subnets = optional(map(object({
      vnet_name               = string
      resource_group_name     = string
      location                = string
      key_vault_name          = optional(string, null)
      create_private_endpoint = optional(bool, false)
    })), {})
    event_hubs = map(object({
      message_retention = number
      partition_count   = number
      authorization_rules = optional(map(object({
        listen = optional(bool, false)
        send   = optional(bool, false)
        manage = optional(bool, false)
        })),
      {})
    }))
  }))
}
