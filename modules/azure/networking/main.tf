resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.vnet_location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "subnets" {
  for_each                          = var.subnets
  name                              = each.key
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = each.value.service_endpoints
  private_endpoint_network_policies = each.value.private_endpoint_network_policies
  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.key
      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.service_delegation_actions
      }
    }
  }
}

resource "azurerm_public_ip" "nat_address" {
  count               = 2
  name                = "${var.nat_prefix}nat-external-address-${count.index}"
  location            = var.vnet_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = "${var.nat_prefix}nat-gateway"
  location                = var.vnet_location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = var.availability_zones
}

resource "azurerm_nat_gateway_public_ip_association" "nat_address_gateway_association" {
  count                = 2
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_address[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_nat_gateway_association" {
  for_each = {
    for subnet, subnet-details in var.subnets :
    subnet => subnet-details
    if subnet-details.enable_nat
  }
  subnet_id      = azurerm_subnet.subnets[each.key].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

resource "azurerm_network_security_group" "security_groups" {
  for_each = { for subnet, subnet-details in var.subnets :
  subnet => subnet-details if length(subnet-details.security_rules) > 0 }
  name                = "${each.key}-NSG"
  location            = var.vnet_location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.security_rules

    content {
      name                                  = security_rule.key
      priority                              = security_rule.value.priority
      direction                             = security_rule.value.direction
      access                                = security_rule.value.access
      protocol                              = security_rule.value.protocol
      source_port_range                     = security_rule.value.source_port_range
      source_port_ranges                    = security_rule.value.source_port_ranges
      destination_port_range                = security_rule.value.destination_port_range
      destination_port_ranges               = security_rule.value.destination_port_ranges
      source_address_prefix                 = security_rule.value.source_address_prefix
      source_address_prefixes               = security_rule.value.source_address_prefixes
      destination_address_prefix            = security_rule.value.destination_address_prefix
      destination_address_prefixes          = security_rule.value.destination_address_prefixes
      source_application_security_group_ids = security_rule.value.source_application_security_group_ids
    }

  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_security_groups_association" {
  for_each = { for subnet, subnet-details in var.subnets :
  subnet => subnet-details if length(subnet-details.security_rules) > 0 }
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.security_groups[each.key].id
}

resource "azurerm_route_table" "route_table" {
  for_each = { for subnet, subnet-details in var.subnets :
  subnet => subnet-details if length(subnet-details.routes) > 0 }
  name                = "${each.key}-RouteTable"
  location            = var.vnet_location
  resource_group_name = var.resource_group_name


  dynamic "route" {

    for_each = { for route, route-details in each.value.routes :
    route => route-details if route-details.next_hop_type != "VirtualAppliance" }

    content {
      name           = route.key
      address_prefix = route.value.address_prefix
      next_hop_type  = route.value.next_hop_type
    }

  }
  dynamic "route" {

    for_each = { for route, route-details in each.value.routes :
    route => route-details if route-details.next_hop_type == "VirtualAppliance" }

    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }

  }

}

resource "azurerm_subnet_route_table_association" "subnet_route_table_association" {
  for_each = { for subnet, subnet-details in var.subnets :
  subnet => subnet-details if length(subnet-details.routes) > 0 }
  subnet_id      = azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.route_table[each.key].id
}
