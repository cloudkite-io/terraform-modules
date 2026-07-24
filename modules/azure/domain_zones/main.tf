resource "azurerm_dns_zone" "domain_zone" {
  for_each            = toset(var.dns_domain_zones)
  name                = each.key
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_a_record" "dns_a_records" {
  for_each            = var.dns_a_records
  name                = split(".", each.key)[0]
  zone_name           = join(".", slice(split(".", each.key), 1, length(split(".", each.key))))
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = each.value.records
  depends_on = [
    azurerm_dns_zone.domain_zone
  ]
}

resource "azurerm_dns_aaaa_record" "dns_aaaa_records" {
  for_each            = var.dns_aaaa_records
  name                = split(".", each.key)[0]
  zone_name           = join(".", slice(split(".", each.key), 1, length(split(".", each.key))))
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = each.value.records
  depends_on = [
    azurerm_dns_zone.domain_zone
  ]
}

resource "azurerm_dns_cname_record" "dns_cname_records" {
  for_each            = var.dns_cname_records
  name                = split(".", each.key)[0]
  zone_name           = join(".", slice(split(".", each.key), 1, length(split(".", each.key))))
  resource_group_name = var.resource_group_name
  ttl                 = 300
  record              = each.value.record
  depends_on = [
    azurerm_dns_zone.domain_zone
  ]
}

resource "azurerm_private_dns_zone" "private_domain_zone" {
  for_each            = toset(var.private_dns_domain_zones)
  name                = each.key
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_a_record" "private_dns_a_records" {
  for_each            = var.private_dns_a_records
  name                = split(".", each.key)[0]
  zone_name           = join(".", slice(split(".", each.key), 1, length(split(".", each.key))))
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = each.value.records
  depends_on = [
    azurerm_private_dns_zone.private_domain_zone
  ]
}

resource "azurerm_private_dns_aaaa_record" "private_dns_aaaa_records" {
  for_each            = var.private_dns_aaaa_records
  name                = split(".", each.key)[0]
  zone_name           = join(".", slice(split(".", each.key), 1, length(split(".", each.key))))
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = each.value.records
  depends_on = [
    azurerm_private_dns_zone.private_domain_zone
  ]
}

resource "azurerm_private_dns_cname_record" "private_dns_cname_records" {
  for_each            = var.private_dns_cname_records
  name                = split(".", each.key)[0]
  zone_name           = join(".", slice(split(".", each.key), 1, length(split(".", each.key))))
  resource_group_name = var.resource_group_name
  ttl                 = 300
  record              = each.value.record
  depends_on = [
    azurerm_private_dns_zone.private_domain_zone
  ]
}
