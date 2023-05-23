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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "Azure subnets and their configuration"
  type = map(object({
    address_prefixes                          = list(string)
    enable_nat                                = bool
    service_endpoints                         = list(string)
    private_endpoint_network_policies_enabled = bool
    delegations = map(object({
      service_delegation_name    = string
      service_delegation_actions = list(string)
    }))
  }))
}
