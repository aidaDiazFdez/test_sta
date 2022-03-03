//LOCALS
locals {
  regions = {
    brazilsouth = "zb1"
    eastus      = "zu1"
    eastus2     = "zu2"
    northeurope = "neu"
    westeurope  = "weu"
    uksouth     = "suk"
  }
  geo_region = lookup(local.regions, var.location)
}

//DATAS
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "key_vault" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.log_analytics_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

//RESOURCES
resource "azurerm_storage_account" "storage_account_service" {
  name                      = join("", [var.name, var.environment, local.geo_region, "sta"])
  resource_group_name       = data.azurerm_resource_group.resource_group.name
  location                  = var.location
  account_kind              = "StorageV2"
  account_tier              = var.account_tier
  access_tier               = var.access_tier
  account_replication_type  = var.account_replication_type
  enable_https_traffic_only = true
  is_hns_enabled            = var.is_hns_enabled
  min_tls_version           = var.min_tls_version

  identity {
    type = "SystemAssigned"
  }

  blob_properties {
    delete_retention_policy {
      days = var.delete_retention_days
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["Logging", "Metrics", "AzureServices"]
    ip_rules       = var.ip_rules
  }

  tags = merge({
    description = var.description
  }, var.custom_tags)

  depends_on = [data.azurerm_resource_group.resource_group]
}

resource "azurerm_key_vault_access_policy" "kvt_access_policy" {

  key_vault_id = data.azurerm_key_vault.key_vault.id

  tenant_id = azurerm_storage_account.storage_account_service.identity.0.tenant_id
  object_id = azurerm_storage_account.storage_account_service.identity.0.principal_id

  key_permissions = [
    "Encrypt",
    "Decrypt",
    "WrapKey",
    "UnwrapKey",
    "Sign",
    "Verify",
    "Get",
    "List",
    "Create",
    "Update",
    "Import",
    "Delete",
    "Backup",
    "Restore",
    "Recover",
    "Purge"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Backup",
    "Restore",
    "Recover",
    "Purge"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Delete",
    "Create",
    "Import",
    "Update",
    "ManageContacts",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers",
    "ManageIssuers",
    "Recover",
    "Purge",
    "Backup",
    "Restore"
  ]

  storage_permissions = [
    "Get",
    "List",
    "Delete",
    "Set",
    "Update",
    "RegenerateKey",
    "Recover",
    "Purge",
    "Backup",
    "Restore",
    "SetSAS",
    "ListSAS",
    "GetSAS",
    "DeleteSAS"
  ]

  depends_on = [azurerm_storage_account.storage_account_service, data.azurerm_key_vault.key_vault]
}

resource "azurerm_key_vault_key" "generated" {
  name         = var.key_name
  key_vault_id = data.azurerm_key_vault.key_vault.id
  key_type     = "RSA"
  key_size     = 2048

  tags = merge({
    description = var.description
  }, var.custom_tags)

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  depends_on = [data.azurerm_key_vault.key_vault, azurerm_key_vault_access_policy.kvt_access_policy]
}

resource "azurerm_storage_account_customer_managed_key" "cmk" {
  storage_account_id = azurerm_storage_account.storage_account_service.id
  key_vault_id       = data.azurerm_key_vault.key_vault.id
  key_name           = azurerm_key_vault_key.generated.name
  key_version        = azurerm_key_vault_key.generated.version

  depends_on = [data.azurerm_key_vault.key_vault, azurerm_key_vault_key.generated, azurerm_key_vault_access_policy.kvt_access_policy, azurerm_storage_account.storage_account_service]
}

resource "azurerm_monitor_diagnostic_setting" "sta" {

  name                       = var.name
  target_resource_id         = azurerm_storage_account.storage_account_service.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics.id

  metric {
    category = "Transaction"
    retention_policy {
      enabled = true
      days    = "30"
    }
  }

  metric {
    category = "Capacity"
    enabled  = false
    retention_policy {
      enabled = false
      days    = "0"
    }
  }
  depends_on = [azurerm_storage_account.storage_account_service, data.azurerm_log_analytics_workspace.log_analytics]
}

resource "azurerm_monitor_diagnostic_setting" "blob" {

  name                       = var.name
  target_resource_id         = "${azurerm_storage_account.storage_account_service.id}/blobServices/default"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics.id

  log {
    category = "StorageRead"
    retention_policy {
      enabled = true
      days    = "30"
    }
  }
  log {
    category = "StorageWrite"
    retention_policy {
      enabled = true
      days    = "30"
    }
  }
  log {
    category = "StorageDelete"
    retention_policy {
      enabled = true
      days    = "30"
    }
  }
  metric {
    category = "Transaction"
    retention_policy {
      enabled = true
      days    = "30"
    }
  }
  metric {
    category = "Capacity"
    enabled  = false
    retention_policy {
      enabled = false
      days    = "0"
    }
  }

  depends_on = [azurerm_storage_account.storage_account_service, data.azurerm_log_analytics_workspace.log_analytics]
}
