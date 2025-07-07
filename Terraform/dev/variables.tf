# Resource Group
variable "resource_group" {
  description = "Resource group configuration"
  type = object({
    name     = string
    location = string
  })
}

# Tags
variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}

# Virtual Network
variable "virtual_network" {
  description = "Virtual network configuration"
  type = object({
    name          = string
    address_space = list(string)
  })
}

# Subnet
variable "subnet" {
  description = "Subnet configuration"
  type = object({
    name           = string
    address_prefix = list(string)
  })
}

# Network Security Group
variable "network_security_group" {
  description = "NSG configuration"
  type = object({
    name = string
  })
}

# NSG Rules
variable "nsg_rules" {
  description = "List of NSG security rules"
  type = list(object({
    name             = string
    priority         = number
    destination_port = number
  }))
}

# Public IP
variable "public_ip" {
  description = "Public IP configuration"
  type = object({
    name              = string
    allocation_method = string
  })
}

# Network Interface
variable "network_interface" {
  description = "NIC configuration"
  type = object({
    name                  = string
    ip_configuration_name = string
    private_ip_allocation = string
  })
}

# Virtual Machine
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
}

# SSH Public Key
variable "ssh_public_key" {
  description = "SSH public key for VM"
  type        = string
}