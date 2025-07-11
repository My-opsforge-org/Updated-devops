# Outputs the name of the resource group

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

# Outputs the public IP of the VM

output "vm_public_ip" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}

# Outputs the public IP for the HTTP server (used for web traffic)

output "http_vm_public_ip" {
  value = azurerm_public_ip.http_vm_public_ip.ip_address
}

# Outputs the admin username for the Linux virtual machine

output "vm_admin_username" {
  value = azurerm_linux_virtual_machine.flask_vm.admin_username
}

# Outputs the fully qualified domain name (FQDN) of the PostgreSQL server

output "postgresql_server_fqdn" {
  value = azurerm_postgresql_flexible_server.db.fqdn
}

# Outputs the database connection URL (sensitive info hidden in CLI)

output "database_url" {
  value = "postgresql://${var.postgres_admin}:${var.postgres_password}@${azurerm_postgresql_flexible_server.db.fqdn}:5432/${var.database_name}"
  sensitive = true
}