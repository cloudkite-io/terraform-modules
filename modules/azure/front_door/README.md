# Terraform Azure FrontDoor module

This Terraform module creates Azure frontdoor profile,origin groups,
origins, custom domains & routes.

<!-- markdownlint-disable MD013 MD033 -->
```shell
module "front_door" {
  source              = "git::https://github.com/cloudkite-io/terraform-modules.git//modules/azure/front_door?ref=add-azure-front-door-module"
  resource_group_name = "example-resource-group"
  event_hubs_namespaces = dev = {
    sku_name                 = "Standard_AzureFrontDoor"
    response_timeout_seconds = 120
    routes = {
      azureadb2c = {
        origin_group = {
          health_probe_enabled   = false
          origins = {
          azureadb2c = {
            hostname           = "bar.domain.com"
            origin_host_header = "bar.domain.com"
          }
        }
        }

      supported_protocols = ["Http", "Https"]
      patterns_to_match   = ["/*"]
      custom_domain_names = ["foo.example.com"]
      }


    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.53.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.53.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_cdn_frontdoor_custom_domain.front_door_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_custom_domain_association.frontdoor_custom_domain_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association) | resource |
| [azurerm_cdn_frontdoor_endpoint.front_door_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_origin.front_door_origin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.frontdoor_profile](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.frontdoor_route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_frontdoor_profiles"></a> [frontdoor\_profiles](#input\_frontdoor\_profiles) | Frontdoor configurations | <pre>map(object({<br>    sku_name                 = string<br>    response_timeout_seconds = number<br>    routes = map(object({<br>      origin_group = object({<br>        session_affinity_enabled                          = optional(bool, true)<br>        health_probe_enabled                              = optional(bool, false)<br>        health_probe_interval_in_seconds                  = optional(number, 240)<br>        health_probe_path                                 = optional(string, "/")<br>        heath_probe_protocol                              = optional(string, "Https")<br>        health_probe_request_type                         = optional(string, "HEAD")<br>        restore_traffic_to_healed_or_new_endpoint         = optional(number)<br>        load_balancing_additional_latency_in_milliseconds = optional(number, 50)<br>        load_balancing_sample_size                        = optional(number, 4)<br>        load_balancing_successful_sample_required         = optional(number, 3)<br>        origins = map(object({<br>          enabled                        = optional(bool, true)<br>          certificate_name_check_enabled = optional(bool, false)<br>          hostname                       = string<br>          http_port                      = optional(number, 80)<br>          https_port                     = optional(number, 443)<br>          origin_host_header             = string<br>          priority                       = optional(number, 1)<br>          weight                         = optional(number, 1)<br>        }))<br>      })<br>      route_enabled                         = optional(bool, true)<br>      forwarding_protocol                   = optional(string, "MatchRequest")<br>      https_redirect_enabled                = optional(bool, true)<br>      patterns_to_match                     = list(string)<br>      supported_protocols                   = list(string)<br>      route_link_to_domain                  = optional(bool, false)<br>      custom_domain_names                   = list(string)<br>      caching_enabled                       = optional(bool, false)<br>      caching_query_string_caching_behavior = optional(string)<br>      caching_query_strings                 = optional(list(string))<br>      caching_compression_enabled           = optional(bool, true)<br>      caching_content_types_to_compress     = optional(list(string))<br><br>    }))<br><br>    })<br>  )</pre> | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure resource group name | `string` | n/a | yes |

## Outputs

No outputs.
