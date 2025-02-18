

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.116.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.12.0"  # ✅ Use the latest stable version
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.9.1"  # ✅ Use the latest stable version
    }
}
}
provider "azapi" {
  
}

provider "azurerm" {
  features {}
}
provider "azuredevops" {
  org_service_url = "https://dev.azure.com/demo-nxt-2303"
  personal_access_token = "Djb06TRhNgEpZWkGGPYbNCZEyxsXcdmcJ5bGKwREpfbMwWfBuQsXJQQJ99BBACAAAAAtbNtjAAASAZDO4KEO"  # Ensure you store this in a Terraform variable
}

