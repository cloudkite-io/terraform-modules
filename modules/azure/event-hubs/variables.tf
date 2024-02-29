variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "environment" {
  description = "Environment like: infra-ops, dev, stage, prod"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "event_hub" {
  description = "Azure event hub related configs"
  type = object({
    sku      = string
    capacity = optional(number)
    auto_inflate = object({
      enabled                  = optional(bool, false)
      maximum_throughput_units = optional(number)
    })
    network_rules = object({
      ip_rules   = list(string)
      subnet_ids = list(string)
    })

  })

}
