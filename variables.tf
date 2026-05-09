variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Name of the server"
  type        = string
  default     = "dokploy-server"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cpx22"
}

variable "location" {
  description = "Hetzner location"
  type        = string
  default     = "nbg1"
}

variable "ssh_key_path" {
  description = "Path to the public SSH key used by Terraform"
  type        = string
  default     = "~/.ssh/terraform_id_ed25519.pub"
}

variable "extra_ssh_key_path" {
  description = "Path to an additional public SSH key to allow access"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}


variable "ssh_key_name" {
  description = "The name of the SSH key as it appears in your Hetzner console"
  type        = string
  default     = "dokploy-key"
}




variable "private_key_path" {
  description = "Path to the private SSH key"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "admin_username" {
  description = "The name of the administrative user to create"
  type        = string
  default     = "dokadmin"
}

variable "backups" {
  description = "Enable automatic backups for the server"
  type        = bool
  default     = true
}


