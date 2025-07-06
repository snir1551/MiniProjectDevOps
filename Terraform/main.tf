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
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# resource "azurerm_resource_group" "imported" {
#   name     = "new_resource"
#   location = "israelcentral"
# }


module "resource_group" {
  source         = "./modules/resource_group"
  resource_group = var.resource_group
  tags           = var.common_tags
}

module "network" {
  source              = "./modules/network"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  tags                = var.common_tags

  virtual_network = {
    name          = var.virtual_network.name
    address_space = var.virtual_network.address_space
  }

  subnet = {
    name           = var.subnet.name
    address_prefix = var.subnet.address_prefix
  }

  nsg = {
    name      = var.network_security_group.name
    rule_name = "ssh-rule"
  }

  public_ip         = var.public_ip
  network_interface = var.network_interface
}


module "vm" {
  source               = "./modules/vm"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  subnet_id            = module.network.subnet_id
  tags                 = var.common_tags
  vm                   = var.virtual_machine
  network_interface_id = module.network.network_interface_id
  ssh_public_key       = var.ssh_public_key
}



