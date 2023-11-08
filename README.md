# Usage

1. Review [pre-requisites](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners#prerequisites).

To validate a GitHub organization's configuration, call the module in your Terraform configuration and specify the configuration options you expect.  Checks for variables not explicitly set will assume the settings from GitHub are desirable.

```hcl
module "github_runner_vnet" {
  source = "garnertb/terraform-github-runner-vnet"
  "resource_group_name = "vnet-test"
}
```


* [Instructions](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners)
