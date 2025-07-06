# Resource Group
variable "resource_group" {
  description = "Resource group configuration"
  type = object({
    name     = string
    location = string
  })
  default = {
    name     = "mtc-resources"
    location = "Israel Central"
  }
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    environment = "dev"
  }
}


# Virtual Network
variable "virtual_network" {
  description = "Virtual network configuration"
  type = object({
    name          = string
    address_space = list(string)
  })
  default = {
    name          = "mtc-network"
    address_space = ["10.123.0.0/16"]
  }
}


# Subnet
variable "subnet" {
  description = "Subnet configuration"
  type = object({
    name           = string
    address_prefix = list(string)
  })
  default = {
    name           = "mtc-subnet"
    address_prefix = ["10.123.1.0/24"]
  }
}


# Network Security Group
variable "network_security_group" {
  description = "NSG configuration"
  type = object({
    name = string
  })
  default = {
    name = "mtc-nsg"
  }
}

# Public IP
variable "public_ip" {
  description = "Public IP configuration"
  type = object({
    name              = string
    allocation_method = string
  })
  default = {
    name              = "mtc-ip"
    allocation_method = "Static"
  }
}

# Network Interface
variable "network_interface" {
  description = "NIC configuration"
  type = object({
    name                  = string
    ip_configuration_name = string
    private_ip_allocation = string
  })
  default = {
    name                  = "mtc-nic"
    ip_configuration_name = "internal"
    private_ip_allocation = "Dynamic"
  }
}

variable "virtual_machine" {
  description = "Virtual machine configuration"
  type = object({
    name              = string
    size              = string
    admin_user        = string
    public_ip_name    = string
    public_ip_alloc   = string
    nic_name          = string
    ip_config_name    = string
    private_ip_alloc  = string
    disk_caching      = string
    disk_storage_type = string
  })
  default = {
    name              = "mtc-vm"
    size              = "Standard_B1s"
    admin_user        = "azureuser"
    public_ip_name    = "mtc-ip"
    public_ip_alloc   = "Static"
    nic_name          = "mtc-nic"
    ip_config_name    = "internal"
    private_ip_alloc  = "Dynamic"
    disk_caching      = "ReadWrite"
    disk_storage_type = "Standard_LRS"
  }
}

variable "ssh_public_key" {
  description = "SSH public key for VM"
  type        = string
}