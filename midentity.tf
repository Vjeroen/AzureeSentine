

# Create the User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "uai" {
  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  name                = var.identity_name
}

variable "identity_name" {
  default = "uaidentity"
}

variable "identity_type" {
  default = "SystemAssigned, UserAssigned"
}

# add 'Owner' role scoped to subscription for user-assigned managed identity
resource "azurerm_role_assignment" "owner_uai" {
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.uai.principal_id
}

# add 'Virtual Machine Contributor' role scoped to subscription for user-assigned managed identity
resource "azurerm_role_assignment" "vm_contributor_uai" {
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.uai.principal_id
}

# add 'Key Vault Reader' role scoped to subscription for user-assigned managed identity
resource "azurerm_role_assignment" "key_vault_reader_uai" {
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "Key Vault Reader"
  principal_id         = azurerm_user_assigned_identity.uai.principal_id
}

data "azurerm_subscription" "mi" {
}

output "managed_identity_details" {
  value = <<EOS
-------------------------
Managed Identity Details
-------------------------
Subscription ID:   ${split("/", data.azurerm_subscription.mi.id)[2]}
Subscription Name: ${data.azurerm_subscription.mi.display_name}
Resource Group:    ${azurerm_resource_group.network.name}

User-Assigned Identity:
-------------------------
Name:        ${azurerm_user_assigned_identity.uai.name}
Client ID:   ${azurerm_user_assigned_identity.uai.client_id}
Object ID:   ${azurerm_user_assigned_identity.uai.principal_id}
Roles:       ${azurerm_role_assignment.owner_uai.role_definition_name}, ${azurerm_role_assignment.vm_contributor_uai.
role_definition_name}, ${azurerm_role_assignment.key_vault_reader_uai.role_definition_name}

EOS
}

