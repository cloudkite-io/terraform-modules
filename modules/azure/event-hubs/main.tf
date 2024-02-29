resource "azurerm_eventhub_namespace" "events" {
  name                = "${var.environment}-ns"
  location            = azurerm_resource_group.events.location
  resource_group_name = var.resource_group_name
  sku                 = var.event_hub.sku
  capacity            = var.event_hub.capacity

  auto_inflate_enabled     = var.event_hub.auto_inflate != null ? var.event_hub.auto_inflate.enabled : null
  maximum_throughput_units = var.event_hub.auto_inflate != null ? var.event_hub.auto_inflate.maximum_throughput_units : null

  dynamic "network_rulesets" {
    for_each = var.event_hub.network_rules != null ? ["true"] : []
    content {
      default_action = "Deny"

      dynamic "ip_rule" {
        for_each = var.event_hub.network_rules.ip_rules
        iterator = iprule
        content {
          ip_mask = iprule.value
        }
      }

      dynamic "virtual_network_rule" {
        for_each = var.event_hub.network_rules.subnet_ids
        iterator = subnet
        content {
          subnet_id = subnet.value
        }
      }
    }
  }
}
