//DATAS
variable "resource_group_name" {
  description = "(Required) Name of the resource group in which to create the Storage Account"
  type        = string
}

variable "key_vault_name" {
  description = "(Required) Name of the Key Vault to encrypt the resource. It has to be in the same resource group"
  type        = string
}

variable "log_analytics_name" {
  description = "(Required) Name of the Log Analytics name where the logs generated are going to be stored"
  type        = string
}

//RESOURCES
variable "account_tier" {
  description = "(Required) Storage account access kind [ Standard | Premium ]"
  type        = string
}

variable "access_tier" {
  description = "(Optional) Storage account access tier for BlobStorage accounts [ Hot | Cool ]"
  type        = string
  default     = "Hot"
}

variable "account_replication_type" {
  description = "(Required) Storage account replication type [ LRS ZRS GRS RAGRS ]"
  type        = string
}

variable "is_hns_enabled" {
  description = "(Optional) Allow Data Lake GEN 2, you need to set the variable account_kind to StorageV2. Changes this force a new resource"
  type        = string
  default     = false
}

variable "min_tls_version" {
  description = "(Optional) Storage account minimun tls version [ TLS1_0 | TLS1_1 | TLS1_2 ]"
  type        = string
  default     = "TLS1_2"
}

variable "delete_retention_days" {
  description = "(Optional) Specifies the number of days that the blob should be retained, between 1 and 365 days. Defaults to 7"
  type        = number
  default     = 7
}

variable "ip_rules" {
  description = "(Optional) List of additional IP ranges which can access the storage account from on-premise"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "(Optional) The name of a key from a KVT to connect with the Storage Account Product"
  type        = string
  default     = ""
}

// TAGGING VARIABLES

variable "description" {
  description = "(Required) This tag will allow the resource operator to provide additional context information"
  type        = string
}

variable "custom_tags" {
  description = "Optional custom tags"
  type        = map(any)
  default     = {}
}

//NAMING VARIABLES

variable "name" {
  description = "(Required) The name of Storage Acccount. Changing this forces a new resource to be created."
  type        = string
}

variable "environment" {
  description = "(Required) The name of environment. Used for Naming. (3 characters) "
  type        = string
}

variable "location" {
  description = "(Required) Specifies the supported Azure location where the Resource Group exists. Changing this forces a new resource to be created."
  type        = string
}
