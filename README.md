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

## Steps Overview

### Architecture Flow Diagram 

![miniproject drawio (2)](https://github.com/user-attachments/assets/1220cacd-b9af-40c3-b9dc-2322c5c37621)




### Infrastructure as Code

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

GitHub Actions Workflows:

<details> 
<summary>terraform-remote-state-initialization</summary>

```
name: Terraform Backend Setup

on:
  workflow_dispatch:
  workflow_call:
    inputs:
      environment:
        description: "Environment (dev/prod)"
        required: true
        type: string

jobs:
  setup-backend:
    name: Create Storage Account + Container for Terraform State
    runs-on: ubuntu-latest

    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Create Backend Storage Resources
        env:
          ENVIRONMENT: ${{ inputs.environment }}
        run: |
          echo "ENVIRONMENT: $ENVIRONMENT"
          echo "CONTAINER_NAME: tfstate-${ENVIRONMENT}"
          RESOURCE_GROUP="${ENVIRONMENT}-rg"
          STORAGE_ACCOUNT="mtcstatetf" # MUST be globally unique
          CONTAINER_NAME="tfstate-${ENVIRONMENT}"
          LOCATION="israelcentral"

          echo "Checking for existing resource group..."
          az group show --name $RESOURCE_GROUP || \
          az group create --name $RESOURCE_GROUP --location $LOCATION

          echo "Checking for existing storage account..."
          az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP || \
          az storage account create \
            --name $STORAGE_ACCOUNT \
            --resource-group $RESOURCE_GROUP \
            --location $LOCATION \
            --sku Standard_LRS \

          echo "Getting storage account key..."
          ACCOUNT_KEY=$(az storage account keys list \
            --resource-group $RESOURCE_GROUP \
            --account-name $STORAGE_ACCOUNT \
            --query '[0].value' -o tsv)

          echo "Checking for existing container..."
          az storage container show \
            --name $CONTAINER_NAME \
            --account-name $STORAGE_ACCOUNT \
            --account-key $ACCOUNT_KEY || \
          az storage container create \
            --name $CONTAINER_NAME \
            --account-name $STORAGE_ACCOUNT \
            --account-key $ACCOUNT_KEY

          echo "Backend container for '${{ inputs.environment }}' environment is ready."
```

</details>

<details> 
<summary>deploy-infrastructure.yml</summary>

```
name: Deploy-Infrastructure (Terraform)

on:
  workflow_call:
    inputs:
        environment:
          description: "Environment to deploy (dev/prod)"
          required: true
          type: string
    outputs:
      vm_ip:
        description: "Public IP of the VM"
        value: ${{ jobs.terraform.outputs.vm_ip }}
    secrets:
      AZURE_CREDENTIALS:
        required: true
      VM_SSH_KEY:
        required: true

jobs:
  terraform:
    name: Terraform Setup
    runs-on: ubuntu-latest
    outputs:
      vm_ip: ${{ steps.vm_ip.outputs.vm_ip }}
    defaults:
      run:
        working-directory: ./Terraform/${{ inputs.environment }}
    env:
      ARM_CLIENT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientId }}
      ARM_CLIENT_SECRET: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientSecret }}
      ARM_SUBSCRIPTION_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).subscriptionId }}
      ARM_TENANT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).tenantId }}
      ENVIRONMENT: ${{ inputs.environment }}

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Azure Login (CLI)
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.6

      - name: Write SSH Private Key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.VM_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa

      - name: Derive SSH Public Key
        id: ssh
        run: |
          ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub
          echo "ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" >> "$GITHUB_OUTPUT"

      - name: Terraform Init
        run: |
          echo '## terraform init' >> deployment_log.md
          echo "Initializing Terraform..." >> deployment_log.md
          terraform init 2>&1 | tee -a deployment_log.md

      - name: Conditionally Import Resource Group
        run: |
          RG_NAME="${ENVIRONMENT}-rg"
          SUB_ID="${{ env.ARM_SUBSCRIPTION_ID }}"
          MODULE_PATH="module.resource_group.azurerm_resource_group.this"

          echo "Checking if resource group is already in Terraform state..."
          if terraform state list | grep -q "$MODULE_PATH"; then
            echo "Resource group already managed in Terraform state. Skipping import."
          else
            echo "Checking if resource group exists in Azure..."
            EXISTS=$(az group exists --resource-group "$RG_NAME")
            if [ "$EXISTS" == "true" ]; then
              echo "Resource group exists. Importing into Terraform state..."
              terraform import -input=false -lock=false \
                -var="ssh_public_key=${{ steps.ssh.outputs.ssh_public_key }}" \
                "$MODULE_PATH" "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME"
            else
              echo "Resource group does not exist. Terraform will create it during apply."
            fi
          fi


      - name: Terraform Apply
        run: |
          echo '## terraform apply' >> deployment_log.md
          echo "Applying Terraform configuration..." >> deployment_log.md
          terraform apply -auto-approve \
            -var="ssh_public_key=${{ steps.ssh.outputs.ssh_public_key }}" 2>&1 | tee -a deployment_log.md

      - name: Terraform Output
        id: vm_ip
        run: |
          echo '## terraform output' >> deployment_log.md
          IP=$(terraform output -raw public_ip_address)
          echo "Public IP from Terraform: $IP" | tee -a deployment_log.md
          echo "vm_ip=$IP" >> $GITHUB_OUTPUT

      - name: Upload Terraform Deployment Log
        uses: actions/upload-artifact@v4
        with:
          name: terraform-deployment-log
          path: ./Terraform/deployment_log.md
```

</details>

#### Screenshot

![image](https://github.com/user-attachments/assets/96b0e0f0-1111-46c9-8184-dc5f2e46874c)




### Docker & Compose

#### App Project Structure
```
app/
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       └── index.ts
│
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       └── main.tsx
│
├── scripts/
│   └── ... (optional helper scripts)
│
├── docker-compose.yml
└── README.md
```

<details> 
<summary>app/backend/Dockerfile</summary>

```
FROM node:18-slim

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8080

CMD ["npm", "run", "dev"]
```

#### Dockerfile Explanation
```
FROM node:18-slim
```
- Uses the official Node.js v18 slim image as the base image.
- The slim version is lightweight and contains only essential packages, making the final image smaller.

```
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
```
- Updates the package list, installs curl, and then removes cached files to reduce image size.
- curl is often used for debugging or downloading files during development.

```
WORKDIR /app
```
- Sets the working directory to /app.
- If the directory doesn’t exist, it will be created.
- All subsequent instructions like COPY, RUN, etc. will be executed from this directory.

```
COPY package*.json ./
```
- Copies package.json and package-lock.json into the container.
- This allows Docker to cache dependencies and avoid reinstalling them unless these files change.

```
RUN npm install
```
- Installs all dependencies listed in package.json.

```
COPY . .
```
- Copies all remaining files from the host machine into the container's /app directory.

```
EXPOSE 8080
```
- Documents that the application inside the container will run on port 8080.
- This does not publish the port. It's just metadata for tools like Docker Compose

```
CMD ["npm", "run", "dev"]
```
- Defines the default command to run when the container starts.
- In this case, it starts the app using nodemon
</details>


<details> 
<summary>app/frontend/Dockerfile</summary>

```
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

RUN apk add --no-cache curl

COPY . .

EXPOSE 3000
CMD ["npm", "start"]
```

#### Dockerfile Explanation

```
FROM node:18-alpine
```
- Uses the official Node.js version 18 based on the Alpine Linux distribution.
- alpine is a minimal image, reducing the size significantly.
- Ideal for frontend apps where keeping the image lightweight is important.

```
WORKDIR /app
```
- Sets the working directory inside the container to /app.
- All following commands (like COPY, RUN, etc.) will execute from this path.

```
COPY package*.json ./
```
- Copies both package.json and package-lock.json into the container.
- This allows Docker to cache npm install, speeding up rebuilds if dependencies haven’t changed.

```
RUN npm install
```
- Installs all Node.js dependencies listed in package.json.
- Since only the package*.json files were copied earlier, this layer is cached until those files change.

```
RUN apk add --no-cache curl
```
- Installs curl using Alpine's package manager apk.
- The --no-cache flag avoids storing cache files, keeping the image small.
- curl may be used for health checks, debugging, or testing APIs from within the container.


```
COPY . .
```
- Copies the entire frontend project (including src, public, etc.) into the /app folder in the container.

```
EXPOSE 3000
```
- Documents that the application runs on port 3000 inside the container.
- Does not publish the port automatically —> this must be done with -p or in docker-compose.yml.

```
CMD ["npm", "start"]
```
- Specifies the default command to run when the container starts.
- Typically, npm start runs the React development server (e.g., react-scripts start).

</details>


<details> 
<summary>app/backend/docker-compose.yml</summary>

```
version: "3.8"

services:
  backend:
    build: ./backend
    ports:
      - "${BACKEND_PORT}:${BACKEND_PORT}"
    # volumes:
    #   - ./backend:/app
    #   - /app/node_modules
    env_file:
      - .env
    depends_on:
      - mongo
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${BACKEND_PORT}"]
      interval: 30s
      timeout: 5s
      retries: 3
    restart: unless-stopped
    networks:
      - appnet

  frontend:
    build: ./frontend
    ports:
      - "${FRONTEND_PORT}:${FRONTEND_PORT}"
    env_file:
      - .env
    depends_on:
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${FRONTEND_PORT}"]
      interval: 20s
      timeout: 5s
      retries: 5
      start_period: 40s
    restart: unless-stopped
    networks:
      - appnet


  mongo:
    image: mongo
    ports:
      - "${MONGO_PORT}:${MONGO_PORT}"
    env_file:
      - .env
    volumes:
      - mongo-data:/data/db
    restart: unless-stopped
    networks:
      - appnet

volumes:
  mongo-data:


networks:
  appnet:
    driver: bridge
```

This docker-compose.yml defines a multi-service Docker application including a frontend, backend, and MongoDB service.

##### Version:
```
version: "3.8"
```
- Specifies the Compose file format version.
- Version 3.8 is compatible with modern Docker features and widely supported.

##### backend service:
```
  backend:
    build: ./backend
```
- Builds the Docker image from the ./backend folder using its Dockerfile.

```
    ports:
      - "${BACKEND_PORT}:${BACKEND_PORT}"
```
- Maps the backend port from container to host using a .env variable (e.g., 8080:8080).

```
    env_file:
      - .env
```
- Loads environment variables from .env file into the container.

```
    depends_on:
      - mongo
```
- Ensures the mongo container starts before backend.

```
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${BACKEND_PORT}"]
      interval: 30s
      timeout: 5s
      retries: 3
```
- Checks the backend health by sending a request to localhost:${BACKEND_PORT} every 30s.

```
restart: unless-stopped
```
- Automatically restarts the container unless it was explicitly stopped.

```
    networks:
      - appnet
```
- Connects the service to the shared appnet network.


###### frontend service

```
  frontend:
    build: ./frontend
```
- Builds the Docker image from the ./frontend folder.

```
    ports:
      - "${FRONTEND_PORT}:${FRONTEND_PORT}"
```
- Maps the frontend port from container to host using a .env variable (e.g., 3000:3000).

```
    depends_on:
      - backend
```
- Ensures the backend starts before the frontend.

```
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${FRONTEND_PORT}"]
      interval: 20s
      timeout: 5s
      retries: 5
      start_period: 40s
```
- Waits 40s before starting health checks; checks if frontend is reachable.

```
    restart: unless-stopped
    networks:
      - appnet
```
- Auto-restarts unless stopped and joins appnet network.


##### mongo service

```
  mongo:
    image: mongo
```
- Uses the official mongo image from Docker Hub.

```
    ports:
      - "${MONGO_PORT}:${MONGO_PORT}"
```
- Exposes MongoDB on a host port defined in .env (e.g., 27017:27017).

```
    env_file:
      - .env
```
- Loads environment variables for MongoDB if needed (e.g., MONGO_INITDB_ROOT_USERNAME).

```
    volumes:
      - mongo-data:/data/db
```
Uses a named volume (mongo-data) to persist MongoDB data between restarts.

```
    restart: unless-stopped
    networks:
      - appnet
```
- Ensures MongoDB runs reliably and is connected to the shared app network.

##### Volumes

```
volumes:
  mongo-data:
```
- Named volume to persist MongoDB data outside the container lifecycle.


##### Networks

```
networks:
  appnet:
    driver: bridge
```
- Defines a custom bridge network for isolated communication between services.

</details>


### CI/CD Pipeline

```
https://github.com/snir1551/MiniProjectDevOps/blob/main/.github/workflows/cicd.yml
```

![image](https://github.com/user-attachments/assets/270aaab6-40b0-4bd0-8190-18ea236ebfd6)



### Healthchecks & Automation







<details> 
<summary>Healthcheck</summary>

```
name: Post-Reboot Healthcheck on App Ports Task9

on:
  workflow_dispatch:
  workflow_call:
    inputs:
      vm_ip:
        required: true
        type: string
  

jobs:
  check-access:
    runs-on: ubuntu-latest

    steps:
        
      - name: Check HTTP access on port 3000 (Frontend)
        run: |
          echo "Checking http://${{ inputs.vm_ip }}:3000 ..." > access-check.log
          if curl --fail --silent http://${{ inputs.vm_ip }}:3000; then
            echo "Port 3000 is accessible." >> access-check.log
          else
            echo "Port 3000 is NOT accessible." >> access-check.log
            exit 1
          fi

      - name: Check HTTP access on port 8080 (Backend)
        run: |
          echo "Checking http://${{ inputs.vm_ip }}:8080 ..." >> access-check.log
          if curl --fail --silent http://${{ inputs.vm_ip }}:8080; then
            echo "Port 8080 is accessible." >> access-check.log
          else
            echo "Port 8080 is NOT accessible." >> access-check.log
            exit 1
          fi

      - name: Upload access check log
        uses: actions/upload-artifact@v4
        with:
          name: post-reboot-healthcheck-log
          path: access-check.log
```

</details>


-------------------------------

<details> 
<summary>Deploy-App</summary>

```
name: Deploy to Azure VM 

on:
  workflow_dispatch:
  workflow_call:
    inputs:
      vm_ip:
        required: true
        type: string
      environment:
        description: "Environment (dev/prod)"
        required: true
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Write SSH key
        run: |
          echo "${{ secrets.VM_SSH_KEY }}" > key.pem
          chmod 600 key.pem

      - name: Create .env file
        run: |
          echo "${{ secrets.ENV_FILE }}" > app/.env
          echo "REACT_APP_API_URL=http://${{ inputs.vm_ip }}:8080" >> app/.env

      - name: Clean Docker on VM
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "
            echo 'Cleaning Docker environment...'

            containers=\$(docker ps -q)
            if [ -n \"\$containers\" ]; then
              echo 'Stopping running containers...'
              docker stop \$containers
            else
              echo 'No running containers to stop.'
            fi

            sudo docker container prune -f
            sudo docker image prune -af
            sudo docker network prune -f

            volumes=\$(docker volume ls -q)
            if [ -n \"\$volumes\" ]; then
              echo 'Removing all Docker volumes...'
              docker volume rm \$volumes
            else
              echo 'No Docker volumes to remove.'
            fi
          "

      - name: Debug SSH command
        run: echo "ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }}"

      - name: Sync app folder to Azure VM
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "mkdir -p /home/azureuser/MiniProject/app"
          rsync -az --delete --exclude='.git' --exclude='node_modules' -e "ssh -i key.pem -o StrictHostKeyChecking=no" ./app/ azureuser@${{ inputs.vm_ip }}:/home/azureuser/MiniProject/app/

      - name: Run setup script on VM
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} << 'EOF'
            cd /home/azureuser/MiniProject/app/scripts
            chmod +x setup.sh
            ./setup.sh
          EOF

      - name: Deploy with Docker Compose
        env:
          ENVIRONMENT: ${{ inputs.environment }}
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "
            cd /home/azureuser/MiniProject/app &&
            sudo docker-compose -f docker-compose.yml -f docker-compose.${ENVIRONMENT}.yml down --remove-orphans
            sudo docker-compose -f docker-compose.yml -f docker-compose.${ENVIRONMENT}.yml up -d --build
          "

      - name: Healthcheck and get logs
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "
            sudo docker ps
          " > remote_logs.txt

      - name: Logs from Azure VM
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "
            cd /home/azureuser/MiniProject/app
            sudo docker-compose ps
            sudo docker-compose logs --tail=50
          " > remote_logs.txt

      - name: Upload logs
        uses: actions/upload-artifact@v4
        with:
          name: remote-logs
          path: remote_logs.txt

      - name: Cleanup SSH key
        run: rm key.pem

      - name: Cleanup .env file
        if: always()
        run: rm -f app/.env
```

</details>





### Resilience Check

![image](https://github.com/user-attachments/assets/c622f48f-0289-4823-b2a9-77c9cd63cbaf)

