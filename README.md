# stw-infra-live

The live production environment for Stewardship Enterprise Workloads (Phase 2). This
repository composes all 10 single-responsibility Terraform modules into a
secure, production-ready Azure deployment.

It provides a hardened network topology, private compute instances with automated 
Syslog ingestion, and isolated management access via Azure Bastion.

## What this deploys

| Order | Module            | Purpose                                                    |
|-------|-------------------|-------------------------------------------------------------|
| 1     | resource_group    | Resource group all other resources deploy into              |
| 2     | vnet              | Virtual Network                                              |
| 3     | subnets_nsg       | VM subnet + NSG (dynamic rules, VM-subnet-only association)  |
| 4     | public_ip (×2)    | Reusable Public IP, called for both Bastion and NAT          |
| 5     | bastion           | Bastion Host + AzureBastionSubnet                            |
| 6     | nat_gateway       | NAT Gateway + associations                                   |
| 7     | storage_account   | Centralized Storage Account + container for Syslog           |
| 8     | vm_nic            | Linux VM + private NIC (no public IP)                        |
| 9     | data_disks        | Managed data disks, attached via `for_each`                  |
| 10    | monitoring        | AMA extension + DCR + DCR association (Syslog → Storage)     |

Every module is sourced from its own GitHub repository, pinned to `v1.0.0`.
Dependencies are passed exclusively via module outputs — no hardcoded names
or resource IDs anywhere in this repository.

## Before running

Create a `terraform.tfvars` file (this is git-ignored, never commit it):

\`\`\`hcl
project_name          = "projecta"
environment            = "prod"
admin_ssh_public_key   = "ssh-rsa AAAA...your-real-key-here"
\`\`\`

Generate an SSH key first if you don't have one:
\`\`\`bash
ssh-keygen -t rsa -b 4096
\`\`\`
Then paste the contents of the `.pub` file (not the private key) into `terraform.tfvars`.

Make sure you're authenticated to Azure before running anything:
\`\`\`bash
az login
az account show
\`\`\`

## Running

\`\`\`bash
terraform init
terraform plan
terraform apply
\`\`\`

## Dependency graph

\`\`\`
resource_group
  └─ vnet
       └─ subnets_nsg
            ├─ nat_gateway (also needs nat_public_ip)
            └─ vm_nic (depends_on nat_gateway for outbound routing)
                 ├─ data_disks
                 └─ monitoring (also needs storage_account)

bastion_public_ip ─┐
                    ├─ bastion (also needs vnet)
nat_public_ip ──────┘

storage_account (independent, needed by monitoring)
\`\`\`

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5.0 |
| azurerm   | ~> 5.4.0   |