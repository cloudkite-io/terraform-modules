# terraform module for azure site to site vpn

example using static routes

```shell
module "s2svpn-legacy" {
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
