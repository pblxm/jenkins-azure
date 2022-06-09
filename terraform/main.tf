terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.9.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "vm_size" {
  type        = string
  description = "VM size for the instance"
  default = "Standard_B2s"
}

variable "key_name" {
  type        = string
  description = "Name of the public key to connect to the instance"
  default = "mykey"
}

variable "admin" {
  type        = string
  description = "Name for the admin user"

  # Value set in deploy script
  default = "pbl" 
}

resource "azurerm_resource_group" "jenkins" {
  name     = "rg-01"
  location = "West Europe"
}

resource "azurerm_virtual_network" "jenkins" {
  name                  = "vnet-01"
  address_space         = ["10.0.0.0/16"]
  resource_group_name   = azurerm_resource_group.jenkins.name
  location              = azurerm_resource_group.jenkins.location
}

resource "azurerm_network_security_group" "jenkins" {
  name                = "jenkins-nsg"
  location            = azurerm_resource_group.jenkins.location
  resource_group_name = azurerm_resource_group.jenkins.name
}

resource "azurerm_application_security_group" "jenkins" {
  name                 = "jenkins-asg"
  location             = azurerm_resource_group.jenkins.location
  resource_group_name  = azurerm_resource_group.jenkins.name
}

resource "azurerm_network_security_rule" "jenkins_endpoint" {
  name                        = "jenkins-endpoint"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.jenkins.name
  network_security_group_name = azurerm_network_security_group.jenkins.name
}

resource "azurerm_network_security_rule" "jenkins_ssh" {
  name                        = "jenkins-ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.jenkins.name
  network_security_group_name = azurerm_network_security_group.jenkins.name
}

resource "azurerm_network_security_rule" "jenkins_end" {
  name                        = "jenkins-end"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "50000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.jenkins.name
  network_security_group_name = azurerm_network_security_group.jenkins.name
}

resource "azurerm_subnet" "public-jenkins" {
  name                 = "public-subnet-01"
  resource_group_name  = azurerm_resource_group.jenkins.name
  virtual_network_name = azurerm_virtual_network.jenkins.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "jenkins" {
  subnet_id                 = azurerm_subnet.public-jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins.id
}

resource "azurerm_storage_account" "jenkins" {
  name                     = "staccjenkins01"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  location            = azurerm_resource_group.jenkins.location
  resource_group_name      = azurerm_resource_group.jenkins.name
}

resource "azurerm_public_ip" "public_ip" {
  name                = "ip-jenkins01"
  resource_group_name = azurerm_resource_group.jenkins.name
  location            = azurerm_resource_group.jenkins.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "jenkins" {
  name                = "nic-jenkins01"
  location            = azurerm_resource_group.jenkins.location
  resource_group_name = azurerm_resource_group.jenkins.name

  ip_configuration {
    name                          = "nic-jenkins01"
    subnet_id                     = azurerm_subnet.public-jenkins.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_application_security_group_association" "jenkins" {
  network_interface_id          = azurerm_network_interface.jenkins.id
  application_security_group_id = azurerm_application_security_group.jenkins.id
}

resource "azurerm_ssh_public_key" "jenkins" {
  name                = var.key_name
  resource_group_name = azurerm_resource_group.jenkins.name
  location            = azurerm_resource_group.jenkins.location
  public_key          = file("~/.ssh/${var.key_name}.pub")
}

resource "azurerm_linux_virtual_machine" "jenkins" {
  name                   = "vm-jenkins01"
  location               = azurerm_resource_group.jenkins.location
  resource_group_name    = azurerm_resource_group.jenkins.name
  network_interface_ids  = [azurerm_network_interface.jenkins.id]
  size                   = var.vm_size
  admin_username         = var.admin
  computer_name          = "jenkins"  

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "jenkins01-disk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  admin_ssh_key {
    username = var.admin
    public_key = azurerm_ssh_public_key.jenkins.public_key
  }
  disable_password_authentication = true
}

output "server_ip" {
  value = azurerm_linux_virtual_machine.jenkins.public_ip_address
}