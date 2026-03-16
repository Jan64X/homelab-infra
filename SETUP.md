# Setup

Setup for the current single-VM layout.

## 1. Prerequisites

Control node:
- Ansible installed
- SSH key for the ansible user on target host

Target host:
- Debian 12 or 13
- user `ansible` exists (UID/GID 1000)
- passwordless sudo for `ansible`
- Python 3 installed

## 2. Create Config Files

```bash
cd ansible
cp inventory/hosts.yml.example inventory/hosts.yml
cp group_vars/all.yml.example group_vars/all.yml
cp group_vars/homelab.yml.example group_vars/homelab.yml
```

Put SSH keys in `ansible/credentials/ssh_keys/`.

Expected files:
- `ansible_admin.key`: private key used by Ansible to connect to hosts
- `ansible_admin.pub`: matching public key
- `sysadmin_homelab.pub`: public key added for normal admin access
- `sysadmin_homelab-backup.pub`: optional backup admin key

If you need to generate them:

```bash
cd ansible/credentials/ssh_keys
ssh-keygen -t ed25519 -f ansible_admin.key -C "ansible-admin"
mv ansible_admin.key.pub ansible_admin.pub
ssh-keygen -t ed25519 -f sysadmin_homelab.key -C "sysadmin-homelab"
mv sysadmin_homelab.key.pub sysadmin_homelab.pub
```

## 3. Inventory

Edit [ansible/inventory/hosts.yml](ansible/inventory/hosts.yml).

Typical single-VM host roles:

```yaml
host_roles:
  - base
  - docker
  - ingress
  - observability
  - monitoring-hl
  - promtail-hl
  - forgejo
  - immich
  - navidrome
  - ntfy
  # - seedbox
```

## 4. Required Variables

Set values in [ansible/group_vars/homelab.yml](ansible/group_vars/homelab.yml):
- `public_base_domain`
- `homelab_base_domain`
- `docker_network_name`
- Cloudflare + certbot values for ingress
- NAS share paths and credentials used by enabled roles

SMB backup shares used by migrated roles:
- Forgejo: `forgejo_backup_share`
- Navidrome: `navidrome_backup_share`
- Observability: `observability_backup_share`

## 5. First Run

Connectivity check:

```bash
cd ansible
ansible all -i inventory/hosts.yml -m ping
```

Deploy:

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --limit homelab-vm
```

Updates:

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml update.yml --limit homelab-vm
```

## 6. Backup and Restore Behavior

- Archive format is `.tar.zst` (`.sql.zst` also used for Forgejo DB dump).
- Fresh install restores newest archive from each service backup share.

Useful flags during migrations:
- `-e forgejo_force_restore_from_backup=true`
- `-e observability_repair_wal=true`
- `-e observability_force_fresh=true`

## 7. Operational Checks

After deploy:
- Verify only 22, 80, 443, 2222 (and intentional SSH custom port if configured) are externally open.
- Verify apps are reachable through ingress domains.
- Verify `https://<homelab_base_domain>` returns 404.
- Check Prometheus targets are UP.

## 8. Troubleshooting

- Role did not run: confirm it is enabled in `host_roles`.
- Config change not visible: rerun playbook for same host and role set.
- NAS mount issues: verify share path, credentials, and reachability.
- Exporters unavailable: confirm local services on 9100 and 9191, then Prometheus targets.

## 9. Notes

- Keep `credentials/` private.
- Test changes on a non-critical host first.
