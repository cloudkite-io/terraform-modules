variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "dns_domain_zones" {
  description = "List of Top level domains to create"
  type        = list(string)
}

variable "dns_a_records" {
  description = "Map with dns A records to create and their configurations"
  type = map(object({
    zone    = string
    records = list(string)
  }))
}

variable "dns_cname_records" {
  description = "Map with dns CNAME records to create and their configurations"
  type = map(object({
    zone   = string
    record = string
  }))
}
