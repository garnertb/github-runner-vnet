variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "base_name" {
  description = "Base name for resources"
  type        = string
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

variable "github_org_id" {
  description = "GitHub Organization ID"
  type        = string
}

variable "include_log_analytics" {
  description = "Create resources related to log analytics"
  type = bool
  default = false
}

variable "logging_storage_account_name" {
  description = "Name for the storage account used for logging/log analytics"
  type = string
}

variable "network_watcher_name" {
  # Network Watcher is a regional service that must be created in the subscription & region where the VNet is located
  # Since there is only one per subscription/region combination, it probably has a lifespan different from this module
  # and should be created outside of this module.
  description = "Name of the network watcher service, to use for log analytics"
  type = string
  default = "NetworkWatcher_eastus"
}

variable "network_watcher_resource_group" {
  # Since we aren't creating the Network Watcher service in this module, we need to know the resource group where it is located
  description = "Name of the resource group where the network watcher service is located"
  type = string
  default = "NetworkWatcherRG"
}
