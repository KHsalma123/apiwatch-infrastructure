
output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.apiwatch.name
}

output "vm_name" {
  description = "Name of the Azure virtual machine"
  value       = azurerm_linux_virtual_machine.apiwatch.name
}

output "public_ip_address" {
  description = "Public IP address of the Azure VM"
  value       = azurerm_public_ip.apiwatch.ip_address
}

output "ssh_username" {
  description = "SSH username for the Azure VM"
  value       = azurerm_linux_virtual_machine.apiwatch.admin_username
}
