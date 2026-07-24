variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "dns_domain_zones" {
  description = "List of Top level domains to create"
  type        = list(string)
  default     = []
}

variable "dns_a_records" {
  description = "Map with dns A records to create and their configurations"
  type = map(object({
    records = list(string)
  }))
  default = {}
}

variable "dns_aaaa_records" {
  description = "Map with dns AAAA records to create and their configurations"
  type = map(object({
    records = list(string)
  }))
  default = {}
}

variable "dns_cname_records" {
  description = "Map with dns CNAME records to create and their configurations"
  type = map(object({
    record = string
  }))
  default = {}
}

variable "private_dns_domain_zones" {
  description = "List of private top level domains to create"
  type        = list(string)
  default     = []
}

variable "private_dns_a_records" {
  description = "Map with private dns A records to create and their configurations"
  type = map(object({
    records = list(string)
  }))
  default = {}
}

variable "private_dns_aaaa_records" {
  description = "Map with private dns AAAA records to create and their configurations"
  type = map(object({
    records = list(string)
  }))
  default = {}
}

variable "private_dns_cname_records" {
  description = "Map with private dns CNAME records to create and their configurations"
  type = map(object({
    record = string
  }))
  default = {}
}
