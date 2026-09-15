terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
 
provider "azurerm" {
  features {
  }
}
 
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "source" {
  name     = "rg-migrate-source-${var.yourname}"
  location = var.location
  tags     = var.tags
}
 
resource "azurerm_virtual_network" "main" {
  name                = "vnet-migrate-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.source.name
  address_space       = ["10.1.0.0/16"]
  tags                = var.tags
}
 
resource "azurerm_subnet" "main" {
  name                 = "snet-migrate"
  resource_group_name  = azurerm_resource_group.source.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_resource_group" "target" {
  name     = "rg-migrate-target-${var.yourname}"
  location = var.location
  tags     = var.tags
}

# Azure Migrate projects are not supported by the azurerm Terraform provider.
# Create the project manually in the portal after terraform apply:
#   1. Search "Azure Migrate" in the portal
#   2. Click "Create project"
#   3. Select resource group: rg-migrate-source-${var.yourname}
#   4. Project name: migrate-project-${var.yourname}
#   5. Geography: United States
#   6. Click Create
resource "null_resource" "migrate_project_reminder" {
  triggers = {
    resource_group = azurerm_resource_group.source.name
  }
}

resource "azurerm_storage_account" "replication_cache" {
  name                     = "stmigrate${var.yourname}"
  resource_group_name      = azurerm_resource_group.source.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-migrate-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.source.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_recovery_services_vault" "main" {
  name                        = "rsv-migrate-${var.yourname}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.source.name
  sku                         = "Standard"
  soft_delete_enabled         = true
  cross_region_restore_enabled = false
  tags                        = var.tags
}

resource "azurerm_network_security_group" "target_vm" {
  name                = "nsg-migrate-target-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.target.name
 
  security_rule {
    name                       = "allow-rdp"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 
  tags = var.tags
}

resource "azurerm_public_ip" "appliance" {
  name                = "pip-migrate-appliance-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.source.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}
 
resource "azurerm_network_interface" "appliance" {
  name                = "nic-migrate-appliance-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.source.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.appliance.id
  }
  tags = var.tags
}
 
resource "azurerm_network_security_group" "appliance" {
  name                = "nsg-migrate-appliance-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.source.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.tags
}
 
resource "azurerm_network_interface_security_group_association" "appliance" {
  network_interface_id      = azurerm_network_interface.appliance.id
  network_security_group_id = azurerm_network_security_group.appliance.id
}
 
# resource "azurerm_windows_virtual_machine" "appliance" {
#  name                  = "vm-mig-appl-${var.yourname}"
#  computer_name         = "appl-gavin"
#  location              = var.location
#  resource_group_name   = azurerm_resource_group.source.name
#  size                  = "Standard_D4alds_v7"
#  admin_username        = "migrateadmin"
#  admin_password        = var.appliance_admin_password
#  network_interface_ids = [azurerm_network_interface.appliance.id]
# os_disk {
#  caching              = "ReadWrite"
#  storage_account_type = "Standard_LRS"
#  disk_size_gb         = 127
# }

# source_image_reference {
#  publisher = "MicrosoftWindowsServer"
#  offer     = "WindowsServer"
#  sku       = "2022-Datacenter-g2"
#  version   = "latest"
#  }
#  tags = var.tags
# }

resource "azurerm_public_ip" "replication" {
  name                = "pip-migrate-repl-gavinbarbee"
  location            = var.location
  resource_group_name = azurerm_resource_group.source.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "replication" {
  name                = "nic-migrate-repl-gavinbarbee"
  location            = var.location
  resource_group_name = azurerm_resource_group.source.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.replication.id
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "replication" {
  name                = "nsg-migrate-repl-gavinbarbee"
  location            = var.location
  resource_group_name = azurerm_resource_group.source.name

  security_rule {
    name                       = "allow-rdp"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-data-transport-inbound"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "replication" {
  network_interface_id      = azurerm_network_interface.replication.id
  network_security_group_id = azurerm_network_security_group.replication.id
}

resource "azurerm_windows_virtual_machine" "replication" {
  name                   = "vm-mig-repl-gavinbarbee"
  computer_name          = "repl-gavin"
  location               = var.location
  resource_group_name    = azurerm_resource_group.source.name
  size                   = "Standard_D8ads_v7"
  admin_username         = "replicationadmin"
  admin_password         = var.replication_admin_password
  network_interface_ids  = [azurerm_network_interface.replication.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 700
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter-g2"
    version   = "latest"
  }

  tags = var.tags
}