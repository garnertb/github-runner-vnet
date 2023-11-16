resource "azurerm_resource_group" "resource_group" {
  location = var.location
  name     = "${var.base_name}-rg"
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

  # provisioner "local-exec" {
  #   command = "../scripts/create-ns.sh ${azurerm_resource_group.resource_group.name} ${var.base_name}-ns ${var.location} ${azurerm_subnet.runner_subnet.id} ${var.gh_org_id}"
  # }

  # provisioner "local-exec" {
  #   when = destroy
  #   command = "../scripts/delete-ns.sh ${azurerm_resource_group.resource_group.name} ${var.base_name}-ns"
  # }
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
