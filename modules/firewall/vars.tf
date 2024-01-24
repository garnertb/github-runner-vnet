variable "base_name" {
  description = "Base name for resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "runner_subnet_address_prefixes" {
  description = "Address prefixes for the runner subnet"
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

variable "firewall_subnet_address_prefixes" {
  description = "Address prefixes for the firewall subnet"
  type        = list(string)
  default     = ["10.0.1.0/26"]
}

variable "firewall_management_subnet_address_prefixes" {
  description = "Address prefixes for the management subnet"
  type        = list(string)
  default     = ["10.0.2.0/26"]
}

variable "github_enterprise_id" {
  description = "GitHub Enterprise Database ID"
  type        = string
}
