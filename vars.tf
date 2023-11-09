variable "location" {
  description = "NSG for outbound rules"
  type        = string
  default     = "eastus"
}

variable "nsg_name" {
  description = "NSG Name"
  type        = string
  default     = "actions_nsg"
}

variable "github_database_id" {
  description = "GitHub Database ID for your enterprise"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the NSG"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

variable "vnet_name" {
  description = "Name of virtual network"
  type = string
  default = "ghvnet"
}

variable "subnet_name" {
  description = "Name of subnet"
  type = string
  default = "ghsubnet"
}
