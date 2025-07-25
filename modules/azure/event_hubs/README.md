# Terraform Azure Eventhubs module

This Terraform module creates Azure eventhub namespace & event hub,
It also provides capability to add private endpoint / network access.

<!-- markdownlint-disable MD013 MD033 -->
```shell
module "event_hubs" {
  source              = "git::https://github.com/cloudkite-io/terraform-modules.git//modules/azure/event_hubs?ref=events-hub-module"
  location            = "eastus"
  resource_group_name = "example-resource-group"
  event_hubs_namespaces = {
    example_namespace = {
      sku            = "Standard"
      capacity       = 1
      zone_redundant = false
      auto_inflate = {
        enabled                  = true
        maximum_throughput_units = 2
      }
      subnets = {
        example_subnet = {
          resource_group_name = "example-resource-group"
          location            = "eastus"
          vnet_name           = "example-vnet"
        }
        example_subnet2 = {
          resource_group_name = "example-resource-group2"
          location            = "eastus2"
          vnet_name           = "example-vnet2"
        }
      }
      ip_rules                       = []
      public_network_access_enabled  = false
      trusted_service_access_enabled = false
      event_hubs = {
        test_topic = {
          partition_count   = 3
          message_retention = 7
          authorization_rules = {
            example_listen_rule = {
              listen = true
              send   = false
              manage = false
            }
            example_send_rule = {
              listen = false
              send   = true
              manage = false
            }
          }
        }
      }
    }
  }
}
```

## Notes

- Auto Inflate can only be enabled on Standard namespaces
- If you want to use private endpoint, you need to provide subnet details in
  the `subnets` block and you need to add `Microsoft.EventHub` as a
  service endpoint for the subnet.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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
| [azurerm_eventhub.event_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_authorization_rule.authorization_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_authorization_rule) | resource |
| [azurerm_eventhub_namespace.events](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_key_vault_secret.connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.hub_specific_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.private_endpoint_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.private_endpoint_hub_specific_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_private_dns_zone.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.private_dns_zone_vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_key_vault.hub_specific_key_vaults](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault.hub_specific_private_endpoint_key_vaults](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault.private_uri_key_vaults](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault.public_uri_key_vaults](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_subnet.event_hub_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.private_endpoint_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_event_hubs_namespaces"></a> [event\_hubs\_namespaces](#input\_event\_hubs\_namespaces) | Azure event hub configurations | <pre>map(object({<br/>    override_name  = optional(string, null)<br/>    sku            = string<br/>    capacity       = number<br/>    zone_redundant = bool<br/>    auto_inflate = object({<br/>      enabled                  = bool<br/>      maximum_throughput_units = number<br/>    })<br/>    public_network_access_enabled  = optional(bool, false)<br/>    trusted_service_access_enabled = optional(bool, false)<br/>    ip_rules                       = optional(list(string), [])<br/>    public_uri_key_vaults = optional(map(object({<br/>      resource_group_name = string<br/>    })), {})<br/>    subnets = optional(map(object({<br/>      vnet_name               = string<br/>      resource_group_name     = string<br/>      location                = string<br/>      key_vault_name          = optional(string, null)<br/>      create_private_endpoint = optional(bool, false)<br/>    })), {})<br/>    extra_subnet_ids_no_private_endpoint = optional(list(string), [])<br/>    event_hubs = map(object({<br/>      message_retention = number<br/>      partition_count   = number<br/>      authorization_rules = optional(map(object({<br/>        listen = optional(bool, false)<br/>        send   = optional(bool, false)<br/>        manage = optional(bool, false)<br/>        })),<br/>      {})<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure location | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure resource group name | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
