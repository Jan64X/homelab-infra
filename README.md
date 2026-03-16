# Homelab Infra (Ansible)

Ansible repo for a my homelab setup running on one Proxmox VM.

Current model:
- One VM runs selected app roles.
- One shared ingress role handles 80/443 and TLS.
- Service domains are subdomains of `home.<public-domain>`.
- Backups use SMB shares and compressed archives.

## What It Deploys

Common roles in this setup:
- `base`
- `docker`
- `ingress`
- `forgejo`
- `immich`
- `navidrome`
- `ntfy`
- `observability`
- `monitoring-hl`
- `promtail-hl`

Other roles still exist and can be enabled per host.

## Core Files

- [ansible/site.yml](ansible/site.yml): main playbook
- [ansible/update.yml](ansible/update.yml): OS updates
- [ansible/inventory/hosts.yml](ansible/inventory/hosts.yml): hosts and host_roles
- [ansible/group_vars/all.yml](ansible/group_vars/all.yml): global vars
- [ansible/group_vars/homelab.yml](ansible/group_vars/homelab.yml): homelab vars

## Quick Run

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml site.yml --limit homelab-vm
```

System updates:

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml update.yml --limit homelab-vm
```

## Backups

Backup model is SMB + archive files, because I needed something working first (maybe I'll switch to Restic/Borg again, but that's for the future)

Service backup shares are configured in [ansible/group_vars/homelab.yml](ansible/group_vars/homelab.yml):
- Forgejo: DB dump (`.sql.zst`) + app data (`.tar.zst`)
- Navidrome: app data (`.tar.zst`)
- Observability: Prometheus/Grafana/Loki state (`.tar.zst`)

Fresh installs restore the newest matching archive automatically.

## Ingress

Ingress behavior:
- HTTP requests redirect to HTTPS.
- Defined service vhosts proxy to internal containers.
- Bare `home.<public-domain>` returns 404 by design.

## Security Notes

- Assume prepared hosts: Debian 12/13, Python 3, SSH access, `ansible` user with sudo.
- Keep `credentials/` out of version control.
- Test role changes before production rollout.

## Docs

- [SETUP.md](SETUP.md): setup steps
- [TODO.md](TODO.md): open tasks

## License

See [LICENSE](LICENSE).
