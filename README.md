> [!WARNING]  
> This repo is a experimental and not ready for general consumption.

# github-runner-vnet 

A terraform module that configures and maintains the infrastructure needed to run GitHub-Hosted Action Runners in a [private network](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners).   

## Quick Start

If you are familiar with the Terraform ecosystem, use these minimal steps to use this module.

1. Before running, review [pre-requisites](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners#prerequisites) from the documentation to ensure your environmnet is properly configured.

Provision and configure the infrastructure in Terraform by calling this module.

```hcl
module "github_runner_vnet" {
  source = "github.com/garnertb/github-runner-vnet"
  resource_group_name = "vnet-test"
}
```
