terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.40.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_public_ip" "gw" {
  name                = "${var.name}-gw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_public_ip" "gw_aa" {
  count               = var.active_active ? 1 : 0
  name                = "${var.name}-gw-aa-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_virtual_network_gateway" "gw" {
  name                = "${var.name}-gw"
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = var.active_active
  enable_bgp    = var.enable_bgp
  sku           = var.sku

  ip_configuration {
    name                          = "${var.name}-gw-config"
    public_ip_address_id          = azurerm_public_ip.gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }

  dynamic "ip_configuration" {
    for_each = var.active_active ? [true] : []
    content {
      name                          = "${var.name}-gw-aa-config"
      public_ip_address_id          = azurerm_public_ip.gw_aa[0].id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = var.subnet_id
    }
  }

  dynamic "vpn_client_configuration" {
    for_each = var.client_configuration != null ? [var.client_configuration] : []
    iterator = vpn
    content {
      address_space = [vpn.value.address_space]

      root_certificate {
        name = "VPN-Certificate"

        public_cert_data = vpn.value.certificate
      }

      vpn_client_protocols = vpn.value.protocols
    }
  }

  # TODO Buggy... keep want to change this attribute
  lifecycle {
    ignore_changes = [vpn_client_configuration[0].root_certificate]
  }

}

resource "azurerm_local_network_gateway" "local" {
  count               = length(var.local_networks)
  name                = "${var.local_networks[count.index].name}-lng"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = var.local_networks[count.index].gateway_address
  address_space       = var.local_networks[count.index].address_space
}

resource "azurerm_virtual_network_gateway_connection" "local" {
  count                      = length(var.local_networks)
  name                       = "${var.local_networks[count.index].name}-lngc"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  connection_protocol        = "IKEv2"
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.local[count.index].id

  shared_key = var.local_networks[count.index].shared_key

  dynamic "ipsec_policy" {
    for_each = var.local_networks[count.index].ipsec_policy != null ? [true] : []
    content {
      dh_group         = var.local_networks[count.index].ipsec_policy.dh_group
      ike_encryption   = var.local_networks[count.index].ipsec_policy.ike_encryption
      ike_integrity    = var.local_networks[count.index].ipsec_policy.ike_integrity
      ipsec_encryption = var.local_networks[count.index].ipsec_policy.ipsec_encryption
      ipsec_integrity  = var.local_networks[count.index].ipsec_policy.ipsec_integrity
      pfs_group        = var.local_networks[count.index].ipsec_policy.pfs_group
      sa_datasize      = var.local_networks[count.index].ipsec_policy.sa_datasize
      sa_lifetime      = var.local_networks[count.index].ipsec_policy.sa_lifetime
    }
  }
}