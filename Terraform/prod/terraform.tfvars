resource_group = {
  name     = "prod-rg"
  location = "Israel Central"
}

common_tags = {
  environment = "prod"
}

virtual_network = {
  name          = "prod-vnet"
  address_space = ["10.1.0.0/16"]
}

subnet = {
  name           = "prod-subnet"
  address_prefix = ["10.1.1.0/24"]
}

network_security_group = {
  name = "prod-nsg"
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
  name              = "prod-ip"
  allocation_method = "Static"
}

network_interface = {
  name                  = "prod-nic"
  ip_configuration_name = "internal"
  private_ip_allocation = "Dynamic"
}

virtual_machine = {
  name              = "prod-vm"
  size              = "Standard_B1s"
  admin_user        = "azureuser"
  public_ip_name    = "prod-ip"
  public_ip_alloc   = "Static"
  nic_name          = "prod-nic"
  ip_config_name    = "internal"
  private_ip_alloc  = "Dynamic"
  disk_caching      = "ReadWrite"
  disk_storage_type = "Standard_LRS"
}