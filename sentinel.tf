

variable "sentinel_location" {
  default = "eastus"
}


resource "azurerm_log_analytics_workspace" "pc" {
  name                = "pc-${random_string.suffix.id}"
  location            = var.sentinel_location
  resource_group_name = "${azurerm_resource_group.network.name}"
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

resource "azurerm_log_analytics_solution" "pc" {
  solution_name         = "SecurityInsights"
  location              = var.sentinel_location
  resource_group_name = "${azurerm_resource_group.network.name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.pc.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.pc.name}"
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}

resource "azapi_resource" "sentinel_onboarding" {
  type      = "Microsoft.SecurityInsights/onboardingStates@2021-10-01"
  schema_validation_enabled = false
  name      = "default"
  parent_id = azurerm_log_analytics_workspace.pc.id
  body = jsonencode({
    properties = {
      provisioningState = "Succeeded"
    }
  })
}


# Note:  Adding this diagnostic setting requires special privileges
# 1. Ensure that owner permissions are added for the SP
# 2. Ensure that SP has Global Administrator permissions
# 3. Run this while logged in as global admin, changing the SP_OBJECT_ID to be the SP object id.  The --role ID is for owner
# az role assignment create --assignee-principal-type  ServicePrincipal --assignee-object-id <SP_OBJECT_ID> --scope "/providers/Microsoft.aadiam" --role b24988ac-6180-42a0-ab88-20f7382dd24c
resource "azurerm_monitor_aad_diagnostic_setting" "threat_monitoring_demo" {
  name                       = "threat-monitoring"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.pc.id

  enabled_log {
    category = "SignInLogs"

    retention_policy {
      enabled = true
    }
  }
  
  enabled_log {
    category = "AuditLogs"

    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "MicrosoftGraphActivityLogs"

    retention_policy {
      enabled = true
    }
  }
  
  enabled_log {
    category = "EnrichedOffice365AuditLogs"

    retention_policy {
      enabled = true
    }
  }
  
  enabled_log {
    category = "NonInteractiveUserSignInLogs"

    retention_policy {
      enabled = true
    }
  }
  
  enabled_log {
    category = "ServicePrincipalSignInLogs"

    retention_policy {
      enabled = true
    }
  }
  
  enabled_log {
    category = "ManagedIdentitySignInLogs"

    retention_policy {
      enabled = true
    }
  }
  lifecycle {
    ignore_changes = [name]  # ✅ Prevent Terraform from failing if it already exists
  }
}

resource "azuread_application" "microsoft_security_api" {
  display_name = "Microsoft Security API Access"
}







resource "azurerm_sentinel_data_connector_azure_active_directory" "pc-demo" {
  name                       = "pc-ad-connector"
  log_analytics_workspace_id = "${azurerm_log_analytics_workspace.pc.id}"  # ✅ FIXED
  depends_on                 = [azapi_resource.sentinel_onboarding]
  
}


resource "azurerm_sentinel_data_connector_office_365" "m365connector-demo" {
  name                       = "M365-Sentinel-connector"
  log_analytics_workspace_id = "${azurerm_log_analytics_workspace.pc.id}"  # ✅ FIXED
  exchange_enabled           = true
  sharepoint_enabled         = true
  teams_enabled              = true
  depends_on                 = [azapi_resource.sentinel_onboarding]
}

## Generate an Azure Devops Organization to link Github with Sentinel and perform detection as code 

resource "azuredevops_project" "sentinel_project" {
  name               = "Sentinel-DevOps"
  description        = "Azure DevOps project for Sentinel automation (Terraform Deploy)"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}
/* Service Connection needs to be manually made via Oauth
resource "azuredevops_build_definition" "sentinel_pipeline" {
  project_id = azuredevops_project.sentinel_project.id
  name       = "Sentinel-Deployment-Pipeline"
  path       = "\\Sentinel"

  repository {
    repo_type   = "GitHub"
    repo_id     = "Vjeroen/DectionRules_Sentinel"
    branch_name = "main"
    yml_path    = ".azure-pipelines/sentinel-deploy.yml"
    service_connection_id = "1ce411ff-"  # 🔹 Replace with the actual Service Connection ID
  }
}*/


output "sentinel_details" {
  value = <<EOS

Azure Sentinel Details
-----------------------
Resource Group: ${azurerm_resource_group.network.name}
Location: ${azurerm_resource_group.network.location}
Log Analytics Workspace: ${azurerm_log_analytics_workspace.pc.name}
Log Analytics Solution: ${azurerm_log_analytics_solution.pc.solution_name}
Azure Devops Project was linked to Github called Sentinel-DevOps
Github has  configured the standard workflow in sentinel-deploy.yml
-----------------------
EOS
}


