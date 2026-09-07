output "vnet_id" {
  value = module.vnet.vnet_id
}

output "vm_subnet_id" {
  value = module.subnets_nsg.vm_subnet_id
}

output "bastion_id" {
  value = module.bastion.bastion_id
}

output "nat_gateway_id" {
  value = module.nat_gateway.nat_gateway_id
}

output "storage_account_id" {
  value = module.storage_account.storage_account_id
}

output "vm_id" {
  value = module.vm_nic.vm_id
}

output "vm_private_ip" {
  value = module.vm_nic.private_ip_address
}

output "disk_ids" {
  value = module.data_disks.disk_ids
}

output "dcr_id" {
  value = module.monitoring.dcr_id
}

output "dcr_association_id" {
  value = module.monitoring.dcr_association_id
}