# modules/virtual_machine/variables.tf

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
