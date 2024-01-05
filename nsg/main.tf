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
  logging_count = var.include_log_analytics ? 1 : 0
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
  name     = "${var.base_name}-rg"
}

resource "azurerm_network_security_group" "actions_nsg" {
  name                = "${var.base_name}-actions-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "DenyInternetOutBoundOverwrite"
    priority                   = 400
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                         = "AllowVnetOutBoundOverwrite"
    source_port_range            = "*"
    destination_port_range       = "443"
    source_address_prefix        = "*"
    destination_address_prefix   = "VirtualNetwork"
    access                       = "Allow"
    priority                     = 200
    direction                    = "Outbound"
    destination_address_prefixes = []
    protocol                     = "Tcp"
  }

  security_rule {
    name                         = "AllowAzureCloudOutBound"
    source_port_range            = "*"
    destination_port_range       = "443"
    source_address_prefix        = "*"
    destination_address_prefix   = "AzureCloud"
    access                       = "Allow"
    priority                     = 210
    direction                    = "Outbound"
    destination_address_prefixes = []
    protocol                     = "Tcp"
  }

  security_rule {
    name                   = "AllowInternetOutBoundGitHub"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "443"
    source_address_prefix  = "*"
    access                 = "Allow"
    priority               = 220
    direction              = "Outbound"
    destination_address_prefixes = [
      "140.82.112.0/20",
      "142.250.0.0/15",
      "143.55.64.0/20",
      "192.30.252.0/22",
      "185.199.108.0/22"
    ]
  }

  security_rule {
    name                   = "AllowInternetOutBoundMicrosoft"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "443"
    source_address_prefix  = "*"
    access                 = "Allow"
    priority               = 230
    direction              = "Outbound"
    destination_address_prefixes = [
      "13.64.0.0/11",
      "13.96.0.0/13",
      "13.104.0.0/14",
      "20.33.0.0/16",
      "20.34.0.0/15",
      "20.36.0.0/14",
      "20.40.0.0/13",
      "20.48.0.0/12",
      "20.64.0.0/10",
      "20.128.0.0/16",
      "52.224.0.0/11",
      "204.79.197.200"
    ]
  }

  security_rule {
    name                         = "AllowInternetOutBoundCannonical"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "443"
    source_address_prefix        = "*"
    access                       = "Allow"
    priority                     = 240
    direction                    = "Outbound"
    destination_address_prefix   = "185.125.188.0/22"
    destination_address_prefixes = []
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.base_name}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "runner_subnet" {
  name                 = "${var.base_name}-runner-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = var.runner_subnet_address_prefixes

  delegation {
    name = "delegation"

    service_delegation {
      name    = "GitHub.Network/networkSettings"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
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
  template_content    = file("${path.module}/../gh_network_settings_template.json")
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.runner_subnet.id
  network_security_group_id = azurerm_network_security_group.actions_nsg.id
}

resource "azurerm_log_analytics_workspace" "law" {
  count = local.logging_count
  name                = "${var.base_name}-law"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_storage_account" "logging_sa" {
  count = local.logging_count
  name = var.logging_storage_account_name
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# This is only here to give an example of how to create the Network Watcher service, you probably want
# to manage the Network Watcher service separately from this module.
# resource "azurerm_network_watcher" "network_watcher" {
#   name                = var.network_watcher_name
#   location            = azurerm_resource_group.resource_group.location
#   resource_group_name = azurerm_resource_group.resource_group.name
# }

resource "azurerm_network_watcher_flow_log" "nsg_flow_log" {
  count = local.logging_count
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group
  name                 = "${var.base_name}-nsg-flow-log"

  network_security_group_id = azurerm_network_security_group.actions_nsg.id
  storage_account_id        = azurerm_storage_account.logging_sa[0].id
  enabled                   = true
  version = 2

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.law[0].workspace_id
    workspace_region      = azurerm_log_analytics_workspace.law[0].location
    workspace_resource_id = azurerm_log_analytics_workspace.law[0].id
    interval_in_minutes   = 10
  }
}
