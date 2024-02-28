resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.vnet_location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "subnets" {
  for_each                                  = var.subnets
  name                                      = each.key
  resource_group_name                       = var.resource_group_name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = each.value.address_prefixes
  service_endpoints                         = each.value.service_endpoints
  private_endpoint_network_policies_enabled = each.value.private_endpoint_network_policies_enabled
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
  name                = "nat-external-address-${count.index}"
  location            = var.vnet_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = "${var.environment}-nat-gateway"
  location                = var.vnet_location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
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
  subnet => subnet-details if subnet != "GatewaySubnet" }
  name                = "${each.key}-NSG"
  location            = var.vnet_location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.security_rules

    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }

  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_security_groups_association" {
  for_each = { for subnet, subnet-details in var.subnets :
  subnet => subnet-details if subnet != "GatewaySubnet" }
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.security_groups[each.key].id
}
