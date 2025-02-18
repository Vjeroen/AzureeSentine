

# Thanks to @christophetd and his Github.com/Adaz project for this little code
data "http" "firewall_allowed" {
  url = "http://ifconfig.so"
}

locals {
  #src_ip = chomp(data.http.firewall_allowed.response_body)
  src_ip = "0.0.0.0/0"
}

# This is the src_ip for white listing Azure NSGs
# This is going to be replaced by the data http resource above
# allow every public IP address by default
variable "src_ip" {
  default = "2a02:a020:8b:7c2:2c7e:3a75:66d9:9c15"
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.resource_group_name}-nsg1"
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"
  security_rule {
    name                       = "allow-rdp"
    description                = "Allow Remote Desktop"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = local.src_ip 
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-winrms"
    description                = "Windows Remote Managment (HTTPS-In)"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = local.src_ip 
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-winrm"
    description                = "Windows Remote Managment (HTTP-In)"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = local.src_ip 
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-ssh"
    description                = "Allow SSH (SSH-In)"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.src_ip 
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.network]
}
