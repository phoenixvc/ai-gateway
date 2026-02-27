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

variable "owner" {
  type        = string
  description = "Owning team or role for resource tagging"
  default     = "platform-team"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to merge with the default tag set (project, owner)"
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "List of public IP ranges (CIDR notation) allowed to access the storage account, e.g. CI/CD runner IPs"
  default     = []
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "List of subnet resource IDs allowed to access the storage account via service endpoints"
  default     = []
}
