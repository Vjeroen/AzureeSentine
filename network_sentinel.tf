
# the address space for the vnet
variable "vnet1-address-space" {
  default = "10.100.0.0/16"
}

# Create the VNet 
resource "azurerm_virtual_network" "vnet1-vnet" {
  name                = "${var.resource_group_name}-${random_string.suffix.id}-vnet"
  address_space       = [var.vnet1-address-space]
  location            = var.location
  resource_group_name = "${var.resource_group_name}-${random_string.suffix.id}"

  depends_on = [azurerm_resource_group.network]
}


variable "ad_subnet-name" {
  default = "ad_subnet"
}

variable "ad_subnet-prefix" {
  default = "10.100.10.0/24"
}

# Create the ad_subnet subnet
resource "azurerm_subnet" "ad_subnet-subnet" {
  name                 = "${var.resource_group_name}-${var.ad_subnet-name}-${random_string.suffix.id}"
  resource_group_name  = "${var.resource_group_name}-${random_string.suffix.id}"
  virtual_network_name = azurerm_virtual_network.vnet1-vnet.name
  address_prefixes     = [var.ad_subnet-prefix]
  service_endpoints    = ["Microsoft.Storage"]

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_subnet_network_security_group_association" "nsg-association-ad_subnet" {
  subnet_id            = azurerm_subnet.ad_subnet-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  depends_on = [azurerm_resource_group.network]
}


variable "user_subnet-name" {
  default = "user_subnet"
}

variable "user_subnet-prefix" {
  default = "10.100.20.0/24"
}

# Create the user_subnet subnet
resource "azurerm_subnet" "user_subnet-subnet" {
  name                 = "${var.resource_group_name}-${var.user_subnet-name}-${random_string.suffix.id}"
  resource_group_name  = "${var.resource_group_name}-${random_string.suffix.id}"
  virtual_network_name = azurerm_virtual_network.vnet1-vnet.name
  address_prefixes     = [var.user_subnet-prefix]
  service_endpoints    = ["Microsoft.Storage"]

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_subnet_network_security_group_association" "nsg-association-user_subnet" {
  subnet_id            = azurerm_subnet.user_subnet-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  depends_on = [azurerm_resource_group.network]
}


variable "security_subnet-name" {
  default = "security_subnet"
}

variable "security_subnet-prefix" {
  default = "10.100.30.0/24"
}

# Create the security_subnet subnet
resource "azurerm_subnet" "security_subnet-subnet" {
  name                 = "${var.resource_group_name}-${var.security_subnet-name}-${random_string.suffix.id}"
  resource_group_name  = "${var.resource_group_name}-${random_string.suffix.id}"
  virtual_network_name = azurerm_virtual_network.vnet1-vnet.name
  address_prefixes     = [var.security_subnet-prefix]
  service_endpoints    = ["Microsoft.Storage"]

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_subnet_network_security_group_association" "nsg-association-security_subnet" {
  subnet_id            = azurerm_subnet.security_subnet-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  depends_on = [azurerm_resource_group.network]
}


variable "attack_subnet-name" {
  default = "attack_subnet"
}

variable "attack_subnet-prefix" {
  default = "10.100.40.0/24"
}

# Create the attack_subnet subnet
resource "azurerm_subnet" "attack_subnet-subnet" {
  name                 = "${var.resource_group_name}-${var.attack_subnet-name}-${random_string.suffix.id}"
  resource_group_name  = "${var.resource_group_name}-${random_string.suffix.id}"
  virtual_network_name = azurerm_virtual_network.vnet1-vnet.name
  address_prefixes     = [var.attack_subnet-prefix]
  service_endpoints    = ["Microsoft.Storage"]

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_subnet_network_security_group_association" "nsg-association-attack_subnet" {
  subnet_id            = azurerm_subnet.attack_subnet-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
  depends_on = [azurerm_resource_group.network]
}
