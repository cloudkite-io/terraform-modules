variable "name" {
  description = "Name of virtual gateway."
  type        = string
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
  type        = string
}

variable "location" {
  description = "The Azure Region in which to create resource."
  type        = string
}

variable "subnet_id" {
  description = "Id of subnet where gateway should be deployed, have to be named GatewaySubnet."
  type        = string
}

variable "enable_bgp" {
  description = "If true, BGP (Border Gateway Protocol) will be enabled for this Virtual Network Gateway. Defaults to false."
  type        = bool
  default     = false
}

variable "active_active" {
  description = "If true, an active-active Virtual Network Gateway will be created. An active-active gateway requires a HighPerformance or an UltraPerformance sku. If false, an active-standby gateway will be created. Defaults to false."
  type        = bool
  default     = false
}

variable "sku" {
  description = "Configuration of the size and capacity of the virtual network gateway."
  type        = string
}

variable "client_configuration" {
  description = "If set it will activate point-to-site configuration."
  type = object({
    address_space = list(string)
    protocols     = list(string)
    certificate   = string
    auth_types    = list(string)
    revoked_certificates = optional(map(object({
      name       = string
      thumbprint = string
    })),{})
  })
  default = null
}

variable "local_networks" {
  description = "List of local virtual network connections to connect to gateway."
  type = list(
    object({
      name            = string
      gateway_address = string
      address_space   = list(string)
      shared_key      = string
      ipsec_policy    = any
    })
  )
  default = []
}
