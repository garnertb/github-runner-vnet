> [!WARNING]  
> This repo is a experimental and not ready for general consumption.

# github-runner-vnet 

Terraform modules that configures and maintains the infrastructure needed to run GitHub-Hosted Action Runners in a [private network](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners).   

## Quick Start

If you are familiar with the Terraform ecosystem, use these minimal steps to use this module.

1. Before running, review [pre-requisites](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners#prerequisites) from the documentation to ensure your environmnet is properly configured.
2. The [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) must be installed and on the system path, logged in with the identity that you want these resources created under, and Azure Subscription configured.
3. The `GitHub.Network` resource provider must be registered in the Azure Subscription. The Terraform modules contain HCL to register this provider, but it is commented out since you may not want this managed by Terraform. See the above GitHub documentation for a sample AZ CLI command to register the provider.

This repo contains two Terraform modules in the `/nsg` and `/firewall` subdirectories. The module in `/nsg` uses a [Network Security Group (NSG)](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview) to manage the network security of the VNet, while `/firewall` uses [Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/overview) instead.

Provision and configure the infrastructure in Terraform by calling this module.

```hcl
module "github_runner_vnet" {
  # or "github.com/garnertb/github-runner-vnet/firewall" for the firewall version
  source = "github.com/garnertb/github-runner-vnet/nsg"

  # The resources use this base_name as a name prefix, e.g. ${base_name}-rg for the resource group
  base_name = "vnet-test"
  
  # retrieved through the GitHub API as explained at the documentation link above
  gh_org_id = "12345"
}
```

The output of these modules is the ID of the new `GitHub.Network/networkSettings` resource. Plug this ID into the github.com UI for configuring the Azure Virtual Network.