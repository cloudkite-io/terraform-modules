locals {
  frontdoor_origin_groups_and_routes = merge([
    for frontdoor_profile, frontdoor_profile_details in var.frontdoor_profiles : {
      for route, route_details in frontdoor_profile_details.routes :
      "${frontdoor_profile}-${route}" => {
        session_affinity_enabled                          = route_details.origin_group.session_affinity_enabled
        health_probe_enabled                              = route_details.origin_group.health_probe_enabled
        health_probe_interval_in_seconds                  = route_details.origin_group.health_probe_interval_in_seconds
        restore_traffic_to_healed_or_new_endpoint         = route_details.origin_group.restore_traffic_to_healed_or_new_endpoint
        load_balancing_additional_latency_in_milliseconds = route_details.origin_group.load_balancing_additional_latency_in_milliseconds
        load_balancing_sample_size                        = route_details.origin_group.load_balancing_sample_size
        load_balancing_successful_sample_required         = route_details.origin_group.load_balancing_successful_sample_required
        origins                                           = route_details.origin_group.origins
        route_enabled                                     = route_details.route_enabled
        forwarding_protocol                               = route_details.forwarding_protocol
        https_redirect_enabled                            = route_details.https_redirect_enabled
        patterns_to_match                                 = route_details.patterns_to_match
        supported_protocols                               = route_details.supported_protocols
        custom_domain_names                               = route_details.custom_domain_names
        caching_enabled                                   = route_details.caching_enabled
        caching_query_string_caching_behavior             = route_details.caching_query_string_caching_behavior
        caching_query_strings                             = route_details.caching_query_strings
        caching_compression_enabled                       = route_details.caching_compression_enabled
        caching_content_types_to_compress                 = route_details.caching_content_types_to_compress
        route_link_to_domain                              = route_details.route_link_to_domain
      }
    }
  ]...)

  frontdoor_origins = merge([
    for frontdoor_origin_group, frontdoor_origin_group_details in local.frontdoor_origin_groups_and_routes : {
      for frontdoor_origin, frontdoor_origin_details in frontdoor_origin_group_details.origins :
      "${frontdoor_origin_group}-${frontdoor_origin}" => {
        name                           = frontdoor_origin
        origin_group                   = frontdoor_origin_group
        enabled                        = frontdoor_origin_details.enabled
        certificate_name_check_enabled = frontdoor_origin_details.certificate_name_check_enabled
        hostname                       = frontdoor_origin_details.hostname
        http_port                      = frontdoor_origin_details.http_port
        https_port                     = frontdoor_origin_details.https_port
        priority                       = frontdoor_origin_details.priority
        weight                         = frontdoor_origin_details.weight
      }
    }
  ]...)

  custom_domains = merge([
    for frontdoor_route, frontdoor_route_details in local.frontdoor_origin_groups_and_routes : {
      for frontdoor_domain in frontdoor_route_details.custom_domain_names :
      "${frontdoor_route}*${frontdoor_domain}" => {
        domain  = frontdoor_domain
        profile = split("-", frontdoor_route)[0]
      }

    }
  ]...)
}

resource "azurerm_cdn_frontdoor_profile" "frontdoor_profile" {
  for_each                 = var.frontdoor_profiles
  name                     = each.key
  resource_group_name      = var.resource_group_name
  sku_name                 = each.value.sku_name
  response_timeout_seconds = each.value.response_timeout_seconds
}

resource "azurerm_cdn_frontdoor_origin_group" "frontdoor_origin_group" {
  for_each                 = local.frontdoor_origin_groups_and_routes
  name                     = split("-", each.key)[1]
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile[split("-", each.key)[0]].id
  session_affinity_enabled = each.value.session_affinity_enabled

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_to_healed_or_new_endpoint

  dynamic "health_probe" {
    for_each = each.value.health_probe_enabled ? [1] : []

    content {
      interval_in_seconds = each.value.health_probe_interval_in_seconds
      path                = each.value.health_probe_path
      protocol            = each.value.heath_probe_protocol
      request_type        = each.value.health_probe_request_type
    }
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing_additional_latency_in_milliseconds
    sample_size                        = each.value.load_balancing_sample_size
    successful_samples_required        = each.value.load_balancing_successful_sample_required
  }

}

resource "azurerm_cdn_frontdoor_origin" "front_door_origin" {
  for_each                      = local.frontdoor_origins
  name                          = each.value.name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group[each.value.origin_group].id
  enabled                       = each.value.enabled

  certificate_name_check_enabled = each.value.certificate_name_check_enabled

  host_name          = each.value.hostname
  http_port          = each.value.http_port
  https_port         = each.value.https_port
  origin_host_header = each.value.hostname
  priority           = each.value.priority
  weight             = each.value.weight
}

resource "azurerm_cdn_frontdoor_endpoint" "front_door_endpoint" {
  for_each                 = local.frontdoor_origin_groups_and_routes
  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile[split("-", each.key)[0]].id
}

resource "azurerm_cdn_frontdoor_custom_domain" "front_door_custom_domain" {
  for_each                 = local.custom_domains
  name                     = replace(each.value.domain, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile[each.value.profile].id
  host_name                = each.value.domain

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "frontdoor_route" {
  for_each                      = local.frontdoor_origin_groups_and_routes
  name                          = "${each.key}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.front_door_endpoint[each.key].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group[each.key].id
  cdn_frontdoor_origin_ids      = [for frontdoor_origin, frontdoor_origin_details in each.value.origins : azurerm_cdn_frontdoor_origin.front_door_origin["${each.key}-${frontdoor_origin}"].id]
  enabled                       = each.value.route_enabled

  forwarding_protocol    = each.value.forwarding_protocol
  https_redirect_enabled = each.value.https_redirect_enabled
  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = each.value.supported_protocols

  cdn_frontdoor_custom_domain_ids = [for domain in toset(each.value.custom_domain_names) : azurerm_cdn_frontdoor_custom_domain.front_door_custom_domain["${each.key}*${domain}"].id]
  link_to_default_domain          = each.value.route_link_to_domain

  dynamic "cache" {
    for_each = each.value.caching_enabled ? [1] : []
    content {
      query_string_caching_behavior = each.value.caching_query_string_caching_behavior
      query_strings                 = each.value.caching_query_strings
      compression_enabled           = each.value.caching_compression_enabled
      content_types_to_compress     = each.value.content_types_to_compress
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "frontdoor_custom_domain_association" {
  for_each                       = local.custom_domains
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.front_door_custom_domain[each.key].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.frontdoor_route[split("*", each.key)[0]].id]
}
