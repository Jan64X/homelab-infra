# Ansible Infrastructure Automation

A comprehensive Ansible playbook for managing a hybrid infrastructure consisting of homelab servers and VPS instances. This playbook automates the deployment and configuration of various self-hosted services including web applications, media servers, development tools, and monitoring solutions.

## 🎯 Overview

This repository contains Ansible automation for managing:
- **Homelab Infrastructure**: Self-hosted services running on local network servers
- **VPS Infrastructure**: Remote virtual private servers for distributed services
- **Monitoring & Observability**: Centralized monitoring with Prometheus and Grafana
- **Service Gateway**: Nginx reverse proxy with SSL/TLS termination and static website hosting

## 🔒 Security Notice

This playbook assumes:
- **Pre-configured hosts** with an `ansible` user (UID/GID 1000)
- **SSH key-based authentication** already in place
- **Passwordless sudo** configured for the ansible user
- **Debian 12/13** as the base operating system

See [SETUP.md](SETUP.md) for detailed prerequisites and security considerations.

## 📋 Managed Services

### Application Services
- **GitLab** - Self-hosted Git repository manager and CI/CD platform
- **Sharkey** - Federated microblogging server (Misskey fork)
- **SearXNG** - Privacy-respecting metasearch engine
- **Immich** - Self-hosted photo and video management solution
- **Navidrome** - Modern music server and streamer
- **UniFi Controller** - Network management controller for UniFi devices
- **Files CDN** - Content delivery and file hosting service
- **Torrent Downloader** - qBittorrent-based download manager with Flood UI

### Infrastructure Services
- **Nginx Gateway** - Reverse proxy and webserver (that automatically pulls website source code) with Cloudflare SSL integration
- **Observability** - Prometheus and Grafana stack for metrics and visualization
- **Monitoring (Homelab)** - Node Exporter for homelab hosts
- **Monitoring (VPS)** - Node Exporter for VPS hosts with firewall restrictions
- **Base** - Common system configuration (users, SSH, security, firewall)

## 🏗️ Architecture

### Host Groups
- **homelab**: Local network servers running self-hosted applications
- **vpses**: Remote virtual private servers for distributed infrastructure

### Role-Based Deployment
Each host can have multiple roles assigned via the `host_roles` variable in the inventory. The playbook dynamically includes roles based on host configuration, allowing flexible service distribution across infrastructure.

### Key Features
- **Modular Design**: Each service is isolated in its own role
- **Idempotent Operations**: Safe to run multiple times
- **Backup Integration**: NAS-based backup and restore capabilities
- **Credential Management**: Automated password generation and secure storage
- **Dynamic Configuration**: Template-based configuration with Jinja2
- **Monitoring Integration**: Node Exporter deployment on all managed hosts

## 📁 Repository Structure

```
.
├── ansible.cfg              # Ansible configuration
├── site.yml                 # Main playbook
├── update.yml              # System update playbook
├── inventory/
│   └── hosts.yml           # Inventory definition (homelab + VPS hosts)
├── group_vars/
│   ├── all.yml             # Variables for all hosts
│   ├── homelab.yml         # Homelab-specific variables
│   └── vpses.yml           # VPS-specific variables
├── roles/                  # Service roles
│   ├── base/               # Base system configuration
│   ├── nginx_gateway/      # Nginx reverse proxy
│   ├── gitlab/             # GitLab CE
│   ├── sharkey/            # Sharkey federated server
│   ├── searxng/            # SearXNG search engine
│   ├── immich/             # Immich photo manager
│   ├── navidrome/          # Navidrome music server
│   ├── torrent-down/       # qBittorrent + Flood
│   ├── filescdn/           # File CDN service
│   ├── unificontroller/    # UniFi controller
│   ├── observability/      # Prometheus + Grafana
│   ├── monitoring-hl/      # Node Exporter (homelab)
│   └── monitoring-vps/     # Node Exporter (VPS)
└── credentials/            # Sensitive data (gitignored)
    ├── hosts/              # Per-host credentials
    └── ssh_keys/           # SSH keys for authentication
```

## 🚀 Quick Start

### Prerequisites
- Ansible 2.9+ installed on control node
- SSH access to all managed hosts
- Python 3 on all managed hosts

### Basic Usage

1. **Configure inventory and variables** (see [SETUP.md](SETUP.md))
2. **Run the main playbook:**
   ```bash
   ansible-playbook site.yml
   ```

3. **Target specific hosts:**
   ```bash
   ansible-playbook site.yml --limit nginx-gateway
   ```

4. **Update all systems:**
   ```bash
   ansible-playbook update.yml
   ```

## 🔧 Configuration

### Inventory Structure
Hosts are organized into two groups:
- `homelab` - Local infrastructure
- `vpses` - Cloud/VPS infrastructure

Each host defines:
- Connection parameters (`ansible_host`, `ansible_user`)
- System configuration (`os_family`, `system_shell`)
- Assigned roles (`host_roles`)

### Variable Hierarchy
1. `group_vars/all.yml` - Global settings (SSH keys, common users)
2. `group_vars/homelab.yml` - Homelab settings (domain, NAS config, services)
3. `group_vars/vpses.yml` - VPS settings (SSH keys, security)
4. Host variables in `inventory/hosts.yml`

## 🔐 Security Features

- **User Management**: Automated creation of system and automation users
- **SSH Hardening**: Key-based authentication, separate keys per environment
- **Firewall Configuration**: UFW-based firewall rules per service
- **Fail2Ban**: Intrusion prevention for SSH and web services
- **Credential Isolation**: Per-host password generation and storage
- **Sudo Configuration**: Restricted privilege escalation

## 📊 Monitoring

The observability stack provides:
- **Prometheus**: Metrics collection and time-series database
- **Grafana**: Visualization and dashboards
- **Node Exporter**: System metrics from all hosts
- **Service Exporters**: Application-specific metrics

## 🔄 Backup & Restore

Services use **Restic with MinIO S3** for secure, encrypted, deduplicated backups:

### Backup Strategy
- **Restic**: Encrypted, deduplicated backup tool
- **MinIO S3**: Self-hosted S3-compatible storage
- **Append-Only**: VMs can write but not delete backups (ransomware protection)
- **Auto-Discovery**: Fresh installs automatically restore from latest backup
- **Scheduled**: Daily cron jobs run backups automatically

### Services with Backup Support
- **Forgejo** - Git repositories and PostgreSQL database
- **Sharkey** - PostgreSQL database and media uploads
- **GitLab** - Repositories and database
- **UniFi Controller** - .unf configuration backups
- **Navidrome** - SQLite database
- **Observability** - Prometheus TSDB and Grafana dashboards

### NAS Integration
Some services mount NAS shares for direct storage access:
- **Navidrome** - Music library (read-only mount)
- **Immich** - Photo storage (read-write mount)
- **Torrent-Down** - Download directory (read-write mount)
- **Files CDN** - Static content (read-only mount)

See **[minio/README.md](minio/README.md)** for complete backup setup.

## 📝 Playbooks

### site.yml
Main playbook that applies roles to all configured hosts based on their `host_roles` variable.

### update.yml
System maintenance playbook that updates packages on all Debian-based hosts.

## 🛠️ Common Tasks

**Deploy a new host:**
1. Add to `inventory/hosts.yml`
2. Configure `host_roles`
3. Run: `ansible-playbook site.yml --limit new-host`

**Add a new service:**
1. Create role in `roles/service-name/`
2. Add to host's `host_roles` in inventory
3. Run playbook

**Update a specific service:**
```bash
ansible-playbook site.yml --limit hostname --tags service-name
```

## 📚 Documentation

- [SETUP.md](SETUP.md) - Detailed setup instructions
- [TODO.md](TODO.md) - Known issues and planned improvements
- Individual role READMEs (if available)

## 🔍 Role Descriptions

### base
Foundation role applied to all hosts. Configures:
- System users (ansible, sysadmin)
- SSH access and keys
- Sudo configuration
- UFW firewall
- Security tools (fail2ban)
- System utilities (chrony, unattended-upgrades)

### nginx_gateway
Reverse proxy and webserver with:
- SSL/TLS termination (Cloudflare Origin CA)
- Virtual host configuration
- Service routing
- Static website deployment from Git repository
- Automatic website updates on repository changes (when the playbook is re-run)
- NAS integration for certificate management

### Application Roles
Each application role:
- Installs dependencies
- Configures the service
- Manages Docker containers (where applicable)
- Sets up systemd services (where applicable)
- Configures backups (where applicable)
- Integrates with monitoring (if defined to do so)

## 🤝 Contributing

This is a personal infrastructure repository. If you're using it as reference:
1. Fork the repository
2. Customize for your environment
3. Remove or modify service-specific configurations

## ⚠️ Important Notes

- **Credentials**: Never commit actual credentials. Use `.gitignore` patterns.
- **Testing**: Test changes on non-production hosts first
- **Backups**: Verify backup restoration procedures regularly
- **Updates**: Review role changes before applying to production

## 📄 License

This playbook is provided as-is for personal infrastructure management. Customize as needed for your environment.

## 🆘 Support

For setup assistance, see [SETUP.md](SETUP.md). For specific service issues, consult the respective role's tasks and templates.

---
