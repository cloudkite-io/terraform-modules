locals {
  event_hub_ns_subnets = merge([
    for event_hub_ns, event_hub_ns_details in var.event_hubs_namespaces : {
      for subnet, subnet_details in event_hub_ns_details.subnets :
      "${event_hub_ns}-${subnet_details.vnet_name}-${subnet_details.resource_group_name}-${subnet_details.location}-${subnet}" => {
        namespace               = event_hub_ns
        subnet_name             = subnet
        vnet_name               = subnet_details.vnet_name
        resource_group_name     = subnet_details.resource_group_name
        location                = subnet_details.location
        key_vault               = subnet_details.key_vault_name
        create_private_endpoint = subnet_details.create_private_endpoint
      }
    }
  ]...)
  subnets_no_private_endpoint = merge([
    for event_hub_ns, event_hub_ns_details in var.event_hubs_namespaces : {
      for subnet, subnet_details in event_hub_ns_details.subnets :
      event_hub_ns => [subnet]...
      if subnet_details.create_private_endpoint == false
    }
  ]...)

}

data "azurerm_subnet" "private_endpoint_subnet" {
  for_each             = local.event_hub_ns_subnets
  name                 = each.value.subnet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.resource_group_name
}

resource "azurerm_eventhub_namespace" "events" {
  for_each                      = var.event_hubs_namespaces
  name                          = each.value.override_name != null ? each.value.override_name : "${each.key}-ns"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = each.value.sku
  capacity                      = each.value.capacity
  auto_inflate_enabled          = each.value.sku == "Standard" ? each.value.auto_inflate.enabled : false
  maximum_throughput_units      = each.value.auto_inflate.enabled && each.value.sku == "Standard" ? each.value.auto_inflate.maximum_throughput_units : null
  zone_redundant                = each.value.zone_redundant
  public_network_access_enabled = length(each.value.ip_rules) > 0 || length(lookup(local.subnets_no_private_endpoint, each.key, [])) > 0 ? true : each.value.public_network_access_enabled

  network_rulesets {
    default_action                 = each.value.public_network_access_enabled ? "Allow" : "Deny"
    public_network_access_enabled  = length(each.value.ip_rules) > 0 || length(lookup(local.subnets_no_private_endpoint, each.key, [])) > 0 ? true : each.value.public_network_access_enabled
    trusted_service_access_enabled = each.value.trusted_service_access_enabled

    ip_rule = [
      for ip in each.value.ip_rules : {
        action  = "Allow"
        ip_mask = ip
      }
    ]

    virtual_network_rule = [
      for subnet, subnet_details in each.value.subnets : {
        ignore_missing_virtual_network_service_endpoint = false
        subnet_id                                       = data.azurerm_subnet.private_endpoint_subnet["${each.key}-${subnet_details.vnet_name}-${subnet_details.resource_group_name}-${subnet_details.location}-${subnet}"].id
      }
      if subnet_details.create_private_endpoint == false
    ]
  }

  lifecycle {
    ignore_changes = [
      capacity,
    ]
  }
}

locals {
  public_uri_key_vault_ids = merge([
    for event_hub_ns, event_hub_ns_details in var.event_hubs_namespaces : {
      for key_vault, key_vault_details in event_hub_ns_details.public_uri_key_vaults :
      "${event_hub_ns}-${key_vault}" => {
        namespace           = event_hub_ns
        key_vault           = key_vault
        resource_group_name = key_vault_details.resource_group_name
      }
    }
  ]...)
}

data "azurerm_key_vault" "public_uri_key_vaults" {
  for_each            = local.public_uri_key_vault_ids
  name                = each.value.key_vault
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_key_vault_secret" "connection_string" {
  for_each     = local.public_uri_key_vault_ids
  key_vault_id = data.azurerm_key_vault.public_uri_key_vaults[each.key].id
  name         = upper("${each.value.namespace}-NS-DEFAULT-PRIMARY-CONNECTION-STRING-EVENT-HUB-URI")
  value        = azurerm_eventhub_namespace.events[each.value.namespace].default_primary_connection_string
}

data "azurerm_virtual_network" "private_endpoint_virtual_network" {
  for_each = {
    for ehns_key, ehns_details in local.event_hub_ns_subnets :
    ehns_key => ehns_details
    if ehns_details.create_private_endpoint
  }
  name                = each.value.vnet_name
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_private_dns_zone" "private_endpoint" {
  for_each = {
    for ehns_key, ehns_details in local.event_hub_ns_subnets :
    ehns_key => ehns_details
    if ehns_details.create_private_endpoint
  }
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_link" {
  for_each = {
    for ehns_key, ehns_details in local.event_hub_ns_subnets :
    ehns_key => ehns_details
    if ehns_details.create_private_endpoint
  }
  name                  = "private-link-${each.value.vnet_name}-vnetlink"
  resource_group_name   = each.value.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_endpoint[each.key].name
  virtual_network_id    = data.azurerm_virtual_network.private_endpoint_virtual_network[each.key].id
}

resource "azurerm_private_endpoint" "private_endpoint" {
  for_each = {
    for ehns_key, ehns_details in local.event_hub_ns_subnets :
    ehns_key => ehns_details
    if ehns_details.create_private_endpoint
  }
  name                = "${each.value.vnet_name}-event-hub-ns-endpoint"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  subnet_id           = data.azurerm_subnet.private_endpoint_subnet[each.key].id

  private_service_connection {
    name                           = "${each.value.vnet_name}-privateserviceconnection"
    private_connection_resource_id = azurerm_eventhub_namespace.events[each.value.namespace].id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "${each.value.vnet_name}-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_endpoint[each.key].id]
  }
}

data "azurerm_key_vault" "private_uri_key_vaults" {
  for_each = {
    for ehns_key, ehns_details in local.event_hub_ns_subnets :
    ehns_key => ehns_details
    if ehns_details.create_private_endpoint && ehns_details.key_vault != null
  }
  name                = each.value.key_vault
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_key_vault_secret" "private_endpoint_connection_string" {
  for_each = {
    for ehns_key, ehns_details in local.event_hub_ns_subnets :
    ehns_key => ehns_details
    if ehns_details.create_private_endpoint && ehns_details.key_vault != null
  }
  key_vault_id = data.azurerm_key_vault.private_uri_key_vaults[each.key].id
  name         = upper("${each.value.namespace}-NS-DEFAULT-PRIMARY-CONNECTION-STRING-EVENT-HUB-PRIVATE-LINK-URI")
  value        = "Endpoint=sb://${azurerm_private_endpoint.private_endpoint[each.key].private_dns_zone_configs[0].record_sets[0].fqdn}/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${azurerm_eventhub_namespace.events[each.value.namespace].default_primary_key}"
}

locals {
  event_hubs = merge([
    for event_hub_ns, event_hub_ns_details in var.event_hubs_namespaces : {
      for event_hub, event_hub_details in event_hub_ns_details.event_hubs :
      "${event_hub_ns}-${event_hub}" => {
        name                          = event_hub
        namespace                     = event_hub_ns
        partition_count               = event_hub_details.partition_count
        message_retention             = event_hub_details.message_retention
        public_network_access_enabled = event_hub_ns_details.public_network_access_enabled
        public_uri_key_vaults         = event_hub_ns_details.public_uri_key_vaults
        authorization_rules           = event_hub_details.authorization_rules
        subnets                       = event_hub_ns_details.subnets
      }
    }
  ]...)
}

resource "azurerm_eventhub" "event_hub" {
  for_each            = local.event_hubs
  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.events[each.value.namespace].name
  resource_group_name = var.resource_group_name
  partition_count     = each.value.partition_count
  message_retention   = each.value.message_retention
}

locals {
  authorization_rules = merge([
    for event_hub_key, event_hub_details in local.event_hubs : {
      for auth_rule, auth_rule_details in event_hub_details.authorization_rules :
      "${event_hub_key}-${auth_rule}" => {
        event_hub_key                 = event_hub_key
        namespace                     = event_hub_details.namespace
        hub_name                      = event_hub_details.name
        public_network_access_enabled = event_hub_details.public_network_access_enabled
        public_uri_key_vaults         = event_hub_details.public_uri_key_vaults
        name                          = auth_rule
        listen                        = auth_rule_details.listen
        send                          = auth_rule_details.send
        manage                        = auth_rule_details.manage
        subnets                       = event_hub_details.subnets
      }
    }
  ]...)
}

resource "azurerm_eventhub_authorization_rule" "authorization_rules" {
  for_each            = local.authorization_rules
  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.events[each.value.namespace].name
  eventhub_name       = azurerm_eventhub.event_hub[each.value.event_hub_key].name
  resource_group_name = var.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}

locals {
  public_authorization_rules = merge([
    for auth_rule_key, auth_rule_details in local.authorization_rules : {
      for key_vault, key_vault_details in auth_rule_details.public_uri_key_vaults :
      "${auth_rule_key}-${key_vault}" => {
        auth_rule_key                 = auth_rule_key
        namespace                     = auth_rule_details.namespace
        hub_name                      = auth_rule_details.hub_name
        name                          = auth_rule_details.name
        key_vault                     = key_vault
        key_vault_resource_group_name = key_vault_details.resource_group_name
      }
    }
  ]...)
}

data "azurerm_key_vault" "hub_specific_key_vaults" {
  for_each            = local.public_authorization_rules
  name                = each.value.key_vault
  resource_group_name = each.value.key_vault_resource_group_name
}

resource "azurerm_key_vault_secret" "hub_specific_connection_string" {
  for_each     = local.public_authorization_rules
  key_vault_id = data.azurerm_key_vault.hub_specific_key_vaults[each.key].id
  name         = upper("${each.value.namespace}-NS-${each.value.hub_name}-HUB-${each.value.name}-RULE-PUBLIC-EVENT-HUB-URI")
  value        = azurerm_eventhub_authorization_rule.authorization_rules[each.value.auth_rule_key].primary_connection_string
}

locals {
  private_authorization_rules = merge([
    for auth_rule_key, auth_rule_details in local.authorization_rules : {
      for subnet, subnet_details in auth_rule_details.subnets :
      "${auth_rule_key}-${subnet}" => {
        auth_rule_key            = auth_rule_key
        event_hub_ns_subnets_key = "${auth_rule_details.namespace}-${subnet_details.vnet_name}-${subnet_details.resource_group_name}-${subnet_details.location}-${subnet}"
        namespace                = auth_rule_details.namespace
        hub_name                 = auth_rule_details.hub_name
        name                     = auth_rule_details.name
        subnet_name              = subnet
        resource_group_name      = subnet_details.resource_group_name
        key_vault                = subnet_details.key_vault_name
      }
      if subnet_details.create_private_endpoint && subnet_details.key_vault_name != null
    }
  ]...)
}

data "azurerm_key_vault" "hub_specific_private_endpoint_key_vaults" {
  for_each            = local.private_authorization_rules
  name                = each.value.key_vault
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_key_vault_secret" "private_endpoint_hub_specific_connection_string" {
  for_each     = local.private_authorization_rules
  key_vault_id = data.azurerm_key_vault.hub_specific_private_endpoint_key_vaults[each.key].id
  name         = upper("${each.value.namespace}-NS-${each.value.hub_name}-HUB-${each.value.name}-RULE-EVENT-HUB-PRIVATE-LINK-URI")
  value        = "Endpoint=sb://${azurerm_private_endpoint.private_endpoint[each.value.event_hub_ns_subnets_key].private_dns_zone_configs[0].record_sets[0].fqdn}/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${azurerm_eventhub_authorization_rule.authorization_rules[each.value.auth_rule_key].primary_key}"
}
