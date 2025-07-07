resource_group = {
  name     = "dev-rg"
  location = "eastus"
}

common_tags = {
  environment = "dev"
}

virtual_network = {
  name          = "dev-vnet"
  address_space = ["10.0.0.0/16"]
}

subnet = {
  name           = "dev-subnet"
  address_prefix = ["10.0.1.0/24"]
}

network_security_group = {
  name = "dev-nsg"
}

nsg_rules = [
  {
    name             = "allow-ssh"
    priority         = 100
    destination_port = 22
  },
  {
    name             = "allow-frontend"
    priority         = 110
    destination_port = 3000
  },
  {
    name             = "allow-backend"
    priority         = 120
    destination_port = 8080
  }
]


public_ip = {
  name              = "dev-ip"
  allocation_method = "Static"
}

network_interface = {
  name                  = "dev-nic"
  ip_configuration_name = "internal"
  private_ip_allocation = "Dynamic"
}

virtual_machine = {
  name              = "dev-vm"
  size              = "Standard_B1s"
  admin_user        = "azureuser"
  public_ip_name    = "dev-ip"
  public_ip_alloc   = "Static"
  nic_name          = "dev-nic"
  ip_config_name    = "internal"
  private_ip_alloc  = "Dynamic"
  disk_caching      = "ReadWrite"
  disk_storage_type = "Standard_LRS"
}

