
locals {
  sysmon_config_s            = "sysmonconfig-export.xml"
  sysmon_zip_s               = "Sysmon.zip"
}

# Create a storage account for sysmon files
resource "azurerm_storage_account" "sysmon_sentinel" {
  name                     = "ss${random_string.suffix.id}"
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  depends_on = [azurerm_resource_group.network]
}

# Create storage container for sysmon files
resource "azurerm_storage_container" "sysmon_sentinel" {
  name                  = "provisioning"
  storage_account_name  = azurerm_storage_account.sysmon_sentinel.name
  container_access_type = "blob"

  depends_on = [azurerm_resource_group.network]
}

# Upload SwiftOnSecurity Sysmon configuration xml file
resource "azurerm_storage_blob" "sysmon_config_sentinel" {
  name                   = local.sysmon_config_s
  storage_account_name   = azurerm_storage_account.sysmon_sentinel.name
  storage_container_name = azurerm_storage_container.sysmon_sentinel.name
  type                   = "Block"
  source                 = "${path.module}/files/sysmon/${local.sysmon_config_s}"
}

# Upload Sysmon zip
resource "azurerm_storage_blob" "sysmon_zip_sentinel" {
  name                   = local.sysmon_zip_s
  storage_account_name   = azurerm_storage_account.sysmon_sentinel.name
  storage_container_name = azurerm_storage_container.sysmon_sentinel.name
  type                   = "Block"
  source                 = "${path.module}/files/sysmon/${local.sysmon_zip_s}"
}
