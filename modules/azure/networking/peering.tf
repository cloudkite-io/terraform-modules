locals {
  dns_zone_links = merge([
    for peering_key, peering_value in var.peering :
    {
      for dns_link in coalesce(peering_value.private_dns_links, []) :
      "${peering_key}-peering" => {
        peering_key               = peering_key
        dns_link                  = dns_link
        remote_virtual_network_id = peering_value.remote_virtual_network_id
      }
    }
  ]...)
}

resource "azurerm_virtual_network_peering" "network_peering" {
  for_each                     = var.peering
  name                         = each.key
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  allow_virtual_network_access = each.value.allow_virtual_network_access
  use_remote_gateways          = each.value.use_remote_gateways
  local_subnet_names           = each.value.local_subnet_names
  remote_subnet_names          = each.value.remote_subnet_names
  lifecycle {
    ignore_changes = [
      local_subnet_names,
      remote_subnet_names
    ]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "peering_private_dns_vnet_link" {
  for_each              = local.dns_zone_links
  name                  = each.key
  private_dns_zone_name = each.value.dns_link
  virtual_network_id    = each.value.remote_virtual_network_id
  resource_group_name   = var.resource_group_name
}
