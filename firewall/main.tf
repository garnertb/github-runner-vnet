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
  name                 = "AzureFirewallSubnet" # for some reason the subnet name has to be exactly this, in order for the subnet to be used for a firewall
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

resource "azurerm_firewall" "firewall" {
  location            = var.location
  name                = "${var.base_name}-firewall"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "ipConfig"
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
    subnet_id            = azurerm_subnet.firewall_subnet.id
  }
  depends_on = [
    azurerm_public_ip.firewall_public_ip,
    azurerm_subnet.firewall_subnet,
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
    command = "../scripts/create-ns.sh ${self.triggers.rg_name} ${self.triggers.ns_name} ${var.location} ${self.triggers.subnet_id} ${var.gh_org_id} >> ${path.module}/ns.json"
  }

  provisioner "local-exec" {
    when = destroy
    command = "../scripts/delete-ns.sh ${self.triggers.rg_name} ${self.triggers.ns_name}"
  }
}

data local_file ns {
  filename = "${path.module}/ns.json"
  depends_on = [
    null_resource.github_network_settings
  ]
}
