provider "azurerm" {
  features {}
  subscription_id = "a06745d9-354b-4624-b974-3dc2646c6d2e"
}

resource "azurerm_resource_group" "rg" {
  name     = "gotrip-resources"
  location = "Canada Central"
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "gotrip-postgres"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = "postgres"
  administrator_password = var.postgres_password
  version                = "13"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768

  authentication {
    password_auth_enabled = true
  }

  delegated_subnet_id = null
  # zone and high_availability intentionally omitted to avoid unwanted changes
}

resource "azurerm_postgresql_flexible_server_database" "gotripdb" {
  name      = "gotripdb"
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "gotrip-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "gotrip-vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

  # Add this new rule for your Flask app
  security_rule {
    name                       = "Allow-Flask-App"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Add this new rule for Node.js backend
  security_rule {
    name                       = "Allow-Node-Backend"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_virtual_network" "vm_vnet" {
  name                = "gotrip-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "gotrip-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "gotrip-vm-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_linux_virtual_machine" "flask_vm" {
  name                = "gotrip-flask-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  admin_password = var.vm_admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "gotrip-flask-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  disable_password_authentication = false
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all" {
  name                = "allow-all"
  server_id           = azurerm_postgresql_flexible_server.db.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# --- HTTP VM Resources ---

resource "azurerm_public_ip" "http_vm_public_ip" {
  name                = "gotrip-http-vm-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "http_vm_nic" {
  name                = "gotrip-http-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.http_vm_public_ip.id
  }
}

resource "azurerm_network_security_group" "http_vm_nsg" {
  name                = "gotrip-http-vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "http_vm_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.http_vm_nic.id
  network_security_group_id = azurerm_network_security_group.http_vm_nsg.id
}

resource "azurerm_linux_virtual_machine" "http_vm" {
  name                = "gotrip-http-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.http_vm_nic.id]

  admin_password = var.vm_admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "gotrip-http-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  disable_password_authentication = false
}

# NOTE: 'azurerm_app_service_plan' is deprecated. Consider migrating to 'azurerm_service_plan' in the future.
