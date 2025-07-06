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