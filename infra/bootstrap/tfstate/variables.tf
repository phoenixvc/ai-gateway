variable "location" {
  type        = string
  description = "Azure location"
  default     = "southafricanorth"
}

variable "location_short" {
  type        = string
  description = "Short location code"
  default     = "san"
}

variable "resource_group_name" {
  type        = string
  description = "RG name for shared tfstate"
  default     = "pvc-shared-tfstate-rg-san"
}

variable "storage_account_name" {
  type        = string
  description = "Globally-unique storage account name (lowercase, 3-24 chars)"
  default     = "pvcsharedtfstatesan"
}

variable "container_name" {
  type        = string
  description = "Blob container for tfstate"
  default     = "tfstate"
}

variable "tags" {
  type        = map(string)
  default     = {
    project = "tfstate"
    owner   = "J"
  }
}
