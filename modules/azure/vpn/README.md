# terraform module for azure s2s and p2s vpn

example using static routes for s2svpn

<!-- markdownlint-disable MD013 MD033 -->
```shell
module "s2svpn" {
  source              = "git::https://github.com/cloudkite-io/terraform-modules.git//modules/azure/s2svpn?ref=v0.1.4"
  name                = "vpn"
  resource_group_name = "sample-resource-group"
  location            = "eastus"
  subnet_id           = "/subscriptions/{Subscription ID}/resourceGroups/MyResourceGroup.providers/Microsoft.Network/virtualNetworks/MyNet/subnets/MySubnet"
  sku                 = "VpnGw1"
  enable_bgp          = false
  active_active       = false
  local_networks      =
  local_networks = [
    {
      name            = "onpremise"
      #on-premise gateway address
      gateway_address = "8.8.8.8"
      address_space = [
        "10.0.0.0/8"
      ]
      #pre-shared key must be similar to on-premise key
      shared_key = "TESTING"

      ipsec_policy = {
        dh_group         = "DHGroup14"
        ike_encryption   = "AES256"
        ike_integrity    = "SHA256"
        ipsec_encryption = "AES256"
        ipsec_integrity  = "SHA256"
        pfs_group        = "PFS2048"
        sa_datasize      = "1024"
        sa_lifetime      = "3600"
      }
    },
  ]

}
```

example for p2svpn

```shell
module "p2svpn" {
    source              = "git::https://github.com/cloudkite-io/terraform-modules.git//modules/azure/vpn?ref=0.1.7"
    name                = "${var.environment}-vpn"
    resource_group_name = var.azure.resource_group_name
    sku                 = var.vpn.sku
    location            = var.azure.location
    subnet_id           = module.networking.vnet_subnets["GatewaySubnet"].id
    client_configuration = {
        protocols   = var.vpn.p2s.protocols
        auth_types  = var.vpn.p2s.auth_types
        address_space = var.vpn.p2s.address_space
        certificate = data.azurerm_key_vault_secret.secrets["P2S-VPN-DEVICES-ROOT-CERTIFICATE"].value
    }
}

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.40.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.40.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_local_network_gateway.local](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway) | resource |
| [azurerm_public_ip.gw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.gw_aa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_network_gateway.gw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) | resource |
| [azurerm_virtual_network_gateway_connection.local](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_active_active"></a> [active\_active](#input\_active\_active) | If true, an active-active Virtual Network Gateway will be created. An active-active gateway requires a HighPerformance or an UltraPerformance sku. If false, an active-standby gateway will be created. Defaults to false. | `bool` | `false` | no |
| <a name="input_client_configuration"></a> [client\_configuration](#input\_client\_configuration) | If set it will activate point-to-site configuration. | <pre>object({<br>    address_space = list(string)<br>    protocols     = list(string)<br>    certificate   = string<br>    auth_types    = list(string)<br>    revoked_certificates = optional(map(object({<br>      name       = string<br>      thumbprint = string<br>    })), {})<br>  })</pre> | `null` | no |
| <a name="input_enable_bgp"></a> [enable\_bgp](#input\_enable\_bgp) | If true, BGP (Border Gateway Protocol) will be enabled for this Virtual Network Gateway. Defaults to false. | `bool` | `false` | no |
| <a name="input_local_networks"></a> [local\_networks](#input\_local\_networks) | List of local virtual network connections to connect to gateway. | <pre>list(<br>    object({<br>      name            = string<br>      gateway_address = string<br>      address_space   = list(string)<br>      shared_key      = string<br>      ipsec_policy    = any<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure Region in which to create resource. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of virtual gateway. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of resource group to deploy resources in. | `string` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | Configuration of the size and capacity of the virtual network gateway. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Id of subnet where gateway should be deployed, have to be named GatewaySubnet. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fqdns"></a> [fqdns](#output\_fqdns) | List of the fqdn for gateway. Will return 2 for active\_active mode and 1 otherwise |
| <a name="output_gateway_id"></a> [gateway\_id](#output\_gateway\_id) | The ID of the virtual network gateway. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
