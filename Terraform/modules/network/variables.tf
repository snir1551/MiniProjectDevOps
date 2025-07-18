variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}

variable "virtual_network" {
  type = object({
    name          = string
    address_space = list(string)
  })
}

variable "subnet" {
  type = object({
    name           = string
    address_prefix = list(string)
  })
}

variable "nsg" {
  type = object({
    name = string
  })
  description = "NSG configuration (name only)"
}

variable "nsg_rules" {
  description = "List of NSG security rules"
  type = list(object({
    name             = string
    priority         = number
    destination_port = number
  }))
}

variable "public_ip" {
  description = "Public IP configuration"
  type = object({
    name              = string
    allocation_method = string
  })
}

variable "network_interface" {
  description = "NIC configuration"
  type = object({
    name                  = string
    ip_configuration_name = string
    private_ip_allocation = string
  })
}