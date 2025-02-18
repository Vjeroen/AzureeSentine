
variable "endpoint-ip-win10-2" {
  default = "10.100.20.11"
}

variable "admin-username-win10-2" {
  default = "RTCAdmin"
}

variable "admin-password-win10-2" {
  default = "3VdRjqq08K"
}

variable "join-domain-win10-2" {
  default = false
}

variable "endpoint_hostname-win10-2" {
  default = "win10-2"
}

variable "tags_endpoint_hostname-win10-2" {
  type = map(any)

  default = {
    terraform = "true"
  }
}

resource "azurerm_public_ip" "win10-external-ip-win10-2" {
  name                = "${var.endpoint_hostname-win10-2}-public-ip-${random_string.suffix.id}"
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_network_interface" "win10-primary-nic-win10-2" {
  name                = "${var.endpoint_hostname-win10-2}-int-nic-${random_string.suffix.id}"
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  internal_dns_name_label = "${var.endpoint_hostname-win10-2}-${random_string.suffix.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.user_subnet-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.endpoint-ip-win10-2
    public_ip_address_id = azurerm_public_ip.win10-external-ip-win10-2.id

  }
  depends_on = [azurerm_resource_group.network]
}

locals {
  win10vmname-win10-2 = var.endpoint_hostname-win10-2 
  win10vmfqdn-win10-2 = "${local.win10vmname-win10-2}.rtc.local"
  win10custom-data-params-win10-2   = "Param($RemoteHostName = \"${local.win10vmfqdn-win10-2}\", $ComputerName = \"${local.win10vmname-win10-2}\")"
  win10custom-data-content-win10-2  = (join(" ", [local.win10custom-data-params-win10-2, 
  templatefile("${path.module}/files/win10/bootstrap-win10-sentinel.ps1.tpl", {
    join_domain               = var.join-domain-win10-2 ? 1 : 0
    install_sysmon            = true ? 1 : 0
    install_art               = true ? 1 : 0
    auto_logon_domain_user    = false ? 1 : 0
    dc_ip                     = "DC_IP" 
    endpoint_ad_user          = "ENDPOINT_AD_USER" 
    endpoint_ad_password      = "ENDPOINT_AD_PASSWORD" 
    winrm_username            = "WINRM_USERNAME" 
    winrm_password            = "WINRM_PASSWORD" 
    admin_username            = var.admin-username-win10-2
    admin_password            = var.admin-password-win10-2
    ad_domain                 = "AD_DOMAIN" 
    storage_acct_s            = azurerm_storage_account.sysmon_sentinel.name
    storage_container_s       = azurerm_storage_container.sysmon_sentinel.name
    sysmon_config_s           = local.sysmon_config_s
    sysmon_zip_s              = local.sysmon_zip_s
    storage_acct_d            = azurerm_storage_account.defender_scripts.name
    storage_container_d       = azurerm_storage_container.scripts.name
    MDE_onboarding_script     = "WindowsDefenderATPOnboardingScript.cmd"
  })
   ]))
}

/*data "template_file" "ps-template-win10-2" {
  template = file("${path.module}/files/win10/bootstrap-win10-sentinel.ps1.tpl")

  vars  = {
    join_domain               = var.join-domain-win10-2 ? 1 : 0
    install_sysmon            = true ? 1 : 0
    install_art               = true ? 1 : 0
    auto_logon_domain_user    = false ? 1 : 0
    dc_ip                     = "DC_IP" 
    endpoint_ad_user          = "ENDPOINT_AD_USER" 
    endpoint_ad_password      = "ENDPOINT_AD_PASSWORD" 
    winrm_username            = "WINRM_USERNAME" 
    winrm_password            = "WINRM_PASSWORD" 
    admin_username            = var.admin-username-win10-2
    admin_password            = var.admin-password-win10-2
    ad_domain                 = "AD_DOMAIN" 
    storage_acct_s            = azurerm_storage_account.sysmon_sentinel.name
    storage_container_s       = azurerm_storage_container.sysmon_sentinel.name
    sysmon_config_s           = local.sysmon_config_s
    sysmon_zip_s              = local.sysmon_zip_s
  }
}*/

resource "local_file" "debug-bootstrap-script-win10-2" {
  # For inspecting the rendered powershell script as it is loaded onto endpoint through custom_data extension
  content = local.win10custom-data-content-win10-2
  filename = "${path.module}/output/win10/bootstrap-${var.endpoint_hostname-win10-2}-sentinel.ps1"
}

resource "azurerm_virtual_machine" "azurerm-vm-win10-2" {
  name                          = "${local.win10vmname-win10-2}-${random_string.suffix.id}"
  resource_group_name           = "${var.resource_group_name}-${random_string.suffix.id}"
  location                      = var.location
  vm_size                       = "Standard_D2as_v4"
  delete_os_disk_on_termination = true
  
  identity {
    type         = var.identity_type
    identity_ids = [azurerm_user_assigned_identity.uai.id]
  }
  
  network_interface_ids         = [
    azurerm_network_interface.win10-primary-nic-win10-2.id,
  ]
  
  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-22h2-pro-g2" 
    version   = "latest"
  }

  storage_os_disk {
    name              = local.win10vmname-win10-2
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }
  
  os_profile_windows_config {
    provision_vm_agent = true
    winrm {
      protocol = "HTTP"
    }
    additional_unattend_config {
      pass = "oobeSystem"
      component = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin-password-win10-2}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin-username-win10-2}</Username></AutoLogon>"
    }
    
    additional_unattend_config {
      pass = "oobeSystem"
      component = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = file("${path.module}/files/win10/FirstLogonCommands.xml")
    }
  }
  
  os_profile {
    custom_data    = local.win10custom-data-content-win10-2
    computer_name  = local.win10vmname-win10-2
    admin_username = var.admin-username-win10-2
    admin_password = var.admin-password-win10-2
  }

  depends_on = [
    azurerm_network_interface.win10-primary-nic-win10-2,

    azurerm_storage_blob.sysmon_zip_sentinel,

  ]
}

resource "azurerm_virtual_machine_extension" "azurerm-vm-win10-2" {
  count                = 1
  name                 = "AMAExtension-azurerm-vm-win10-2"
  virtual_machine_id   = azurerm_virtual_machine.azurerm-vm-win10-2.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.25"
  auto_upgrade_minor_version = "true"
  depends_on = [
    azurerm_virtual_machine.azurerm-vm-win10-2,
    azurerm_log_analytics_workspace.pc
  ]

  tags = merge(var.tags_endpoint_hostname-win10-2, tomap({ "firstapply" = timestamp() }))
  
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_monitor_data_collection_rule" "rule1_azurerm-vm-win10-2" {
 name                = "dcrule1-azurerm-vm-win10-2"
 location            = var.location
 resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
 depends_on          = [azurerm_virtual_machine_extension.azurerm-vm-win10-2]

 destinations {
   log_analytics {
     workspace_resource_id = azurerm_log_analytics_workspace.pc.id
     name                  = "log-analytics"
   }
 }

 data_flow {
   streams      = ["Microsoft-Event"]
   destinations = ["log-analytics"]
 }
 
  data_sources {
   windows_event_log {
     streams = ["Microsoft-Event"]
     x_path_queries = [
       "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
       "Security!*",
       "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
       "Microsoft-Windows-Sysmon/Operational!*"
     ]
     name = "eventLogsDataSource"
   }
 }
}
 
# data collection rule association
resource "azurerm_monitor_data_collection_rule_association" "dcra-azurerm-vm-win10-2" {
 count                   = 1
 name                    = "dcra-azurerm-vm-win10-2"
 target_resource_id      = azurerm_virtual_machine.azurerm-vm-win10-2.id
 data_collection_rule_id = azurerm_monitor_data_collection_rule.rule1_azurerm-vm-win10-2.id
}
 
resource "local_file" "hosts-cfg-win10-2" {
  content = templatefile("${path.module}/files/win10/hosts.tpl",
    {
      ip    = azurerm_public_ip.win10-external-ip-win10-2.ip_address
      auser = var.admin-username-win10-2
      apwd  = var.admin-password-win10-2
    }
  )
  filename = "${path.module}/hosts-${var.endpoint_hostname-win10-2}.cfg"
}

# add 'Contributor' role scoped to subscription for system-assigned managed identity
resource "azurerm_role_assignment" "contributor_si_azurerm-vm-win10-2" {
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "Contributor"
  principal_id   = azurerm_virtual_machine.azurerm-vm-win10-2.identity[0].principal_id
}

# add 'Virtual Machine Contributor' role scoped to subscription for system-assigned managed identity
resource "azurerm_role_assignment" "vm_contributor_si_azurerm-vm-win10-2" {
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id   = azurerm_virtual_machine.azurerm-vm-win10-2.identity[0].principal_id
}

# add 'Key Vault Reader' role scoped to subscription for system-assigned managed identity
resource "azurerm_role_assignment" "key_vault_reader_si_azurerm-vm-win10-2" {
  scope                = data.azurerm_subscription.mi.id
  role_definition_name = "Key Vault Reader"
  principal_id   = azurerm_virtual_machine.azurerm-vm-win10-2.identity[0].principal_id
}

output "windows_endpoint_details_azurerm-vm-win10-2" {
  value = <<EOS
-------------------------
Virtual Machine ${var.endpoint_hostname-win10-2} 
-------------------------
Computer Name:  ${var.endpoint_hostname-win10-2}
Private IP: ${var.endpoint-ip-win10-2}
Public IP:  ${azurerm_public_ip.win10-external-ip-win10-2.ip_address}
local Admin:  ${var.admin-username-win10-2}
local password: ${var.admin-password-win10-2} 
-------------
SSH to ${var.endpoint_hostname-win10-2}
-------------
ssh ${var.admin-username-win10-2}@${azurerm_public_ip.win10-external-ip-win10-2.ip_address}

System-Assigned Identity for ${var.endpoint_hostname-win10-2}:
-------------------------
Object ID:   ${azurerm_virtual_machine.azurerm-vm-win10-2.identity[0].principal_id}
Roles:       ${azurerm_role_assignment.contributor_si_azurerm-vm-win10-2.role_definition_name}, ${azurerm_role_assignment.vm_contributor_si_azurerm-vm-win10-2.role_definition_name}, ${azurerm_role_assignment.key_vault_reader_si_azurerm-vm-win10-2.role_definition_name}
EOS
}

