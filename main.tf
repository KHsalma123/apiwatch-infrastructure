resource "azurerm_resource_group" "apiwatch" {
  name     = "rg-apiwatch-dev"
  location = "Belgium Central"

  tags = {
    project     = "APIWatch"
    environment = "development"
    managed_by  = "Terraform"
  }
}

# 1. Virtual Network
resource "azurerm_virtual_network" "apiwatch" {
  name                = "vnet-apiwatch"
  location            = azurerm_resource_group.apiwatch.location
  resource_group_name = azurerm_resource_group.apiwatch.name
  address_space       = ["10.0.0.0/16"]
}

# 2. Subnet
resource "azurerm_subnet" "apiwatch" {
  name                 = "subnet-apiwatch"
  resource_group_name  = azurerm_resource_group.apiwatch.name
  virtual_network_name = azurerm_virtual_network.apiwatch.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. Network Security Group
resource "azurerm_network_security_group" "apiwatch" {
  name                = "nsg-apiwatch"
  location            = azurerm_resource_group.apiwatch.location
  resource_group_name = azurerm_resource_group.apiwatch.name
}

# 4. Allow HTTP traffic
resource "azurerm_network_security_rule" "http" {
  name                        = "Allow-HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.apiwatch.name
  network_security_group_name = azurerm_network_security_group.apiwatch.name
}

# 5. Allow HTTPS traffic
resource "azurerm_network_security_rule" "https" {
  name                        = "Allow-HTTPS"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.apiwatch.name
  network_security_group_name = azurerm_network_security_group.apiwatch.name
}

# 6. Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "apiwatch" {
  subnet_id                 = azurerm_subnet.apiwatch.id
  network_security_group_id = azurerm_network_security_group.apiwatch.id
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "Allow-SSH-Admin"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${var.admin_ip}/32"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.apiwatch.name
  network_security_group_name = azurerm_network_security_group.apiwatch.name
}

# Public IP
resource "azurerm_public_ip" "apiwatch" {
  name                = "pip-apiwatch"
  location            = azurerm_resource_group.apiwatch.location
  resource_group_name = azurerm_resource_group.apiwatch.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    project = "APIWatch"
  }
}

# Network Interface
resource "azurerm_network_interface" "apiwatch" {
  name                = "nic-apiwatch"
  location            = azurerm_resource_group.apiwatch.location
  resource_group_name = azurerm_resource_group.apiwatch.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.apiwatch.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.apiwatch.id
  }

  tags = {
    project = "APIWatch"
  }
}

locals {
  ssh_public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "azurerm_linux_virtual_machine" "apiwatch" {
  name                = "vm-apiwatch"
  resource_group_name = azurerm_resource_group.apiwatch.name
  location            = azurerm_resource_group.apiwatch.location
  size                = "Standard_B2as_v2"
  zone                = "2"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.apiwatch.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = local.ssh_public_key
  }

  os_disk {
    name                 = "disk-apiwatch-os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    project     = "APIWatch"
    environment = "development"
    managed_by  = "Terraform"
  }
}