# VNet with Network Security Groups

This folder contains a Terraform module to create an Azure Virtual Network that uses Network Security Groups (NSGs) to control network access. The NSG configuration is simpler than the Azure Firewall method and there is no added cost. However using NSGs requires you to use IP addresses in the access rules for external services, which makes managing the access rules more complex and potentially prone to failures due to IP/DNS changes.

See the [related example](../../examples/example-nsg/) for how to use this module.
