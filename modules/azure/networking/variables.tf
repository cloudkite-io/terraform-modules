variable "environment" {
  description = "Environment like: infra-ops, dev, stage, prod"
  type        = string
}

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "vnet_name" {
  description = "Name for the virtual network"
  type        = string
}

variable "vnet_location" {
  description = "Azure location for the virtual network"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for nat gateway and public ips"
  type        = list(string)
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "Azure subnets and their configuration"
  type = map(object({
    address_prefixes                  = list(string)
    enable_nat                        = bool
    service_endpoints                 = list(string)
    private_endpoint_network_policies = string # Allowed values: "Disabled", "Enabled", "NetworkSecurityGroupEnabled" and "RouteTableEnabled"
    delegations = map(object({
      service_delegation_name    = string
      service_delegation_actions = list(string)
    }))
    security_rules = optional(map(object({
      priority                              = number
      direction                             = string
      access                                = string
      protocol                              = string
      source_port_range                     = optional(string)
      source_port_ranges                    = optional(list(string))
      destination_port_range                = optional(string)
      destination_port_ranges               = optional(list(string))
      source_address_prefix                 = optional(string)
      source_address_prefixes               = optional(list(string))
      destination_address_prefix            = optional(string)
      destination_address_prefixes          = optional(list(string))
      source_application_security_group_ids = optional(list(string))
    })), {})
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })))
  }))
}
