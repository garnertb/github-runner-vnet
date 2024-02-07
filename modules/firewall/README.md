# VNet with Firewall

This folder contains a Terraform module to create an Azure Virtual Network that uses an Azure Firewall to control network access. The firewall configuration is a bit more complex than the Network Security Group method and there is an associated charge with the Azure Firewall product. However using Azure Firewall instead of NSGs allows you to use host names instead of IP addresses in the access rules, which makes managing the access rules easier and less prone to IP/DNS changes affecting your network access.

See the [related example](../../examples/example-firewall/) for how to use this module.
