# Ansible Homelab Infrastructure

A comprehensive Ansible playbook for managing homelab servers. This playbook automates the deployment and configuration of various self-hosted services including media servers, monitoring, and network infrastructure.

## 🎯 Overview

This repository contains Ansible automation for managing:
- **Homelab Infrastructure**: Self-hosted services running on local network servers
- **Monitoring & Observability**: Centralized monitoring with Prometheus and Grafana
- **DNS**: Local DNS resolution with Unbound
- **Backups**: Restic + MinIO S3 for encrypted, deduplicated backups

> **Note**: Public-facing VPS infrastructure (Nginx gateway, SearXNG, Files CDN) is managed separately in the [public-infra](https://github.com/jan64x/public-infra) repository.

## 🔒 Security Notice

This playbook assumes:
- **Pre-configured hosts** with an `ansible` user (UID/GID 1000)
- **SSH key-based authentication** already in place
- **Passwordless sudo** configured for the ansible user
- **Locked local passwords** for `root` and `ansible` accounts
- **Debian 12/13** as the base operating system

See [SETUP.md](SETUP.md) for detailed prerequisites and security considerations.

## 📋 Managed Services

### Application Services
- **Immich** - Self-hosted photo and video management solution
- **Navidrome** - Modern music server and streamer
- **UniFi Controller** - Network management controller for UniFi devices
- **Torrent Downloader** - qBittorrent-based download manager with Flood UI

### Infrastructure Services
- **Observability** - Prometheus and Grafana stack for metrics and visualization
- **Monitoring (Homelab)** - Node Exporter for homelab hosts
- **Unbound** - Local DNS resolver with DNS-over-TLS
- **Promtail** - Log shipper for Loki
- **Base** - Common system configuration (users, SSH, security, firewall)

## 🏗️ Architecture

### Host Groups
- **homelab**: Local network servers running self-hosted applications

### Role-Based Deployment
Each host can have multiple roles assigned via the `host_roles` variable in the inventory. The playbook dynamically includes roles based on host configuration, allowing flexible service distribution across infrastructure.

### Key Features
- **Modular Design**: Each service is isolated in its own role
- **Idempotent Operations**: Safe to run multiple times
- **Backup Integration**: NAS-based backup and restore capabilities
- **Credential Management**: Automated password generation and secure storage
- **Credential Management**: System user and service credential generation with host-scoped storage
- **Dynamic Configuration**: Template-based configuration with Jinja2
- **Monitoring Integration**: Node Exporter deployment on all managed hosts

## 📁 Repository Structure

```
.
├── ansible.cfg              # Ansible configuration
├── site.yml                 # Main playbook
├── update.yml              # System update playbook
├── inventory/
│   └── hosts.yml           # Inventory definition (homelab hosts)
├── group_vars/
│   ├── all.yml             # Variables for all hosts
│   └── homelab.yml         # Homelab-specific variables
├── roles/                  # Service roles
│   ├── base/               # Base system configuration
│   ├── immich/             # Immich photo manager
│   ├── navidrome/          # Navidrome music server
│   ├── seedbox/            # qBittorrent + Flood
│   ├── unificontroller/    # UniFi controller
│   ├── unbound/            # Unbound DNS resolver
│   ├── observability/      # Prometheus + Grafana
│   ├── monitoring-hl/      # Node Exporter (homelab)
│   └── promtail-hl/        # Promtail log shipper (homelab)
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
Hosts are organized in a single group:
- `homelab` - Local infrastructure

Each host defines:
- Connection parameters (`ansible_host`, `ansible_user`)
- System configuration (`os_family`, `system_shell`)
- Assigned roles (`host_roles`)

### Variable Hierarchy
1. `group_vars/all.yml` - Global settings (SSH keys, common users, Unbound DNS)
2. `group_vars/homelab.yml` - Homelab settings (NAS config, backup credentials)
3. Host variables in `inventory/hosts.yml`

## 🔐 Security Features

- **User Management**: Automated creation of system and automation users
- **SSH Hardening**: Key-based authentication, separate keys per environment
- **Firewall Configuration**: UFW-based firewall rules per service
- **Fail2Ban**: Intrusion prevention for SSH and web services
- **Credential Isolation**: Per-host password generation and storage
- **Locked Admin Accounts**: `root` and `ansible` passwords locked; SSH keys required
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
- **UniFi Controller** - .unf configuration backups
- **Navidrome** - SQLite database
- **Observability** - Prometheus TSDB and Grafana dashboards

### NAS Integration
Some services mount NAS shares for direct storage access:
- **Navidrome** - Music library (read-only mount)
- **Immich** - Photo storage (read-write mount)
- **Torrent-Down** - Download directory (read-write mount)

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

This playbook is provided as-is for personal infrastructure management. Customize as needed for your environment. See [LICENSE](LICENSE). 

## 🆘 Support

For setup assistance, see [SETUP.md](SETUP.md). For specific service issues, consult the respective role's tasks and templates.

---
