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
