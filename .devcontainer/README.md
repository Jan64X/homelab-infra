# Ansible DevContainer

This DevContainer provides a stable, reproducible Ansible environment with pinned versions to avoid compatibility issues.

## Versions

- **Base Image**: Debian Bookworm (Debian 12)
- **Ansible Core**: 2.18.x (stable, receives bug fixes)
- **Python**: 3.12 (supported until October 2028)

## Why These Versions?

We're using Ansible 2.18 with Python 3.12 instead of the bleeding-edge versions to avoid known issues:
- [GitHub Issue #84483](https://github.com/ansible/ansible/issues/84483) - Privilege escalation timeouts
- [GitHub Issue #84503](https://github.com/ansible/ansible/issues/84503) - Ubuntu 24.04.1 compatibility issues

## Features

- Pre-built image from [willhallonline/docker-ansible](https://github.com/willhallonline/docker-ansible)
- Ansible-lint for playbook validation
- Mitogen for improved performance (optional)
- VSCode Ansible extension pre-configured
- SSH agent forwarding enabled
- Host network mode for direct access to your homelab

## Usage

### Opening in VSCode

1. Install the "Dev Containers" extension in VSCode
2. Open the homelab-ansible folder
3. Press `F1` and select "Dev Containers: Reopen in Container"
4. Wait for the container to build (first time only)

### Verifying Versions

```bash
python3 --version  # Should show Python 3.12.x
ansible --version  # Should show ansible-core 2.18.x
```

### Running Playbooks

```bash
# Same as before, but now in a stable environment
ansible-playbook site.yml

# With higher forks now that we have stable versions
ansible-playbook site.yml -e 'forks=15'
```

## SSH Keys

The container automatically mounts your `credentials/` directory. Your SSH keys and other credentials remain on the host and are never copied into the container image.

## Network Access

The container uses `--network=host`, meaning it can directly access your network without port forwarding complications.

## Troubleshooting

### Container won't start
- Ensure Docker is running
- Check that the `credentials/` directory exists (it should be pre-created if you git cloned this repo tho)

### SSH authentication fails
- Make sure your SSH agent is running on the host
- Verify SSH keys are in `credentials/ssh_keys/`

### Ansible can't reach hosts
- Confirm you're using `--network=host` mode
- Test connectivity: `ping <some IP you know should be up>` from inside the container
