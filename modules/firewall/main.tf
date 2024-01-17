terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">3.0.0"
    }
  }
}

locals {
  rg_name = "${var.base_name}-rg"
  ns_name = "${var.base_name}-ns"
}

# You need this if you haven't already registered the GitHub.Network resource provider in your Azure subscription.
# Terraform doesn't manage this type of create-once-and-never-delete resource very well, so I've just commented it out.
# Even with the lifecycle/prevent_destroy, it will still throw an error if you delete the resources manually with "terraform destroy".

# resource "azurerm_resource_provider_registration" "github_network_provider" {
#   name = "GitHub.Network"
#   lifecycle {
#     prevent_destroy = true
#   }
# }

resource "azurerm_resource_group" "resource_group" {
  location = var.location
  name     = local.rg_name
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = var.vnet_address_space
  location            = var.location
  name                = "${var.base_name}-vnet"
  resource_group_name = azurerm_resource_group.resource_group.name
  depends_on = [
    azurerm_resource_group.resource_group
  ]
}

resource "azurerm_subnet" "firewall_subnet" {
  address_prefixes     = var.firewall_subnet_address_prefixes
  # The subnet name has to be exactly this, in order for the subnet to be used for a firewall
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "management_subnet" {
  address_prefixes     = var.firewall_management_subnet_address_prefixes
  # The subnet name has to be exactly this in order for the subnet to be used for the firewall management
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "runner_subnet" {
  address_prefixes     = var.runner_subnet_address_prefixes
  name                 = "${var.base_name}-runner-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  delegation {
    name = "GitHub.Network.networkSettings"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "GitHub.Network/networkSettings"
    }
  }
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_public_ip" "firewall_public_ip" {
  allocation_method   = "Static"
  location            = var.location
  name                = "${var.base_name}-firewall-ip"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.resource_group,
  ]
}

resource "azurerm_public_ip" "firewall_management_public_ip" {
  allocation_method   = "Static"
  location            = var.location
  name                = "${var.base_name}-firewall-mgmt-ip"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.resource_group,
  ]
}

resource "azurerm_firewall_policy" "firewall_policy" {
  location            = var.location
  name                = "${var.base_name}-firewall-policy"
  resource_group_name = azurerm_resource_group.resource_group.name
  depends_on = [
    azurerm_resource_group.resource_group,
  ]
}

resource "azurerm_firewall_policy_rule_collection_group" "firewall_policy_rule_collection_group" {
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  name               = "DefaultRuleCollectionGroup"
  priority           = 200

  network_rule_collection {
    action   = "Allow"
    name     = "AllowAzureCloud"
    priority = 100
    rule {
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443"]
      name                  = "AzureCloud"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
    }
  }

  application_rule_collection {
    action = "Allow"
    name = "AllowApplicationRules"
    priority = 1000
    rule {
      name = "GitHub"
      source_addresses = ["*"]
      destination_fqdns = [
        "github.com",
        "*.github.com",
        "*.githubusercontent.com",
        "*.githubapp.com"
      ]
      protocols {
        port = "443"
        type = "Https"
      }
    }
    rule {
      name = "NPM"
      source_addresses = ["*"]
      destination_fqdns = ["registry.npmjs.org"]
      protocols {
        port = "443"
        type = "Https"
      }
    }
  }
  depends_on = [
    azurerm_firewall_policy.firewall_policy,
  ]
}

resource "azurerm_firewall" "firewall" {
  location            = var.location
  name                = "${var.base_name}-firewall"
  resource_group_name = azurerm_resource_group.resource_group.name
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "ipConfig"
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
    subnet_id            = azurerm_subnet.firewall_subnet.id
  }
  management_ip_configuration {
    name                 = "mgmtIpConfig"
    public_ip_address_id = azurerm_public_ip.firewall_management_public_ip.id
    subnet_id            = azurerm_subnet.management_subnet.id
  }
  depends_on = [
    azurerm_public_ip.firewall_public_ip,
    azurerm_public_ip.firewall_management_public_ip,
    azurerm_subnet.firewall_subnet,
    azurerm_firewall_policy.firewall_policy
  ]
}

resource "azurerm_route_table" "route_table" {
  location            = var.location
  name                = "${var.base_name}-rt"
  resource_group_name = azurerm_resource_group.resource_group.name
  depends_on = [
    azurerm_resource_group.resource_group
  ]
}

resource "azurerm_route" "firewall_route" {
  address_prefix         = "0.0.0.0/0"
  name                   = "${var.base_name}-firewall-route"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = azurerm_resource_group.resource_group.name
  route_table_name       = azurerm_route_table.route_table.name
  depends_on = [
    azurerm_firewall.firewall,
    azurerm_resource_group.resource_group,
    azurerm_route_table.route_table
  ]
}

resource "azurerm_subnet_route_table_association" "runner_subnet_route_table_association" {
  route_table_id = azurerm_route_table.route_table.id
  subnet_id      = azurerm_subnet.runner_subnet.id
  depends_on = [
    azurerm_route_table.route_table,
    azurerm_subnet.runner_subnet,
  ]
}

# There is no Terraform provider for GitHub.Network, so we have to use an ARM deployment template
# to create the GitHub.Network/networkSettings resource. See the note at the top of this documentation
# on deleting nested resources: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment

# WARNING: Attempting to delete the nested GitHub.Network/networkSettings resource will fail if the
# networkSettings is still in use in github.com. You need to delete resources in github.com before
# trying to delete the Azure resources.
resource "azurerm_resource_group_template_deployment" "github_network_settings" {
  name                = "${local.ns_name}-deployment"
  resource_group_name = local.rg_name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "name" = {
      value = local.ns_name
    },
    "subnetId" = {
      value = azurerm_subnet.runner_subnet.id
    },
    "organizationId" = {
      value = var.github_org_id
    },
  })
  template_content    = file("${path.module}/../shared/gh_network_settings_template.json")
}
