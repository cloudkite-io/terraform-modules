variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "frontdoor_profiles" {
  description = "Frontdoor configurations"
  default     = {}
  type = map(object({
    sku_name                 = string
    response_timeout_seconds = number
    routes = map(object({
      origin_group = object({
        session_affinity_enabled                          = optional(bool, true)
        health_probe_enabled                              = optional(bool, false)
        health_probe_interval_in_seconds                  = optional(number, 240)
        health_probe_path                                 = optional(string, "/")
        heath_probe_protocol                              = optional(string, "Https")
        health_probe_request_type                         = optional(string, "HEAD")
        restore_traffic_to_healed_or_new_endpoint         = optional(number)
        load_balancing_additional_latency_in_milliseconds = optional(number, 50)
        load_balancing_sample_size                        = optional(number, 4)
        load_balancing_successful_sample_required         = optional(number, 3)
        origins = map(object({
          enabled                        = optional(bool, true)
          certificate_name_check_enabled = optional(bool, false)
          hostname                       = string
          http_port                      = optional(number, 80)
          https_port                     = optional(number, 443)
          origin_host_header             = string
          priority                       = optional(number, 1)
          weight                         = optional(number, 1)
        }))
      })
      route_enabled                         = optional(bool, true)
      forwarding_protocol                   = optional(string, "MatchRequest")
      https_redirect_enabled                = optional(bool, true)
      patterns_to_match                     = list(string)
      supported_protocols                   = list(string)
      route_link_to_domain                  = optional(bool, false)
      custom_domain_names                   = list(string)
      caching_enabled                       = optional(bool, false)
      caching_query_string_caching_behavior = optional(string)
      caching_query_strings                 = optional(list(string))
      caching_compression_enabled           = optional(bool, true)
      caching_content_types_to_compress     = optional(list(string))

    }))

    })
  )

}
