locals {
  event_hubs = merge([
    for event_hub_ns, event_hub_ns_details in var.event_hubs_namespaces : {
      for event_hub, event_hub_details in event_hub_ns_details.event_hubs :
      "${event_hub_ns}-${event_hub}" => {
        name              = event_hub
        namespace         = event_hub_ns
        partition_count   = event_hub_details.partition_count
        message_retention = event_hub_details.message_retention
      }

    }
  ]...)
}


resource "azurerm_eventhub_namespace" "events" {
  for_each                      = var.event_hubs_namespaces
  name                          = "${each.key}-ns"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = each.value.sku
  capacity                      = each.value.capacity
  auto_inflate_enabled          = each.value.auto_inflate.enabled
  maximum_throughput_units      = each.value.auto_inflate.enabled ? each.value.auto_inflate.maximum_throughput_units : null
  zone_redundant                = each.value.zone_redundant
  public_network_access_enabled = each.value.network_rules.public_network_access_enabled
  network_rulesets {
    default_action                 = "Deny"
    public_network_access_enabled  = each.value.network_rules.public_network_access_enabled
    trusted_service_access_enabled = each.value.network_rules.trusted_service_access_enabled

    ip_rule = [
      for ip in each.value.network_rules.ip_rules : {
        action  = "Allow"
        ip_mask = ip
      }
    ]

    virtual_network_rule = [
      for subnet_id in each.value.network_rules.subnet_ids : {
        ignore_missing_virtual_network_service_endpoint = false
        #TODO: pass subnet_name and resource_group_name and get subnet_id from data objects
        subnet_id = subnet_id
      }
    ]
  }
}

data "azurerm_subnet" "private_endpoint_subnet" {
  count = anytrue([for event_hub_ns, event_hub_ns-details in var.event_hubs_namespaces :
  event_hub_ns-details.private_endpoint.enabled]) ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

data "azurerm_virtual_network" "private_endpoint_virtual_network" {
  count = anytrue([for event_hub_ns, event_hub_ns-details in var.event_hubs_namespaces :
  event_hub_ns-details.private_endpoint.enabled]) ? 1 : 0
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "private_endpoint" {
  count = anytrue([for event_hub_ns, event_hub_ns-details in var.event_hubs_namespaces :
  event_hub_ns-details.private_endpoint.enabled]) ? 1 : 0
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_link" {
  count = anytrue([for event_hub_ns, event_hub_ns-details in var.event_hubs_namespaces :
  event_hub_ns-details.private_endpoint.enabled]) ? 1 : 0
  name                  = "private-link-${var.environment}-vnetlink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_endpoint[count.index].name
  virtual_network_id    = data.azurerm_virtual_network.private_endpoint_virtual_network[count.index].id
}

resource "azurerm_private_endpoint" "private_endpoint" {
  for_each = { for event_hub_ns, event_hub_ns-details in var.event_hubs_namespaces :
  event_hub_ns => event_hub_ns-details if event_hub_ns-details.private_endpoint.enabled }
  name                = "${each.key}-event-hub-ns-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.private_endpoint_subnet[0].id

  private_service_connection {
    name                           = "${each.key}-privateserviceconnection"
    private_connection_resource_id = azurerm_eventhub_namespace.events[each.key].id
    is_manual_connection           = false
    subresource_names              = ["namespace"]

  }
  private_dns_zone_group {
    name                 = "${each.key}-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_endpoint[0].id]
  }
}

resource "azurerm_eventhub" "event_hub" {
  for_each            = local.event_hubs
  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.events[each.value.namespace].name
  resource_group_name = var.resource_group_name
  partition_count     = each.value.partition_count
  message_retention   = each.value.message_retention
}
