resource "azurerm_virtual_network" "this" {
  name                = var.virtual_network.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.virtual_network.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  name                 = var.subnet.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.subnet.address_prefix
}

resource "azurerm_network_security_group" "this" {
  name                = var.nsg.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  name                        = var.nsg.rule_name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["22"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
  name                = var.public_ip.name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.public_ip.allocation_method
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = var.network_interface.name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = var.network_interface.ip_configuration_name
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = var.network_interface.private_ip_allocation
    public_ip_address_id          = azurerm_public_ip.this.id
  }

  tags = var.tags
}