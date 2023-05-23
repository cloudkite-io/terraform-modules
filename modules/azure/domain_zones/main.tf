resource "azurerm_dns_zone" "domain_zone" {
  for_each            = toset(var.dns_domain_zones)
  name                = each.key
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_a_record" "dns_a_records" {
  for_each            = var.dns_a_records
  name                = each.key
  zone_name           = each.value.zone
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = each.value.records
  depends_on = [
    azurerm_dns_zone.domain_zone
  ]
}

resource "azurerm_dns_cname_record" "dns_cname_records" {
  for_each            = var.dns_cname_records
  name                = each.key
  zone_name           = each.value.zone
  resource_group_name = var.resource_group_name
  ttl                 = 300
  record              = "${each.key}.${each.value.record}"
  depends_on = [
    azurerm_dns_zone.domain_zone
  ]
}
