# Setup Guide

> **🔐 SECURITY FIRST**
> 
> This playbook makes significant system changes including:
> - User account creation and modification
> - Account password locking for `root` and `ansible`
> - Firewall rule configuration  
> - Service installation and configuration
> - SSH access modifications
>
> **ALWAYS** test in a non-production environment first!

This guide walks you through setting up this Ansible playbook to manage your infrastructure.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [SSH Key Configuration](#ssh-key-configuration)
4. [Inventory Configuration](#inventory-configuration)
5. [Variable Configuration](#variable-configuration)
6. [Credential Management](#credential-management)
7. [MinIO S3 Backup Configuration](#minio-s3-backup-configuration)
8. [First Run](#first-run)
9. [Service-Specific Setup](#service-specific-setup)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

> **⚠️ CRITICAL: Host Preparation Required**
> 
> This playbook does NOT perform initial host setup. You must manually prepare each host with:
> - Debian 12/13 installed
> - An `ansible` user with UID/GID 1000
> - Passwordless sudo configured
> - SSH key authentication enabled
> - Python 3 installed
>
> Attempting to run this playbook on unprepared hosts will fail.
> Using cloud-init with the Debian cloud image is recommended.

### Control Node (Your Machine)
- **Ansible**: Version 2.9 or later
  ```bash
  # Ubuntu/Debian
  sudo apt update
  sudo apt install ansible
  
  # macOS
  brew install ansible
  
  # Python pip
  pip3 install ansible
  ```

- **Git**: For cloning and version control
  ```bash
  sudo apt install git  # Ubuntu/Debian
  brew install git      # macOS
  ```

### Managed Hosts

**IMPORTANT**: This playbook assumes your managed hosts have already been prepared with the following configuration during OS installation:

- **Debian 12/13 OS**
- **Python 3** installed (usually included by default)
- **SSH server** running and accessible
- **User Setup** (configured during OS installation):
  - An `ansible` user exists with **UID/GID 1000**
  - `sudo` package is installed
  - The `ansible` user has **passwordless sudo** access
  - The Ansible public key is already in `/home/ansible/.ssh/authorized_keys`

#### How to Prepare a Fresh Debian Host

If you're setting up a new host from scratch, during Debian installation:

1. **Create the ansible user** when prompted for user creation
   - Username: `ansible`
   - This will automatically get UID/GID 1000 (first user)

2. **After installation**, configure passwordless sudo:
   ```bash
   # Login as ansible user or switch to it
   su - ansible
   
   # Add ansible user to sudo group (if not already)
   sudo usermod -aG sudo ansible
   
   # Configure passwordless sudo
   echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers
   ```

3. **Add your Ansible SSH public key**:
   ```bash
   # On the managed host as ansible user
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   echo "your-ansible-public-key-here" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

### Network Requirements
- SSH access (port 22) from control node to all managed hosts
- Internet access on managed hosts for package installation
- (Optional) NAS accessible via CIFS/SMB for backups

## Initial Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url> ansible
cd ansible
```

### 2. Verify Directory Structure

Ensure the following structure exists:
```
ansible/
├── credentials/
│   ├── hosts/
│   └── ssh_keys/
├── group_vars/
├── inventory/
└── roles/
```

## SSH Key Configuration

### 1. Generate SSH Keys

You need to create SSH keys for different purposes:

```bash
cd credentials/ssh_keys/
```

#### Ansible Admin Key
Used by Ansible to connect to all hosts:
```bash
ssh-keygen -t ed25519 -f ansible_admin.key -C "ansible-admin"
mv ansible_admin.key.pub ansible_admin.pub
```

#### Sysadmin Keys
Personal SSH keys for manual access:

**For homelab hosts:**
```bash
ssh-keygen -t ed25519 -f sysadmin_homelab.key -C "sysadmin-homelab"
mv sysadmin_homelab.key.pub sysadmin_homelab.pub
```

### 2. Verify SSH Access

Since your hosts should already have the ansible user configured with the public key, verify SSH access:

```bash
ssh -i credentials/ssh_keys/ansible_admin.key ansible@<host-ip>
```

If this works without prompting for a password, you're ready to proceed.

## Inventory Configuration

### 1. Create Inventory File

```bash
cp inventory/hosts.yml.example inventory/hosts.yml
```

### 2. Edit Inventory

Edit `inventory/hosts.yml` and replace example values:

```yaml
all:
  children:
    homelab:
      hosts:
        immich:
          ansible_host: 192.168.1.10  # Replace with actual IP
          ansible_user: ansible       # Pre-configured ansible user
          ansible_python_interpreter: /usr/bin/python3
          ansible_become_method: sudo
          system_shell: /bin/bash
          os_family: Debian
          host_roles:
            - base
            - monitoring-hl
            - immich
          hostname: immich
        # Add more homelab hosts...
```

**Key Points:**
- Replace `x.x.x.x` with actual IP addresses
- Use `ansible` as the user (should already be configured on hosts)
- The ansible user should already have passwordless sudo
- Adjust `host_roles` to control which services run on each host

### 3. Host Role Assignment

Available roles:
- `base` - Base configuration (recommended for all hosts)
- `immich` - Immich photos
- `navidrome` - Navidrome music
- `seedbox` - qBittorrent + VueTorrent
- `unificontroller` - UniFi controller
- `observability` - Prometheus + Grafana
- `monitoring-hl` - Node Exporter (homelab)
- `promtail-hl` - Promtail log shipper (homelab)
- `unbound` - Unbound DNS resolver

Example minimal setup:
```yaml
host_roles:
  - base
  - monitoring-hl
```

## Variable Configuration

### 1. Global Variables

```bash
cp group_vars/all.yml.example group_vars/all.yml
```

Edit `group_vars/all.yml`:

```yaml
---
# System Configuration
# The ansible user (UID/GID 1000) already exists on hosts
# This creates an ADDITIONAL sysadmin user for manual access
system_user: sysadmin          # Your personal username on managed systems
system_user_groups:
  - wheel
  - ssh

ansible_user: ansible          # Ansible automation user (already exists)
ansible_user_groups: 
  - ssh

# SSH Configuration
# Homelab Configuration
# SSH key for all homelab hosts
sysadmin_ssh_key: "{{ lookup('file', playbook_dir + '/credentials/ssh_keys/sysadmin_homelab.pub') }}"

# Grafana SMTP Configuration
grafana_smtp_enabled: false
grafana_smtp_host: "smtp.example.com:465"
grafana_smtp_user: "myuser"
grafana_smtp_password: "mysecret"
grafana_smtp_from_address: "grafana@example.com"
grafana_smtp_from_name: "Grafana"
grafana_smtp_skip_verify: false

# monitoring - observability role with prometheus and grafana
monitoring_force_fresh_install: false

# immich backup restoration settings, set to true to force a fresh install
immich_force_restore: false

# NAS IP address (adjust to your network)
nas_ip: "x.x.x.x"

# MinIO/S3 Configuration for Restic Backups
minio_endpoint: "https://nas.core.lan:9000"
```

### 3. Homelab Variables

```bash
cp group_vars/homelab.yml.example group_vars/homelab.yml
```

## MinIO S3 Backup Configuration

Multiple services use Restic with MinIO S3-compatible storage for encrypted backups:
- **UniFi Controller** - Configuration backups (.unf files)
- **Navidrome** - Music database
- **Observability** - Prometheus and Grafana data

### Why MinIO + Restic?

- **Append-Only Security**: VMs can write backups but cannot delete old data (ransomware protection)
- **Encryption**: All backups encrypted by Restic before upload
- **Deduplication**: Efficient storage of only changed data
- **S3 Compatible**: Works with MinIO, AWS S3, Backblaze B2, Wasabi, etc.

### Quick Setup

See **[minio/README.md](minio/README.md)** for complete instructions. Summary:

1. Install MinIO client and configure alias
2. Create buckets for each service
3. Apply append-only policies
4. Create service users with restricted permissions
5. Add credentials to `group_vars/homelab.yml`

**Example `group_vars/homelab.yml` configuration:**

```yaml
# MinIO/S3 Configuration
minio_endpoint: "https://nas.core.lan:9000"

# ... similar for unifi, navidrome, observability
```

### NAS Mount Configuration

Some services require direct NAS access for media/data:
- **Navidrome** - Music library (read-only)
- **Torrent-Down** - Download directory (read-write)
- **Immich** - Photo storage (read-write)

Configure NAS credentials and share paths in `group_vars/homelab.yml`:

```yaml
# NAS IP address
nas_ip: "10.0.0.11"

# Navidrome NAS configuration
navidrome_nas_user: "media-user"
navidrome_nas_password: "secure-password"
navidrome_music_share: "//{{ nas_ip }}/tank/Media/Music"

# Torrent-Down NAS configuration
torrentdown_nas_user: "downloads-user"
torrentdown_nas_password: "secure-password"
torrentdown_torrents_share: "//{{ nas_ip }}/sas/torrents"

# Immich NAS configuration
immich_nas_user: "photos-user"
immich_nas_password: "secure-password"
immich_photos_share: "//{{ nas_ip }}/tank/Server/immich"
```

**Security Note**: Use dedicated NAS users with minimal permissions for each service.

## Credential Management

### Auto-Generated Credentials

The playbook automatically generates credentials for each host in:
```
credentials/hosts/<hostname>/
├── <system_user>_pass.txt
├── restic_<service>_password.txt  # Per-service Restic encryption keys
└── salts/
```

**Important Notes:**
- Credentials are generated on first run and reused on subsequent runs
- `root` and `ansible` account passwords are locked by policy and are not generated
- Restic passwords encrypt your backup data (keep them safe!)
- Service-specific passwords (Grafana, etc.) are also auto-generated
- All credential files are gitignored for security

### Account Access Model

- `root` account password is locked
- `ansible` account password is locked
- SSH access is public key only
- `ansible` keeps passwordless sudo for automation

This means there is no password-based fallback for `root` or `ansible` access. Ensure the configured SSH key remains available before rollout.

### Manual Configuration Required

Some credentials must be configured in `group_vars/homelab.yml`:

1. **MinIO/S3 credentials** (for Restic backups)
2. **NAS credentials** (for network mounts)
3. **External service tokens** (Cloudflare API, SMTP, etc.)

See [Variable Configuration](#variable-configuration) for details.

### Host-Specific Credentials

The playbook automatically generates credentials for each host in:
```
credentials/hosts/<hostname>/
├── <system_user>_pass.txt    # your system_user name
└── salts/
```

**Important:** These are auto-generated on first run. Keep them secure!

## First Run

### 1. Verify Host Prerequisites

Before running the playbook, verify each managed host meets the requirements:

```bash
# Test SSH access with the ansible user
ssh -i credentials/ssh_keys/ansible_admin.key ansible@<host-ip>

# Once logged in, verify:
# 1. Check UID/GID of ansible user
id ansible
# Should show: uid=1000(ansible) gid=1000(ansible)

# 2. Verify passwordless sudo
sudo whoami
# Should return "root" without asking for password

# 3. Check Python is available
python3 --version

# 4. Exit back to control node
exit
```

### 2. Test Connectivity

Verify Ansible can reach all hosts:
```bash
ansible all -m ping
```

Expected output:
```
immich | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 2. Dry Run (Check Mode)

Test without making changes:
```bash
ansible-playbook site.yml --check
```

### 3. Run the Playbook

Since the ansible user and SSH access are already configured, you can run the playbook directly:

```bash
ansible-playbook site.yml
```

Or start with just the base role to configure the foundation:

Edit `site.yml` and uncomment the base role:
```yaml
  roles:
    - role: base  # Always applied to all hosts
```

Then run:
```bash
ansible-playbook site.yml
```

This will configure:
- System users (creating the sysadmin user with UID/GID defined in variables)
- SSH access for the sysadmin user
- UFW firewall rules
- Security packages (fail2ban, etc.)
- Base system utilities

### 4. Deploy Services

If you ran only the base role first, comment it out in `site.yml`:
```yaml
#  roles:
#    - role: base  # Always applied to all hosts
```

Then run the full playbook to deploy services based on `host_roles`:
```bash
ansible-playbook site.yml
```

Or target specific hosts:
```bash
ansible-playbook site.yml --limit immich
```

## Service-Specific Setup

### Observability (Prometheus + Grafana)

1. **Grafana Access**:
   - Access: `http://<observability-host>:80`
   - Username: `admin`
   - Password: In `credentials/hosts/observability/grafana_admin_password.txt`

2. **Prometheus**:
   - Configured to scrape all hosts with `monitoring-hl` role
   - Access: `http://<observability-host>:9090`

### Other Services

Each service has auto-generated credentials in `credentials/hosts/<hostname>/`.
Check individual role templates for specific configuration details.

## Troubleshooting

### SSH Connection Issues

**Problem**: "Permission denied (publickey)"
```bash
# Verify key is loaded
ssh-add -l

# Add key if needed
ssh-add credentials/ssh_keys/ansible_admin.key

# Test direct connection
ssh -i credentials/ssh_keys/ansible_admin.key ansible@<host-ip>
```

### Python Not Found

**Problem**: "/usr/bin/python3: not found"
```bash
# Install Python on target host
ssh root@<host-ip>
apt update && apt install python3
```

### Privilege Escalation Failed

**Problem**: "Missing sudo password" or sudo issues
- Ensure the ansible user has passwordless sudo configured:
  ```bash
  # On the managed host
  sudo cat /etc/sudoers.d/ansible
  # Should contain: ansible ALL=(ALL) NOPASSWD:ALL
  ```
- Verify `ansible_become_method: sudo` is set in inventory
- Test sudo manually:
  ```bash
  ssh -i ./credentials/ssh_keys/ansible_admin.key ansible@<host-ip> 'sudo whoami'
  # Should return: root
  ```

### Role Not Applied

**Problem**: Service role not running
- Check `host_roles` in inventory includes the role
- Verify role name spelling matches directory in `roles/`
- Check for errors in previous tasks

### NAS Mount Failed

**Problem**: Cannot mount NAS
- Verify NAS IP in `group_vars/homelab.yml`
- Check NAS credentials in `group_vars/homelab.yml` (e.g., `immich_nas_user`, `navidrome_nas_user`)
- Ensure NAS share exists and is accessible
- Verify share paths are correct (e.g., `immich_photos_share`, `navidrome_music_share`)
- Test manual mount:
  ```bash
  sudo mount -t cifs //nas-ip/share /mnt/test -o username=user,password=pass
  ```
- Check systemd mount status: `sudo systemctl status mnt-*.mount`

### Firewall Blocking Services

**Problem**: Cannot access service after deployment
- Check UFW status: `sudo ufw status`
- Verify port is allowed in role's firewall tasks
- Check if service is running: `sudo systemctl status <service>`

### Certificate Errors

**Problem**: SSL/TLS errors on nginx
- Verify certificates exist in `/etc/nginx/ssl/`
- Check certificate validity: `openssl x509 -in cert.pem -text -noout`
- Ensure NAS mount was successful during deployment

## Advanced Configuration

### Using Ansible Vault

Encrypt sensitive files:
```bash
ansible-vault encrypt group_vars/all.yml
ansible-playbook site.yml --ask-vault-pass
```

### Custom SSH Port

If using non-standard SSH port:
```yaml
# inventory/hosts.yml
ansible_port: 2222
ssh_port: 2222
```

### Limiting Execution

Run specific roles:
```bash
ansible-playbook site.yml --tags base
```

Run specific hosts:
```bash
ansible-playbook site.yml --limit homelab
ansible-playbook site.yml --limit immich
```

### Parallel Execution

Adjust forks in `ansible.cfg`:
```ini
[defaults]
forks = 20  # Number of parallel processes
```

## Post-Setup Maintenance

### Regular Updates

Update all systems:
```bash
ansible-playbook update.yml
```

### Backup Verification

Regularly test backup restoration on non-production hosts.

### Credential Rotation

Periodically rotate:
- SSH keys
- Service passwords
- SSL certificates

### Monitoring

1. Access Grafana dashboards
2. Verify all hosts are reporting metrics
3. Set up alerting rules in Grafana

## Next Steps

1. **Customize Services**: Adjust role variables for your needs
2. **Add Monitoring Dashboards**: Import or create Grafana dashboards
3. **Set Up Backups**: Configure automated backup schedules
4. **Document Changes**: Keep notes on customizations
5. **Test DR Procedures**: Practice restoring from backups

## Getting Help

- Review role-specific `tasks/main.yml` for detailed steps
- Consult Ansible documentation: https://docs.ansible.com/ (RTFM)
- Review service-specific documentation for applications

---

**Setup Complete!** 🎉

Your infrastructure should now be managed by Ansible. Run `ansible-playbook site.yml` anytime to ensure configuration compliance.
