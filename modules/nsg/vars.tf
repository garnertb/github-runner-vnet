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

variable "github_business_id" {
  description = "GitHub Enterprise or Organization Database ID"
  type        = string
}
