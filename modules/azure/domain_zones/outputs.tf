output "domain_zones" {
  description = "The properties for domain zones created by this module"
  value       = azurerm_dns_zone.domain_zone
}

output "dns_a_records" {
  description = "The properties of DNS A records created by this module"
  value       = azurerm_dns_a_record.dns_a_records
}

output "dns_cname_records" {
  description = "The properties of DNS CNAME records created by this module"
  value       = azurerm_dns_cname_record.dns_cname_records
}

output "private_domain_zones" {
  description = "The properties for private domain zones created by this module"
  value       = azurerm_private_dns_zone.private_domain_zone
}

output "private_dns_a_records" {
  description = "The properties of private DNS A records created by this module"
  value       = azurerm_private_dns_a_record.private_dns_a_records
}

output "private_dns_aaaa_records" {
  description = "The properties of private DNS AAAA records created by this module"
  value       = azurerm_private_dns_aaaa_record.private_dns_aaaa_records
}

output "private_dns_cname_records" {
  description = "The properties of private DNS CNAME records created by this module"
  value       = azurerm_private_dns_cname_record.private_dns_cname_records
}

output "dns_aaaa_records" {
  description = "The properties of DNS AAAA records created by this module"
  value       = azurerm_dns_aaaa_record.dns_aaaa_records
}
