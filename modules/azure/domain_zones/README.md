# Terraform Azure Domain Zones

This Terraform module creates public and private Azure Domain Zones, `A`, `AAAA`
and `CNAME` records.

<!-- markdownlint-disable MD013 MD033 -->

```shell
module "domain_zones" {
  source              = "git@github.com:cloudkite-io/terraform-modules.git//modules/azure/domain_zones?ref=v0.1.5"
  resource_group_name = "sample-resource-group"
  dns_domain_zones    = ["example.com", "sub.example.com"]
  dns_a_records       = {
    "*" = {
      records = ["0.0.0.0"]
      zone    = "sub.example.com"
    }
  }
  dns_cname_records   = {
    "something" = {
      record = "_424c7224e9b0146f9a8808af955727d0.acm-validations.aws." # Example from: https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html
      zone   = "example.com"
    }
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.53.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.53.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_dns_a_record.dns_a_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_aaaa_record.dns_aaaa_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_aaaa_record) | resource |
| [azurerm_dns_cname_record.dns_cname_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_zone.domain_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) | resource |
| [azurerm_private_dns_a_record.private_dns_a_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_aaaa_record.private_dns_aaaa_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_aaaa_record) | resource |
| [azurerm_private_dns_cname_record.private_dns_cname_records](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_cname_record) | resource |
| [azurerm_private_dns_zone.private_domain_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.private_dns_zone_virtual_network_links](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_dns_a_records"></a> [dns\_a\_records](#input\_dns\_a\_records) | Map with dns A records to create and their configurations | <pre>map(object({<br/>    records = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_dns_aaaa_records"></a> [dns\_aaaa\_records](#input\_dns\_aaaa\_records) | Map with dns AAAA records to create and their configurations | <pre>map(object({<br/>    records = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_dns_cname_records"></a> [dns\_cname\_records](#input\_dns\_cname\_records) | Map with dns CNAME records to create and their configurations | <pre>map(object({<br/>    record = string<br/>  }))</pre> | `{}` | no |
| <a name="input_dns_domain_zones"></a> [dns\_domain\_zones](#input\_dns\_domain\_zones) | List of Top level domains to create | `list(string)` | `[]` | no |
| <a name="input_private_dns_a_records"></a> [private\_dns\_a\_records](#input\_private\_dns\_a\_records) | Map with private dns A records to create and their configurations | <pre>map(object({<br/>    records = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_private_dns_aaaa_records"></a> [private\_dns\_aaaa\_records](#input\_private\_dns\_aaaa\_records) | Map with private dns AAAA records to create and their configurations | <pre>map(object({<br/>    records = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_private_dns_cname_records"></a> [private\_dns\_cname\_records](#input\_private\_dns\_cname\_records) | Map with private dns CNAME records to create and their configurations | <pre>map(object({<br/>    record = string<br/>  }))</pre> | `{}` | no |
| <a name="input_private_dns_domain_zones"></a> [private\_dns\_domain\_zones](#input\_private\_dns\_domain\_zones) | List of private top level domains to create | `list(string)` | `[]` | no |
| <a name="input_private_dns_zone_virtual_network_links"></a> [private\_dns\_zone\_virtual\_network\_links](#input\_private\_dns\_zone\_virtual\_network\_links) | Map with private DNS zone virtual network links to create | <pre>map(object({<br/>    zone_name            = string<br/>    virtual_network_id   = string<br/>    registration_enabled = optional(bool, false)<br/>    resolution_policy    = optional(string, "Default")<br/>  }))</pre> | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure resource group name | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dns_a_records"></a> [dns\_a\_records](#output\_dns\_a\_records) | The properties of DNS A records created by this module |
| <a name="output_dns_aaaa_records"></a> [dns\_aaaa\_records](#output\_dns\_aaaa\_records) | The properties of DNS AAAA records created by this module |
| <a name="output_dns_cname_records"></a> [dns\_cname\_records](#output\_dns\_cname\_records) | The properties of DNS CNAME records created by this module |
| <a name="output_domain_zones"></a> [domain\_zones](#output\_domain\_zones) | The properties for domain zones created by this module |
| <a name="output_private_dns_a_records"></a> [private\_dns\_a\_records](#output\_private\_dns\_a\_records) | The properties of private DNS A records created by this module |
| <a name="output_private_dns_aaaa_records"></a> [private\_dns\_aaaa\_records](#output\_private\_dns\_aaaa\_records) | The properties of private DNS AAAA records created by this module |
| <a name="output_private_dns_cname_records"></a> [private\_dns\_cname\_records](#output\_private\_dns\_cname\_records) | The properties of private DNS CNAME records created by this module |
| <a name="output_private_dns_zone_virtual_network_links"></a> [private\_dns\_zone\_virtual\_network\_links](#output\_private\_dns\_zone\_virtual\_network\_links) | The properties of private DNS zone virtual network links created by this module |
| <a name="output_private_domain_zones"></a> [private\_domain\_zones](#output\_private\_domain\_zones) | The properties for private domain zones created by this module |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
