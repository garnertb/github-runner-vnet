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

# There is no Terraform provider for GitHub.Network, so we have to use a null_resource and
# local-exec to call a script that uses the Azure CLI to create the network settings. We
# can't add these provisioners to the runner subnet resource because a destroy provisioner
# doesn't have access to any other resources including vars and locals. We need to use these
# triggers to get those values. 

# WARNING: Deleting this resource will fail if the networkSettings is still in use in github.com. You need
# to delete resources in github.com before trying to delete the Azure resources.
resource null_resource github_network_settings {
  triggers = {
    ns_name = local.ns_name
    rg_name = local.rg_name
    subnet_id = azurerm_subnet.runner_subnet.id
  }

  provisioner "local-exec" {
    when = create
    command = "../scripts/create-ns.sh ${self.triggers.rg_name} ${self.triggers.ns_name} ${var.location} ${self.triggers.subnet_id} ${var.gh_org_id}"
  }

  provisioner "local-exec" {
    when = destroy
    command = "../scripts/delete-ns.sh ${self.triggers.rg_name} ${self.triggers.ns_name}"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.runner_subnet.id
  network_security_group_id = azurerm_network_security_group.actions_nsg.id
}

# This data source is used to get the networkSettings resource created above, so that we can return its ID as an output.
data "azurerm_resources" "github_network_settings" {
  name = local.ns_name
  depends_on = [
    null_resource.github_network_settings
  ]
}
