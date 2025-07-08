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




## Steps Overview

### Infrastructure as Code

<details> 
<summary>code view</summary>

[DevOps & Agile methodology](https://github.com/snir1551/DevOps-Linux/wiki/What-is-DevOps-and-Agile-methodology)

</details>



### Docker & Compose


### CI/CD Pipeline


### Healthchecks & Automation

### Step 4 – Apply Infrastructure

Used `terraform apply` via GitHub Actions (`Terraform Deploy Task9`):

- Automatically writes SSH key
- Initializes and applies Terraform
- Imports existing resource group if needed
- Outputs the VM's public IP for next steps

Output is consumed by other workflows via `workflow_call`.


```
name: Terraform Deploy Task9

on:
  workflow_call:
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
        working-directory: week9/week9_summery/Terraform
    env:
      ARM_CLIENT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientId }}
      ARM_CLIENT_SECRET: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientSecret }}
      ARM_SUBSCRIPTION_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).subscriptionId }}
      ARM_TENANT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).tenantId }}

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
        run: terraform init

      - name: Conditionally Import Resource Group
        run: |
          RG_NAME="mtc-resources"
          SUB_ID="${{ env.ARM_SUBSCRIPTION_ID }}"
          MODULE_PATH="module.resource_group.azurerm_resource_group.this"

          echo "Checking if resource group is already in Terraform state..."
          if terraform state list | grep -q "$MODULE_PATH"; then
            echo "Resource group already managed in Terraform state. Skipping import."
          else
            echo "Checking if resource group exists in Azure..."
            EXISTS=$(az group exists --name "$RG_NAME")
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
          terraform apply -auto-approve \
            -var="ssh_public_key=${{ steps.ssh.outputs.ssh_public_key }}"

      - name: Terraform Output
        id: vm_ip
        run: |
          IP=$(terraform output -raw public_ip_address)
          echo "Public IP from Terraform: $IP"
          echo "vm_ip=$IP" >> $GITHUB_OUTPUT

```
screenshots of successful execution:

![image](https://github.com/user-attachments/assets/15f5b115-3ff7-4927-a446-aa75a6ca33f9)


### Step 5,6 – Healthcheck Script and Automatic Deployment (Optional)

This GitHub Action automates the deployment of the app to the Azure VM and performs a basic health check.

 Application Stack:

Node.js frontend – exposed on port 3000

MongoDB backend – accessible on port 8080

Uses version-controlled docker-compose.yml

 App URL: http://51.4.113.244:3000/

```
name: Deploy to Azure VM Task8

on:
  workflow_dispatch:
  workflow_call:
    inputs:
      vm_ip:
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
        run: echo "${{ secrets.ENV_FILE_TASK8 }}" > week8/week8_summery/app/.env

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
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "mkdir -p /home/azureuser/week9summery/app"
          rsync -az --delete --exclude='.git' --exclude='node_modules' -e "ssh -i key.pem -o StrictHostKeyChecking=no" ./week8/week8_summery/app/ azureuser@${{ inputs.vm_ip }}:/home/azureuser/week9summery/app/

      - name: Deploy with Docker Compose
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "
            cd /home/azureuser/week9summery/app &&
            sudo docker-compose down --remove-orphans &&
            sudo docker-compose up -d --build
          "

      - name: Healthcheck and get logs
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "
            sudo docker ps
          " > remote_logs.txt

      - name: Logs from Azure VM
        run: |
          ssh -i key.pem -o StrictHostKeyChecking=no azureuser@${{ inputs.vm_ip }} "
            cd /home/azureuser/week9summery/app
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
        run: rm -f week8/week8_summery/app/.env

```

#### Screenshot of the result:

![image](https://github.com/user-attachments/assets/5d1d55d8-8a90-44e6-b8e8-7cb971ef2726)




### Step 7 – Logging and Documentation 

All Terraform commands (`init`, `plan`, `apply`) are logged automatically into:

- `deployment_log.md`


```
terraform init

Initializing Terraform...

Initializing the backend...
Successfully configured the backend "azurerm"!
Terraform will automatically use this backend unless the backend configuration changes.

Initializing modules...
- network in modules/network
- resource_group in modules/resource_group
- vm in modules/vm

Initializing provider plugins...
Finding hashicorp/azurerm versions matching "~> 3.0"...
Installing hashicorp/azurerm v3.117.1...
Installed hashicorp/azurerm v3.117.1 (signed by HashiCorp)

Terraform has created a lock file `.terraform.lock.hcl` to record the provider selections it made above.
Include this file in your version control repository to guarantee consistent provider selections in future runs.

Terraform has been successfully initialized!

You may now begin working with Terraform.
Try running `terraform plan` to see any changes required for your infrastructure.

If you ever set or change modules or backend configuration, rerun `terraform init`.
Other commands will remind you if reinitialization is necessary.

---

terraform apply

Applying Terraform configuration...
Acquiring state lock. This may take a few moments...

Refreshing state:
- module.resource_group.azurerm_resource_group.this
- module.network.azurerm_network_security_group.this
- module.network.azurerm_virtual_network.this
- module.network.azurerm_public_ip.this
- module.network.azurerm_subnet.this
- module.network.azurerm_network_security_rule.this
- module.network.azurerm_subnet_network_security_group_association.this
- module.network.azurerm_network_interface.this
- module.vm.azurerm_linux_virtual_machine.this

Terraform execution plan:

Resource actions:
~ Update in-place

Resources to modify:
- module.vm.azurerm_linux_virtual_machine.this

Details of modification:
  identity block will be removed:
    - identity_ids: []
    - principal_id: "24b72eeb-2c65-4acb-946f-be0e6ee7c4ca"
    - tenant_id: "485d9998-0bfe-4500-89f1-6d8e49183499"
    - type: "SystemAssigned"

Plan summary:
- 0 resources to add
- 1 resource to change
- 0 resources to destroy

Applying changes:
- module.vm.azurerm_linux_virtual_machine.this: Modifying...
- module.vm.azurerm_linux_virtual_machine.this: Modifications complete after 23s

Releasing state lock. This may take a few moments...

Apply complete!
- Resources: 0 added, 1 changed, 0 destroyed.

Outputs:
- public_ip_address = "51.4.113.244"
- resource_group_name = "mtc-resources"
- ssh_connection_command = "ssh azureuser@51.4.113.244"
- virtual_machine_id = "/subscriptions/f9f71262-67c6-48a1-ad2f-75ed5b29135b/resourceGroups/mtc-resources/providers/Microsoft.Compute/virtualMachines/mtc-vm"
- virtual_machine_name = "mtc-vm"

---

terraform output

Public IP from Terraform: 51.4.113.244
```


### Step 8 – Resilience Test

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



![image](https://github.com/user-attachments/assets/46d47769-8d98-46ae-b473-bd2b4d659c02)

Step 9 – User Experience and Validation:

![image](https://github.com/user-attachments/assets/cda95043-76ac-4f68-864c-f52dea838c01)

---------------------------------------

http://51.4.113.244:3000/
