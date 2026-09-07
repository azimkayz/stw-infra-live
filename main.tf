# -----------------------------------------------------------------------------
# 1. Resource Group
# -----------------------------------------------------------------------------
module "resource_group" {
  source = "github.com/azimkayz/stw-tf-resource-group?ref=v1.0.0"

  project_name = var.project_name
  environment  = var.environment
  location     = var.location
}

# -----------------------------------------------------------------------------
# 2. Virtual Network
# -----------------------------------------------------------------------------
module "vnet" {
  source = "github.com/azimkayz/stw-tf-vnet?ref=v1.0.0"

  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = module.resource_group.resource_group_name
  address_space        = ["10.0.0.0/16"]
}

# -----------------------------------------------------------------------------
# 3. Subnets + NSG
# -----------------------------------------------------------------------------
module "subnets_nsg" {
  source = "github.com/azimkayz/stw-tf-subnets-nsg?ref=v1.0.0"

  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = module.resource_group.resource_group_name
  vnet_name            = module.vnet.vnet_name
  address_prefixes     = ["10.0.1.0/24"]

  nsg_rules = [
    {
      name                       = "allow-ssh-from-bastion"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "10.0.2.0/26"
      destination_address_prefix = "*"
    },
    {
      name                       = "deny-all-inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

# -----------------------------------------------------------------------------
# 4. Public IPs — same module, called twice
# -----------------------------------------------------------------------------
module "bastion_public_ip" {
  source = "github.com/azimkayz/stw-tf-public-ip?ref=v1.0.0"

  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = module.resource_group.resource_group_name
  name_suffix          = "bastion"
}

module "nat_public_ip" {
  source = "github.com/azimkayz/stw-tf-public-ip?ref=v1.0.0"

  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = module.resource_group.resource_group_name
  name_suffix          = "nat"
}

# -----------------------------------------------------------------------------
# 5. Bastion
# -----------------------------------------------------------------------------
module "bastion" {
  source = "github.com/azimkayz/stw-tf-bastion?ref=v1.0.0"

  project_name                    = var.project_name
  environment                     = var.environment
  location                        = var.location
  resource_group_name             = module.resource_group.resource_group_name
  vnet_name                       = module.vnet.vnet_name
  bastion_subnet_address_prefix   = ["10.0.2.0/26"]
  bastion_public_ip_id            = module.bastion_public_ip.public_ip_id
}

# -----------------------------------------------------------------------------
# 6. NAT Gateway
# -----------------------------------------------------------------------------
module "nat_gateway" {
  source = "github.com/azimkayz/stw-tf-nat-gateway?ref=v1.0.0"

  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = module.resource_group.resource_group_name
  public_ip_id         = module.nat_public_ip.public_ip_id
  subnet_id            = module.subnets_nsg.vm_subnet_id
}

# -----------------------------------------------------------------------------
# 7. Storage Account
# -----------------------------------------------------------------------------
module "storage_account" {
  source = "github.com/azimkayz/stw-tf-storage-account?ref=v1.0.0"

  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = module.resource_group.resource_group_name
  container_name       = "syslog-data"
}

# -----------------------------------------------------------------------------
# 8. Virtual Machine + NIC
# -----------------------------------------------------------------------------
module "vm_nic" {
  source = "github.com/azimkayz/stw-tf-vm-nic?ref=v1.0.0"

  project_name          = var.project_name
  environment           = var.environment
  location              = var.location
  resource_group_name   = module.resource_group.resource_group_name
  subnet_id             = module.subnets_nsg.vm_subnet_id
  admin_ssh_public_key  = var.admin_ssh_public_key

  depends_on = [module.nat_gateway]
}

# -----------------------------------------------------------------------------
# 9. Data Disks
# -----------------------------------------------------------------------------
module "data_disks" {
  source = "github.com/azimkayz/stw-tf-data-disks?ref=v1.0.0"

  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = module.resource_group.resource_group_name
  vm_id                = module.vm_nic.vm_id

  data_disks = {
    data1 = {
      size_gb               = 128
      lun                   = 0
      storage_account_type  = "Standard_LRS"
    }
  }
}

# -----------------------------------------------------------------------------
# 10. Monitoring (DCR)
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "github.com/azimkayz/stw-tf-monitoring?ref=v1.0.0"

  project_name             = var.project_name
  environment              = var.environment
  location                 = var.location
  resource_group_name      = module.resource_group.resource_group_name
  vm_id                    = module.vm_nic.vm_id
  storage_account_id       = module.storage_account.storage_account_id
  storage_container_name   = module.storage_account.storage_container_name
}