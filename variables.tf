variable "github_username" {
  type        = string
  default     = "azimkayz"
  description = "GitHub username or org that all module repos are published under."
}

variable "project_name" {
  type        = string
  default     = "projecta"
  description = "Project identifier used for resource naming across all modules."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment name used for resource naming across all modules."
}

variable "location" {
  type        = string
  default     = "southafricanorth"
  description = "Azure region for all resources."
}

variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key for VM admin login. Supply via terraform.tfvars, never commit a real key."
}