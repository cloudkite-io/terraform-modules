# Terraform Azure Eventhubs module

This Terraform module creates Azure eventhub namespace & event hub,
It also provides capability to add private endpoint / network access.

<!-- markdownlint-disable MD013 MD033 -->
```shell
module "event_hubs" {
  source              = "git::https://github.com/cloudkite-io/terraform-modules.git//modules/azure/event_hubs?ref=events-hub-module"
  location            = "us-east-1"
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
      private_endpoint = {
        enabled = true
      }
      network_rules = {
        subnet_ids                     = []
        ip_rules                       = []
        public_network_access_enabled  = false
        trusted_service_access_enabled = false
      }
      event_hubs = {
        test_topic = {
          partition_count   = 3
          message_retention = 7
        }
      }

    }
  }
  vnet_name   = "example-vnet"
  subnet_name = "example-subnet"
  environment = "example-env"
}
```

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
| [azurerm_eventhub_namespace.events](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_key_vault_secret.connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.private_endpoint_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_private_dns_zone.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.private_dns_zone_vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_subnet.private_endpoint_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.private_endpoint_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment like: infra-ops, dev, stage, prod | `string` | n/a | yes |
| <a name="input_event_hubs_namespaces"></a> [event\_hubs\_namespaces](#input\_event\_hubs\_namespaces) | Azure event hub configurations | <pre>map(object({<br>    sku            = string<br>    capacity       = number<br>    zone_redundant = bool<br>    auto_inflate = object({<br>      enabled                  = bool<br>      maximum_throughput_units = number<br>    })<br>    network_rules = object({<br>      ip_rules                       = list(string)<br>      subnet_ids                     = list(string)<br>      public_network_access_enabled  = bool<br>      trusted_service_access_enabled = bool<br>    })<br>    private_endpoint = object({<br>      enabled = bool<br>    })<br>    event_hubs = map(object({<br>      message_retention = number<br>      partition_count   = number<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | Id of the Keyvault where event hub primary connection strings are stored | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure location | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure resource group name | `string` | n/a | yes |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Name of the subnet on which private link is to be setup | `string` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name of the vnet on which private link is to be setup | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
