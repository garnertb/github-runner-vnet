# Create a VNET using an Azure Network Security Group to control the VNET network access
module "vnet" {
    source = "./modules/nsg"

    base_name = var.base_name
    github_enterprise_id = var.github_enterprise_id
    location = var.location
    vnet_address_space = var.vnet_address_space
    runner_subnet_address_prefixes = var.runner_subnet_address_prefixes
}
