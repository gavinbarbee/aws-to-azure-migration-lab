output "migrate_project_name" {
  value = "migrate-project-${var.yourname} (create manually in portal)"
}
 
output "source_resource_group" {
  value = azurerm_resource_group.source.name
}
 
output "target_resource_group" {
  value = azurerm_resource_group.target.name
}
 
output "replication_storage_account" {
  value = azurerm_storage_account.replication_cache.name
}
 
output "recovery_services_vault" {
  value = azurerm_recovery_services_vault.main.name
}
 
output "target_subnet_id" {
  description = "Paste this into the Azure Migrate replication settings when prompted for target subnet."
  value       = azurerm_subnet.main.id
}
 
output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "appliance_public_ip" {
  description = "Public IP of the discovery appliance VM."
  value       = azurerm_public_ip.appliance.ip_address
}

output "replication_appliance_public_ip" {
  description = "Public IP of the replication appliance VM."
  value       = azurerm_public_ip.replication.ip_address
}