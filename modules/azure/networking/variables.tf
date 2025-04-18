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

variable "nat_prefix" {
  description = "Prefix of the nat gateway & public ip address"
  type        = string
  default     = ""
}

variable "ip_prefix" {
  description = "Prefix of the nat public ip address"
  type        = string
  default     = ""
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

variable "peering" {
  description = "Vnet Peering configuration"
  type = map(object({
    remote_virtual_network_id    = optional(string)
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
    use_remote_gateways          = optional(bool, false)
    local_subnet_names           = optional(list(string))
    remote_subnet_names          = optional(list(string))
    private_dns_links            = optional(list(string))
  }))
}
