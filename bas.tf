

# -------------------------------
# VNET & SUBNET
# -------------------------------
resource "azurerm_virtual_network" "caldera_vnet" {
  name                = "caldera-vnet"
  location            = var.location
  resource_group_name = "${azurerm_resource_group.network.name}"
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "caldera_subnet" {
  name                 = "caldera-subnet"
  resource_group_name  = "${azurerm_resource_group.network.name}"
  virtual_network_name = azurerm_virtual_network.caldera_vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

# -------------------------------
# PUBLIC IP & NETWORK INTERFACE
# -------------------------------
resource "azurerm_public_ip" "caldera_public_ip" {
  name                = "caldera-public-ip"
  location            = var.location
  resource_group_name = "${azurerm_resource_group.network.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "caldera_nic" {
  name                = "caldera-nic"
  location            = var.location
  resource_group_name = "${azurerm_resource_group.network.name}"

  ip_configuration {
    name                          = "caldera-ipconfig"
    subnet_id                     = azurerm_subnet.caldera_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.caldera_public_ip.id
  }
}

# -------------------------------
# NETWORK SECURITY GROUP (NSG)
# -------------------------------
resource "azurerm_network_security_group" "caldera_nsg" {
  name                = "caldera-nsg"
  location            = var.location
  resource_group_name = "${azurerm_resource_group.network.name}"

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Caldera"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8888"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "Allow-Caldera-agent"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2222"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with the Subnet
resource "azurerm_subnet_network_security_group_association" "caldera_nsg_association" {
  subnet_id                 = azurerm_subnet.caldera_subnet.id
  network_security_group_id = azurerm_network_security_group.caldera_nsg.id
}

# -------------------------------
# VIRTUAL MACHINE (CALDERA SERVER)
# -------------------------------
resource "azurerm_linux_virtual_machine" "caldera_vm" {
  name                  = var.caldera_vm_name
  resource_group_name   = "${azurerm_resource_group.network.name}"
  location              = var.location
  size                  = var.caldera_vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.caldera_nic.id]

  os_disk {
    name                 = "${var.caldera_vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.caldera_os_disk_size
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-DAILY-LTS"
    version   = "latest"
  }
}

# -------------------------------
# CUSTOM SCRIPT EXTENSION - INSTALL CALDERA
# -------------------------------
locals {
  caldera_local_yml = templatefile("${path.module}/files/caldera/local.yml.tpl", {
    api_key_blue            = var.api_key_blue 
    api_key_red             = var.api_key_red
    blue_username           = var.blue_username
    blue_password           = var.blue_password
    caldera_admin_username  = var.caldera_admin_username
    caldera_admin_password  = var.caldera_admin_password
    red_username            = var.red_username
    red_password            = var.red_password
    caldera_port            = var.caldera_port_https
    caldera_listen          = var.caldera_port
    caldera_host       = azurerm_linux_virtual_machine.caldera_vm.public_ip_address
    caldera_transport       = var.caldera_transport_protocol
  })
}


# Create a storage account for caldera files
resource "azurerm_storage_account" "caldera_files_account" {
  name                     = "cl${random_string.suffix.id}"
  resource_group_name = "${azurerm_resource_group.network.name}"
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  depends_on = [azurerm_resource_group.network]
}

# Create storage container caldere files
resource "azurerm_storage_container" "caldera_files_container" {
  name                  = "provisioning"
  storage_account_name  = azurerm_storage_account.caldera_files_account.name
  container_access_type = "blob"

  depends_on = [azurerm_resource_group.network]
}

# Upload SwiftOnSecurity Sysmon configuration xml file
resource "azurerm_storage_blob" "caldera_files_blob" {
  name                   = "bootstrap.sh"
  storage_account_name   = azurerm_storage_account.caldera_files_account.name
  storage_container_name = azurerm_storage_container.caldera_files_container.name
  type                   = "Block"
  source                 = "${path.module}/files/caldera/bootstrap.sh.tpl"
}

/*resource "azurerm_virtual_machine_extension" "caldera_script" {
  name                 = "CalderaCustomScript"
  virtual_machine_id   = azurerm_linux_virtual_machine.caldera_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    fileUris = ["https://${azurerm_storage_account.caldera_files_account.name}.blob.core.windows.net/${azurerm_storage_container.caldera_files_container.name}/${azurerm_storage_blob.caldera_files_blob.name}"]
    commandToExecute = "bash bootstrap.sh"
  })
}*/
/*resource "azurerm_virtual_machine_extension" "caldera_install" {
  name                 = "caldera-install"
  virtual_machine_id   = azurerm_linux_virtual_machine.caldera_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = jsonencode({
    script = <<EOT
#!/bin/bash
sudo apt update -y
sudo apt install -y git python3 python3-pip
git clone https://github.com/mitre/caldera.git --recursive
cd caldera
pip3 install -r requirements.txt
nohup python3 server.py --host 0.0.0.0 --port 8888 > caldera.log 2>&1 &
EOT
  })

  depends_on = [azurerm_linux_virtual_machine.caldera_vm]
}*/

# -------------------------------
# OUTPUT: PUBLIC IP FOR CALDERA
# -------------------------------
output "caldera_server_ip" {
  value       = azurerm_public_ip.caldera_public_ip.ip_address
  description = "Public IP address of the Caldera C2 server"
}
