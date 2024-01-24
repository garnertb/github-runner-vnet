# Create a VNET using an Azure Firewall to control the VNET network access
module "vnet" {
    source = "github.com/garnertb/github-runner-vnet//modules/firewall"

    base_name = var.base_name
    github_org_id = var.github_org_id
}
