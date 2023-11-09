# github-runner-vnet

This is a terraform module that provisions the required infrastructure (a virtual network and subnet) to enable with GitHub hosted runners with private networking.  See [GitHub documentation](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners) for the full manual process and pre-requisites.

## Usage

### Pre-requisites

* Use an Azure account with the Subscription Contributor role and the Network Contributor role. These roles enable you to register the GitHub.Network resource provider and delegate the subnet. For more information, see Azure built-in roles in the Azure documentation.
* To correctly associate the subnets with the right user, Azure NetworkSettings resources must be created in the same subscriptions where virtual networks are created.
* To ensure resource availability/data residency, resources must be created in the same Azure region.
* Terraform installed on the machine that executes this project.

### Using the module

```hcl
module "github_runner_vnet" {
  source = "garnertb/terraform-github-runner-vnet"
  resource_group_name = "vnet-test"
}
```


* [Instructions](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners)
