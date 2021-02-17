provider "azurerm" {
  features {}
}

# Locate the existing custom/golden image
data "azurerm_image" "api_vm" {
  name                = "sample-api-image-2"
  resource_group_name = "HOLPierre"
}

# Virtual network within the resource group
resource "azurerm_virtual_network" "api_vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = "HOLPierre"
  location            = var.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = "HOLPierre"
  virtual_network_name = azurerm_virtual_network.api_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# NSG Network Security Group with some rules
resource "azurerm_network_security_group" "api_nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = "HOLPierre"

  security_rule {
    name                       = "allow_RDP"
    description                = "Allow RDP access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_HTTP"
    description                = "Allow HTTP access"
    priority                   = 111
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Subnet <--> NSG
resource "azurerm_subnet_network_security_group_association" "subnet_default_nsg_api_nsg" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.api_nsg.id
}

resource "azurerm_public_ip" "api_vm_public_ip" {
  name                = "${var.prefix}-vm-pubic-ip"
  resource_group_name = "HOLPierre"
  location            = var.location
  allocation_method   = "Static"
}

# NIC (VM)
resource "azurerm_network_interface" "api_vm_nic" {
  name                = "${var.prefix}-vm-nic"
  location            = var.location
  resource_group_name = "HOLPierre"

  ip_configuration {
    name = "public"
    public_ip_address_id = azurerm_public_ip.api_vm_public_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id = azurerm_subnet.default.id
  }
}

# VM from image
resource "azurerm_windows_virtual_machine" "api_vm" {
  name                = "${var.prefix}-vm"
  resource_group_name = "HOLPierre"
  location            = var.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.api_vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = data.azurerm_image.api_vm.id
}