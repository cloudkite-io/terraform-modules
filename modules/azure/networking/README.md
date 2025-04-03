# Terraform Azure Networking

This Terraform module creates a Virtual Network in Azure with a set of subnets
passed in as input parameters.

The module does not create nor expose a security group. This would need to be
defined separately as additional security rules on subnets in the created
network.

<!-- markdownlint-disable MD013 MD033 -->

```shell
module "networking" {
  source              = "git@github.com:cloudkite-io/terraform-modules.git//modules/azure/networking?ref=v0.1.5"
  environment         = "dev"
  resource_group_name = "sample-resource-group"
  vnet_name           = "dev-vnet"
  vnet_location       = "eastus"
  vnet_address_space  = ["10.10.0.0/16"] # Hosts: 10.10.0.1 - 10.10.255.254, Broadcast: 10.10.255.255
  subnets             = {
    aks-subnet = {
      address_prefixes                          = ["10.10.0.0/17"] # Hosts: 10.10.0.1 - 10.10.127.254, Broadcast: 10.10.127.255
      enable_nat                                = true
      service_endpoints                         = []
      private_endpoint_network_policies_enabled = true
      delegations                               = {}
    }
    # Azure Gateway subnet name MUST be `GatewaySubnet`
    # Azure recommends its size to be `/27`
    # Source: https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#gwsub
    GatewaySubnet = {
      address_prefixes                          = ["10.10.128.0/27"] # Hosts: 10.10.128.1 - 10.10.128.30, Broadcast: 10.10.128.31
      enable_nat                                = false
      service_endpoints                         = []
      private_endpoint_network_policies_enabled = true
      delegations                               = {}
    }
    databases-subnet = {
      address_prefixes                          = ["10.10.129.0/24"] # Hosts: 10.10.129.1 - 10.10.129.254, Broadcast: 10.10.129.255
      enable_nat                                = false
      service_endpoints                         = ["Microsoft.Storage"]
      private_endpoint_network_policies_enabled = true
      delegations = {
        # only flexible-server instances can use this subnet
        postgres-delegation = {
          service_delegation_name    = "Microsoft.DBforPostgreSQL/flexibleServers"
          service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.105.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.105.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_nat_gateway.nat_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) | resource |
| [azurerm_nat_gateway_public_ip_association.nat_address_gateway_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_network_security_group.security_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_private_dns_zone_virtual_network_link.peering_private_dns_vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_public_ip.nat_address](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_route_table.route_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.subnet_nat_gateway_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_network_security_group_association.subnet_security_groups_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.subnet_route_table_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.network_peering](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Availability zones for nat gateway and public ips | `list(string)` | n/a | yes |
| <a name="input_ip_prefix"></a> [ip\_prefix](#input\_ip\_prefix) | Prefix of the nat public ip address | `string` | `""` | no |
| <a name="input_nat_prefix"></a> [nat\_prefix](#input\_nat\_prefix) | Prefix of the nat gateway & public ip address | `string` | `""` | no |
| <a name="input_peering"></a> [peering](#input\_peering) | Vnet Peering configuration | <pre>map(object({<br/>    remote_virtual_network_id    = optional(string)<br/>    allow_forwarded_traffic      = optional(bool, false)<br/>    allow_gateway_transit        = optional(bool, false)<br/>    allow_virtual_network_access = optional(bool, true)<br/>    use_remote_gateways          = optional(bool, false)<br/>    local_subnet_names           = optional(list(string))<br/>    remote_subnet_names          = optional(list(string))<br/>    private_dns_links            = optional(list(string))<br/>  }))</pre> | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure resource group name | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Azure subnets and their configuration | <pre>map(object({<br/>    address_prefixes                  = list(string)<br/>    enable_nat                        = bool<br/>    service_endpoints                 = list(string)<br/>    private_endpoint_network_policies = string # Allowed values: "Disabled", "Enabled", "NetworkSecurityGroupEnabled" and "RouteTableEnabled"<br/>    delegations = map(object({<br/>      service_delegation_name    = string<br/>      service_delegation_actions = list(string)<br/>    }))<br/>    security_rules = optional(map(object({<br/>      priority                              = number<br/>      direction                             = string<br/>      access                                = string<br/>      protocol                              = string<br/>      source_port_range                     = optional(string)<br/>      source_port_ranges                    = optional(list(string))<br/>      destination_port_range                = optional(string)<br/>      destination_port_ranges               = optional(list(string))<br/>      source_address_prefix                 = optional(string)<br/>      source_address_prefixes               = optional(list(string))<br/>      destination_address_prefix            = optional(string)<br/>      destination_address_prefixes          = optional(list(string))<br/>      source_application_security_group_ids = optional(list(string))<br/>    })), {})<br/>    routes = optional(map(object({<br/>      address_prefix         = string<br/>      next_hop_type          = string<br/>      next_hop_in_ip_address = optional(string)<br/>    })))<br/>  }))</pre> | n/a | yes |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | Address space for the virtual network | `list(string)` | n/a | yes |
| <a name="input_vnet_location"></a> [vnet\_location](#input\_vnet\_location) | Azure location for the virtual network | `string` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name for the virtual network | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vnet_address_space"></a> [vnet\_address\_space](#output\_vnet\_address\_space) | The address space of the newly created vNet |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | The id of the newly created vNet |
| <a name="output_vnet_location"></a> [vnet\_location](#output\_vnet\_location) | The location of the newly created vNet |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | The Name of the newly created vNet |
| <a name="output_vnet_subnets"></a> [vnet\_subnets](#output\_vnet\_subnets) | The properties of subnets created inside the newly created vNet |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
