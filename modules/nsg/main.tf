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
    name                         = "AllowStorageOutBound"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "*"
    destination_address_prefix   = "Storage"
    access                       = "Allow"
    priority                     = 230
    direction                    = "Outbound"
    destination_address_prefixes = []
    protocol                     = "*"
  }

  security_rule {
    name                   = "AllowOutBoundGitHub"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "443"
    source_address_prefix  = "*"
    access                 = "Allow"
    priority               = 220
    direction              = "Outbound"
    destination_address_prefixes = [
            "140.82.112.0/20",
            "143.55.64.0/20",
            "185.199.108.0/22",
            "192.30.252.0/22",
            "20.175.192.146/32",
            "20.175.192.147/32",
            "20.175.192.149/32",
            "20.175.192.150/32",
            "20.199.39.227/32",
            "20.199.39.228/32",
            "20.199.39.231/32",
            "20.199.39.232/32",
            "20.200.245.241/32",
            "20.200.245.245/32",
            "20.200.245.246/32",
            "20.200.245.247/32",
            "20.200.245.248/32",
            "20.201.28.144/32",
            "20.201.28.148/32",
            "20.201.28.149/32",
            "20.201.28.151/32",
            "20.201.28.152/32",
            "20.205.243.160/32",
            "20.205.243.164/32",
            "20.205.243.165/32",
            "20.205.243.166/32",
            "20.205.243.168/32",
            "20.207.73.82/32",
            "20.207.73.83/32",
            "20.207.73.85/32",
            "20.207.73.86/32",
            "20.207.73.88/32",
            "20.233.83.145/32",
            "20.233.83.146/32",
            "20.233.83.147/32",
            "20.233.83.149/32",
            "20.233.83.150/32",
            "20.248.137.48/32",
            "20.248.137.49/32",
            "20.248.137.50/32",
            "20.248.137.52/32",
            "20.248.137.55/32",
            "20.27.177.113/32",
            "20.27.177.114/32",
            "20.27.177.116/32",
            "20.27.177.117/32",
            "20.27.177.118/32",
            "20.29.134.17/32",
            "20.29.134.18/32",
            "20.29.134.19/32",
            "20.29.134.23/32",
            "20.29.134.24/32",
            "20.87.245.0/32",
            "20.87.245.1/32",
            "20.87.245.4/32",
            "20.87.245.6/32",
            "20.87.245.7/32",
            "4.208.26.196/32",
            "4.208.26.197/32",
            "4.208.26.198/32",
            "4.208.26.199/32",
            "4.208.26.200/32"
    ]
  }

  security_rule {
    name                   = "AllowOutBoundActions"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "443"
    source_address_prefix  = "*"
    access                 = "Allow"
    priority               = 210
    direction              = "Outbound"
    destination_address_prefixes = [
            "4.175.114.51/32",
            "20.102.35.120/32",
            "4.175.114.43/32",
            "20.72.125.48/32",
            "20.19.5.100/32",
            "20.7.92.46/32",
            "20.232.252.48/32",
            "52.186.44.51/32",
            "20.22.98.201/32",
            "20.246.184.240/32",
            "20.96.133.71/32",
            "20.253.2.203/32",
            "20.102.39.220/32",
            "20.81.127.181/32",
            "52.148.30.208/32",
            "20.14.42.190/32",
            "20.85.159.192/32",
            "52.224.205.173/32",
            "20.118.176.156/32",
            "20.236.207.188/32",
            "20.242.161.191/32",
            "20.166.216.139/32",
            "20.253.126.26/32",
            "52.152.245.137/32",
            "40.118.236.116/32",
            "20.185.75.138/32",
            "20.96.226.211/32",
            "52.167.78.33/32",
            "20.105.13.142/32",
            "20.253.95.3/32",
            "20.221.96.90/32",
            "51.138.235.85/32",
            "52.186.47.208/32",
            "20.7.220.66/32",
            "20.75.4.210/32",
            "20.120.75.171/32",
            "20.98.183.48/32",
            "20.84.200.15/32",
            "20.14.235.135/32",
            "20.10.226.54/32",
            "20.22.166.15/32",
            "20.65.21.88/32",
            "20.102.36.236/32",
            "20.124.56.57/32",
            "20.94.100.174/32",
            "20.102.166.33/32",
            "20.31.193.160/32",
            "20.232.77.7/32",
            "20.102.38.122/32",
            "20.102.39.57/32",
            "20.85.108.33/32",
            "40.88.240.168/32",
            "20.69.187.19/32",
            "20.246.192.124/32",
            "20.4.161.108/32",
            "20.22.22.84/32",
            "20.1.250.47/32",
            "20.237.33.78/32",
            "20.242.179.206/32",
            "40.88.239.133/32",
            "20.121.247.125/32",
            "20.106.107.180/32",
            "20.22.118.40/32",
            "20.15.240.48/32",
            "20.84.218.150/32"
    ]
  }

  # Example rule for allowing access to NPM (registry.npmjs.org)
  # Note: At the time of writing, this IP range will enable access to registry.npmjs.org
  # but broader than it needs to be. If you want to restrict access to only registry.npmjs.org, you
  # should use a tighter range. This is just an example.
  # security_rule {
  #   name                   = "AllowOutBoundNPM"
  #   protocol               = "Tcp"
  #   source_port_range      = "*"
  #   destination_port_range = "443"
  #   source_address_prefix  = "*"
  #   access                 = "Allow"
  #   priority               = 240
  #   direction              = "Outbound"
  #   destination_address_prefixes = [
  #     "104.16.0.0/16"
  #   ]
  # }

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
resource "azapi_resource" "github_network_settings" {
  type                      = "GitHub.Network/networkSettings@2024-04-02"
  name                      = "${local.ns_name}-deployment"
  location                  = var.location
  parent_id                 = azurerm_resource_group.resource_group.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      businessId = var.github_business_id
      subnetId   = azurerm_subnet.runner_subnet.id
    }
  })
  response_export_values = ["tags.GitHubId"]

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.runner_subnet.id
  network_security_group_id = azurerm_network_security_group.actions_nsg.id
}
