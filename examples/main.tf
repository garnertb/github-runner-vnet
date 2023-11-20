module "github_runner_vnet" {
  source = "../nsg/"

  # Fill in your Azure region
  location = "eastus"

  # Fill in the base_name to be used for resources
  base_name = "runner-vnet"
  
  # Fill in your GitHub Organization ID
  github_org_id = "YOUR_GITHUB_ORG_ID"
}

provider "azurerm" {
  features {
  }
}

output "resource_id" {
    value = module.github_runner_vnet.resource_id
}
