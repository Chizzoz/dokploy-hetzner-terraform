terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.54.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "dokploy_ssh_key" {
  name       = var.ssh_key_name
  public_key = file(var.ssh_key_path)
}

data "hcloud_datacenters" "all" {}

locals {
  # Safer lookup: errors if zero or multiple datacenters are found for the location
  target_datacenter_obj = one([for dc in data.hcloud_datacenters.all.datacenters : dc if startswith(dc.name, var.location)])
}

resource "hcloud_primary_ip" "dokploy_ip" {
  name          = "${var.server_name}-ip"
  datacenter    = local.target_datacenter_obj.name # Reverted to name for API compatibility
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false
}

resource "hcloud_firewall" "dokploy_fw" {
  name = "${var.server_name}-fw"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3000"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "dokploy" {
  name         = var.server_name
  server_type  = var.server_type
  image        = "ubuntu-24.04"
  datacenter   = local.target_datacenter_obj.name # Reverted to name for API compatibility
  backups      = var.backups
  ssh_keys     = [hcloud_ssh_key.dokploy_ssh_key.id]
  firewall_ids = [hcloud_firewall.dokploy_fw.id]

  public_net {
    ipv4 = hcloud_primary_ip.dokploy_ip.id
  }

  user_data = <<-EOT
    #cloud-config
    users:
      - name: ${var.admin_username}
        groups: sudo
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh_authorized_keys:
          - ${file(var.ssh_key_path)}
          - ${file(var.extra_ssh_key_path)}

    runcmd:
      - sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
      - sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
      - systemctl restart ssh
      - apt-get update
      - apt-get install -y fail2ban
      - systemctl enable fail2ban
      - systemctl start fail2ban
      - ufw default deny incoming
      - ufw default allow outgoing
      - ufw allow 22/tcp
      - ufw allow 3000/tcp
      - ufw allow 80/tcp
      - ufw allow 443/tcp
      - ufw --force enable
    EOT

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.private_key_path)
      host        = self.ipv4_address
      timeout     = "5m"
    }

    inline = [
      "echo 'Waiting for Cloud-Init to finish...'",
      "cloud-init status --wait",
      "echo 'Installing Dokploy...'",
      "curl -sSLf https://dokploy.com/install.sh | sudo sh"
    ]
  }

  lifecycle {
    prevent_destroy = false # Disable to allow terraform destroy to work
    # prevent_destroy = true # Enable to protect production server from accidental deletion
  }
}

output "server_ip" {
  value       = hcloud_server.dokploy.ipv4_address
  description = "The public IP address of the server"
}

output "ssh_command" {
  value       = "ssh -i ${var.private_key_path} ${var.admin_username}@${hcloud_server.dokploy.ipv4_address}"
  description = "Command to SSH into the server"
}

output "dokploy_url" {
  value       = "http://${hcloud_server.dokploy.ipv4_address}:3000"
  description = "The URL to access the Dokploy dashboard"
}

output "next_steps" {
  value = <<EOT
1. Wait a few minutes for Dokploy to finish its background installation.
2. Visit the Dokploy URL above IMMEDIATELY to register your admin account.
   (The first person to visit becomes the administrator!)
3. Use the SSH command above if you need manual access to the server.
4. Root SSH login is disabled; always use the '${var.admin_username}' user.
EOT
}
