This project demonstrates how to provision and manage real-world infrastructure on **Microsoft Azure** using **Terraform**, following Infrastructure as Code (IaC) best practices. The solution includes networking, VM provisioning, remote backend configuration, CI/CD automation with GitHub Actions, and post-deployment health checks.

## Project Goals

- Use Terraform to provision a complete infrastructure on Azure.
- Configure remote state management with an Azure Storage Account.
- Automate deployment and testing with GitHub Actions workflows.
- Run app on an Azure VM using Docker Compose.
- Document and log the full provisioning process.


## Project Structure

```

./Terraform
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── backend.tf
├── prod/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── backend.tf
├── modules/
│   ├── resource_group/
│   ├── network/
│   └── vm/
```

<details> 
<summary>modules/resouce_group/main.tf</summary>

```
resource "azurerm_resource_group" "this" {
  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = var.tags
}
```
</details>

<details> 
<summary>modules/resouce_group/variables.tf</summary>

```
variable "resource_group" {
  description = "Resource group configuration"
  type = object({
    name     = string
    location = string
  })
}

variable "tags" {
  description = "Tags for the resource group"
  type        = map(string)
}
```
</details>

<details> 
<summary>modules/resouce_group/outputs.tf</summary>

```
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_location" {
  value = azurerm_resource_group.this.location
}
```
</details>

------------------------------------------

<details> 
<summary>modules/network/main.tf</summary>

```
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

resource "azurerm_network_security_rule" "rules" {
  for_each = { for rule in var.nsg_rules : rule.name => rule }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = [each.value.destination_port]
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
```
</details>


<details> 
<summary>modules/network/variables</summary>

```
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
```
</details>



<details> 
<summary>modules/network/outputs.tf</summary>

```
output "subnet_id" {
  value = azurerm_subnet.this.id
}

output "nsg_id" {
  value = azurerm_network_security_group.this.id
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "network_interface_id" {
  description = "The ID of the network interface (NIC)"
  value       = azurerm_network_interface.this.id
}

output "public_ip_id" {
  description = "The ID of the public IP address"
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "Public IP address of the virtual machine"
  value       = azurerm_public_ip.this.ip_address
}
```
</details>


---------------------------------------


<details> 
<summary>modules/vm/main.tf</summary>

```
resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm.size
  admin_username      = var.vm.admin_user

  network_interface_ids = [var.network_interface_id]

  admin_ssh_key {
    username   = var.vm.admin_user
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = var.vm.disk_caching
    storage_account_type = var.vm.disk_storage_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags

}
```
</details>


<details> 
<summary>modules/vm/variables.tf</summary>

```
variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "subnet_id" {
  description = "ID of the subnet to associate with the NIC"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}

variable "vm" {
  description = "Virtual machine configuration"
  type = object({
    name                = string
    size                = string
    admin_user          = string
    public_ip_name      = string
    public_ip_alloc     = string
    nic_name            = string
    ip_config_name      = string
    private_ip_alloc    = string
    disk_caching        = string
    disk_storage_type   = string
  })
}

variable "network_interface_id" {
  description = "The ID of the network interface to attach to the VM"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM"
  type        = string
}
```
</details>


<details> 
<summary>modules/vm/outputs.tf</summary>

```
output "virtual_machine_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "virtual_machine_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.name
}
```
</details>

-----------------------------------

<details> 
<summary>dev/main.tf</summary>

```
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



module "resource_group" {
  source         = "../modules/resource_group"
  resource_group = var.resource_group
  tags           = var.common_tags
}

module "network" {
  source              = "../modules/network"
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

  nsg_rules         = var.nsg_rules
}


module "vm" {
  source               = "../modules/vm"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  subnet_id            = module.network.subnet_id
  tags                 = var.common_tags
  vm                   = var.virtual_machine
  network_interface_id = module.network.network_interface_id
  ssh_public_key       = var.ssh_public_key
}

```
</details>


<details> 
<summary>dev/variables.tf</summary>

```
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
```
</details>


<details> 
<summary>dev/outputs.tf</summary>

```
output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.resource_group.resource_group_name
}

output "public_ip_address" {
  description = "Public IP address of the virtual machine"
  value       = module.network.public_ip_address
}

output "virtual_machine_id" {
  description = "ID of the deployed virtual machine"
  value       = module.vm.virtual_machine_id
}

output "virtual_machine_name" {
  description = "Name of the deployed virtual machine"
  value       = module.vm.virtual_machine_name
}

output "ssh_connection_command" {
  description = "Command to SSH into the VM"
  value       = "ssh ${var.virtual_machine.admin_user}@${module.network.public_ip_address}"
}
```
</details>


<details> 
<summary>dev/terraform.tfvars</summary>

```
resource_group = {
  name     = "dev-rg"
  location = "Israel Central"
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
    name             = "allow-http"
    priority         = 110
    destination_port = 80
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

```
</details>



<details> 
<summary>dev/backend.tf</summary>

```
terraform {
  backend "azurerm" {
    resource_group_name  = "dev-rg"
    storage_account_name = "mtcstatetf"
    container_name       = "tfstate-dev"
    key                  = "terraform.tfstate"
  }
}

```
</details>



--------------------------------------------


<details> 
<summary>prod/main.tf</summary>

```
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



module "resource_group" {
  source         = "../modules/resource_group"
  resource_group = var.resource_group
  tags           = var.common_tags
}

module "network" {
  source              = "../modules/network"
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

  nsg_rules         = var.nsg_rules
}


module "vm" {
  source               = "../modules/vm"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  subnet_id            = module.network.subnet_id
  tags                 = var.common_tags
  vm                   = var.virtual_machine
  network_interface_id = module.network.network_interface_id
  ssh_public_key       = var.ssh_public_key
}


```
</details>



<details> 
<summary>prod/variables.tf</summary>

```
# Resource Group
variable "resource_group" {
  description = "Resource group configuration"
  type = object({
    name     = string
    location = string
  })
}

# Common Tags
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

```
</details>



<details> 
<summary>prod/outputs.tf</summary>

```
output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.resource_group.resource_group_name
}

output "public_ip_address" {
  description = "Public IP address of the virtual machine"
  value       = module.network.public_ip_address
}

output "virtual_machine_id" {
  description = "ID of the deployed virtual machine"
  value       = module.vm.virtual_machine_id
}

output "virtual_machine_name" {
  description = "Name of the deployed virtual machine"
  value       = module.vm.virtual_machine_name
}

output "ssh_connection_command" {
  description = "Command to SSH into the VM"
  value       = "ssh ${var.virtual_machine.admin_user}@${module.network.public_ip_address}"
}

```
</details>


<details> 
<summary>prod/terraform.tfvars</summary>

```
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

```
</details>


<details> 
<summary>prod/backend.tf</summary>

```
terraform {
  backend "azurerm" {
    resource_group_name  = "prod-rg"
    storage_account_name = "mtcstatetf"
    container_name       = "tfstate-prod"
    key                  = "terraform.tfstate"
  }
}

```
</details>



Using modules in Terraform helps us organize and reuse code efficiently. Instead of writing all resource definitions in one big file, we break the infrastructure into logical, reusable components (e.g., resource_group, network, vm).

main.tf
This is the main entry point of a Terraform configuration.
It defines the resources, and in our case, it invokes modules using the module block.

```
module "vm" {
  source = "../modules/vm"
  ...
}
```

variables.tf
Defines the input variables that this Terraform configuration expects.
These variables make the code flexible and reusable by allowing different values in dev and prod.


```
variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}
```

outputs.tf
Defines what outputs Terraform should display after running.
These outputs can be useful for debugging or for using in other configurations (e.g., public IP, SSH command):

```
output "ssh_connection_command" {
  value = "ssh ${var.virtual_machine.admin_user}@${module.network.public_ip_address}"
}
```


terraform.tfvars
This file provides the actual values for the input variables defined in variables.tf.
It’s environment-specific (dev, prod, etc.), and used during terraform apply and terraform plan.


```
resource_group = {
  name     = "dev-rg"
  location = "Israel Central"
}
```

backend.tf
Defines the remote backend configuration, which tells Terraform where to store its state file.
In your case, it's using an Azure Storage Account so multiple people can work on the same project safely:


```
terraform {
  backend "azurerm" {
    resource_group_name  = "dev-rg"
    storage_account_name = "mtcstatetf"
    container_name       = "tfstate-dev"
    key                  = "terraform.tfstate"
  }
}
```


## Steps Overview

### Infrastructure as Code

<details> 
<summary>code view</summary>

[DevOps & Agile methodology](https://github.com/snir1551/DevOps-Linux/wiki/What-is-DevOps-and-Agile-methodology)

</details>



### Docker & Compose


### CI/CD Pipeline


### Healthchecks & Automation


