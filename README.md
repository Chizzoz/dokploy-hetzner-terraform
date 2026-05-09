# Dokploy Terraform Deployment

Provision a production-ready Hetzner VPS with [Dokploy](https://dokploy.com/) pre-installed using Terraform.

## 🚀 What's New

This project has been customized for a high-security, production-ready setup:

- **Ubuntu 24.04 LTS**: Uses the latest stable Ubuntu image.
- **Dual Firewalls**: Secured by both a Hetzner Cloud Firewall and internal UFW.
- **Admin User**: Automatic creation of a non-root administrative user (`dokadmin`).
- **SSH Hardening**: Root SSH login and password authentication are completely disabled.
- **Automatic Backups**: Daily backups are enabled by default.
- **Dynamic Infrastructure**: Automatically provisions a Primary IP and Firewall—no manual pre-setup required in the Hetzner console.

## 🛠 Default VPS Configuration

| Setting         | Default Value                             |
| :-------------- | :---------------------------------------- |
| **Server Type** | `cpx22` (Regular Performance Shared vCPU) |
| **Location**    | `nbg1` (Nuremberg, Germany)               |
| **Image**       | `ubuntu-24.04`                            |
| **Backups**     | `true`                                    |
| **Admin User**  | `dokadmin`                                |

## 📋 Prerequisites

## 🔑 Two SSH Key Strategy

This project uses a two-key approach for maximum security and automation:

1. **Terraform Key**: A dedicated, passphrase-free key used only by Terraform for automated provisioning and Dokploy installation.
2. **Personal Key**: Your main SSH key (likely passphrase-protected) for secure manual access.

## 📋 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed.
- [Hetzner Cloud](https://www.hetzner.com/) account and [API token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/).

## ⚡️ Setup Instructions

### 1. Create the Dedicated Terraform Key

Generate a passphrase-free key pair for Terraform's automation:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/terraform_id_ed25519 -N ""
```

### 2. Configure Variables

Copy the example variables file and fill in your details:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with:

- `hcloud_token`: Your Hetzner API token.
- `ssh_key_name`: The name of the key as it appears in your Hetzner console.
- `ssh_key_path`: `"~/.ssh/terraform_id_ed25519.pub"`
- `private_key_path`: `"~/.ssh/terraform_id_ed25519"`
- `extra_ssh_key_path`: `"~/.ssh/id_ed25519.pub"` (Your personal key)

### 3. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Useful Outputs

Upon completion, Terraform will output:

- **`server_ip`**: Your server's public IP.
- **`ssh_command`**: A ready-to-use command to log in.
- **`dokploy_url`**: The URL to access your new dashboard (`http://<ip>:3000`).

## 🔐 Security Features

- **Root Access**: Root login is disabled via SSH. All administrative tasks should be done via the `dokadmin` user using `sudo`.
- **Dual Firewalls**: Secured by both a Hetzner Cloud Firewall and internal UFW + Fail2ban.
  - **Open Ports**: 22 (SSH), 80 (HTTP), 443 (HTTPS), 3000 (Dokploy).
- **SSH**: Password authentication is disabled; only key-based access is permitted.
- **Deletion Protection**: The server has `prevent_destroy = true` enabled in Terraform. This prevents accidental deletion through `terraform destroy` or accidental resource replacements.

## 🧹 Cleaning Up

To permanently delete your server, you must first disable the safety lock:

1. Open `main.tf` and set `prevent_destroy = false`.
2. Run the destroy command:
   ```bash
   terraform destroy
   ```

**Warning:** This action is irreversible and will delete all data on the server.
