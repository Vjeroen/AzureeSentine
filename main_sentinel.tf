

locals {
  storage_account_name = "purplecloud${random_string.suffix.id}"
  
}
variable "caldera_transport_protocol" {
  description = "Either http or https should be used"
  default     = "https"
}

variable "caldera_port" {
  description = "Default listening port http for Caldera"
  default     = "8888"
}

variable "caldera_port_https" {
  description = "Default listening port https for Caldera"
  default     = "8443"
}

variable "api_key_blue" {
  description = "Caldera api blue key"
  default     = "blueadmin2024"
}

variable "api_key_red" {
  description = "Caldera api red key"
  default     = "redadmin2024"
}

variable "blue_username" {
  description = "Caldera blue username"
  default     = "blue"
}

variable "blue_password" {
  description = "Caldera blue password"
  default     = "Caldera2024"
}

variable "red_username" {
  description = "Caldera red username"
  default     = "red"
}

variable "red_password" {
  description = "Caldera red password"
  default     = "Caldera2024"
}

variable "caldera_admin_username" {
  description = "Caldera admin username"
  default     = "admin"
}

variable "caldera_admin_password" {
  description = "Caldera admin password"
  default     = "Caldera2024"
}

variable "caldera_vm_name" {
  default = "calderaserver"
}

variable "admin_username" {
  default = "nxtadmin"
}

variable "admin_password" {
  default = "Redadminnxt!"  # 🔹 Change this or use a secure method
}

variable "caldera_vm_size" {
  default = "Standard_B2s"  # 🔹 Smallest recommended VM for testing
}

variable "caldera_os_disk_size" {
  default = 30  # 🔹 Disk size in GB
}

variable "location" {
  default = "eastus"
}

variable "resource_group_name" {
  default = "nxtdemo"
}

variable "storage_container_name" {
  default = "staging"
}

variable "azure_users_file" {
  default = "ad_users.csv"
}

variable "azure_aadconnect_file" {
  default = "AzureADConnect.msi"
}

# Random string for resources
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false 
}

# Specify the resource group
resource "azurerm_resource_group" "network" {
  name     = "${var.resource_group_name}-${random_string.suffix.id}"
  location = var.location
}

# Create a storage account
resource "azurerm_storage_account" "storage-account" {
  name                     = local.storage_account_name 
  resource_group_name      = "${var.resource_group_name}-${random_string.suffix.id}"
  location                 = var.location 
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  depends_on = [azurerm_resource_group.network]
}

# Create storage container
resource "azurerm_storage_container" "storage-container" {
  name                  = var.storage_container_name 
  storage_account_name  = azurerm_storage_account.storage-account.name
  container_access_type = "blob"

  depends_on = [azurerm_resource_group.network]
}

output "rg_name" {
  value   = "${var.resource_group_name}-${random_string.suffix.id}"
}

