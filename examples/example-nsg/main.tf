# Create a VNET using an Azure Network Security Group to control the VNET network access
module "vnet" {
    source = "github.com/pwideman/github-runner-vnet//modules/nsg"

    base_name = var.base_name
    github_org_id = var.github_org_id
}
